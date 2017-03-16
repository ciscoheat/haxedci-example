import haxe.ds.Option;
import views.ScreenView.ScreenState;
import Data.Card;
import Data.LoanItem;
import haxe.Timer;

/**
 *  Use case implementation.
 *  @see https://docs.google.com/spreadsheets/d/1TSpjKUhjvP9pMRukt_mInHVbdQWsXHzFjSymQ3VyGmE/edit#gid=2
 */
class BorrowLibraryItems implements dci.Context
{
    static var maxPinAttempts(default, never) : Int = 3;

    var pinAttemptsLeft : Int;
    var authorizedCard : Card;
    var lastScannedRfid : Option<String>;
    var removeCardLoop : Timer;

    public function new(scanner, cardReader, screen, printer, keypad, finishButtons) {
        this.scanner = scanner;
        this.cardReader = cardReader;
        this.screen = screen;
        this.printer = printer;
        this.keypad = keypad;
        this.finishButtons = finishButtons;

        this.library = Data;
        this.scannedItems = new Array<LoanItem>();
    }
    
    public function start() {
        resetState();
        screen.displayWelcome();
        cardReader.waitForCardChange();
    }

    function restart() {
        resetState();
        screen.displayThankYouMessage();
        cardReader.waitForCardChange();
    }

    function resetState() {
        if(removeCardLoop != null) removeCardLoop.stop();
        scannedItems.clearItems();
        pinAttemptsLeft = maxPinAttempts;
        authorizedCard = null;
        lastScannedRfid = None;
    }

    @role var cardReader : {
        function scanRfid(callback : Option<String> -> Void) : Void;

        public function waitForCardChange()
            self.scanRfid(self.rfidScanned);

        function rfidScanned(data : Option<String>) switch data {
            case None:
                // No card, keep waiting
                self.waitForCardChange();

            case Some(rfid):
                // Create a wait loop, detecting card removal.
                removeCardLoop = new haxe.Timer(50);
                removeCardLoop.run = function() {
                    self.scanRfid(function(data) {
                        // An "equals" test is required because data is an Enum.
                        if(data.equals(None)) restart();
                    });
                }

                // Look up current card in library database, display pin screen if valid.
                var card = library.card(rfid);

                if(card != null)
                    keypad.waitForEnterPin();
                else
                    screen.displayInvalidCard();
        }

        public function validatePin(pin : String) {
            self.scanRfid(function(data) switch data {
                case Some(rfid):
                    var card = library.card(rfid);

                    if(card == null) {
                        screen.displayInvalidCard();
                    }
                    else if(card.pin == pin) {
                        authorizedCard = card;
                        screen.displayScannedItems();
                        scanner.waitForItem();
                    }
                    else if(--pinAttemptsLeft > 0) {
                        keypad.waitForEnterPin();
                    }
                    else {
                        screen.displayTooManyInvalidPin();
                    }

                case None:
                    // Card already removed.
            });
        }
    }

    @role var scanner : {
        function scanRfid(callback : Option<String> -> Void) : Void;

        public function waitForItem()
            self.scanRfid(self.rfidScanned);

        function rfidScanned(rfid : Option<String>) {
            // If the card has been removed, cancel interaction.
            if(authorizedCard == null) return;

            if(rfid.equals(lastScannedRfid)) return self.waitForItem()
            else lastScannedRfid = rfid;

            switch rfid {
                case None: 
                    self.waitForItem();

                case Some(rfid):
                    if(scannedItems.alreadyScanned(rfid)) return self.waitForItem();

                    var item = library.item(rfid);
                    if(item == null) return self.waitForItem();

                    switch new BorrowLoanItem(item, authorizedCard).borrow() {
                        case Ok:
                            scannedItems.addItem(item);
                            screen.displayScannedItems();                                
                            self.waitForItem();
                        case InvalidLoanItem:
                            screen.displayInvalidLoanItemMessage();
                            self.waitForItem();
                        case ItemAlreadyBorrowed:
                            screen.displayAlreadyBorrowedMessage();
                            self.waitForItem();
                        case InvalidBorrower:
                            // Card is invalid, don't wait for another item.
                            screen.displayInvalidCard();
                    }
            }
        }
    }

    @role var scannedItems : {
        function iterator() : Iterator<LoanItem>;
        function push(item : LoanItem) : Int;
        function splice(pos : Int, len : Int) : Iterable<LoanItem>;
        var length(default, null) : Int;

        public function addItem(item : LoanItem)
            self.push(item);

        public function clearItems()
            self.splice(0, self.length);

        public function alreadyScanned(rfid : String) : Bool
            return self.exists(function(loanItem) return loanItem.rfid == rfid);
    }

    @role var screen : {
        function display(s : ScreenState) : Void;
        function displayMessage(state : ScreenState, waitMs : Int, ?thenDisplay : ScreenState) : Void;

        public function displayWelcome()
            display(Welcome);
        
        public function displayThankYouMessage()
            displayMessage(ThankYou, 4000, Welcome);

        public function displayEnterPin()
            display(EnterPin({previousAttemptFailed: pinAttemptsLeft < 3}));

        public function displayScannedItems() {
            finishButtons.waitForFinishClick();
            display(DisplayBorrowedItems(scannedItems));
        }

        public function displayTooManyInvalidPin()
            display(TooManyInvalidPin);

        public function displayInvalidCard()
            display(InvalidCard);

        public function displayInvalidLoanItemMessage()
            displayMessage(InvalidLoanItem, 3000);

        public function displayAlreadyBorrowedMessage()
            displayMessage(ItemAlreadyBorrowed, 3000);

        public function displayDontForgetLibraryCard()
            display(DontForgetLibraryCard);
    }

    @role var finishButtons : {
        function onFinishWithoutReceiptClicked(callback : Void -> Void, ?pos : haxe.PosInfos) : Void;
        function onFinishWithReceiptClicked(callback : Void -> Void, ?pos : haxe.PosInfos) : Void;

        public function waitForFinishClick() {
            onFinishWithoutReceiptClicked(screen.displayDontForgetLibraryCard);
        }
    }

    @role var keypad : {
        function onPinCodeEntered(callback : String -> Void, ?pos : haxe.PosInfos) : Void;

        public function waitForEnterPin() {
            screen.displayEnterPin();
            self.onPinCodeEntered(cardReader.validatePin);
        }
    }

    @role var printer : {

    }

    @role var library : {
        var libraryItems(default, null) : Array<LoanItem>;
        var libraryCards(default, null) : Array<Card>;

        public function item(rfid : String) : LoanItem 
            return libraryItems.find(function(loanItem) return loanItem.rfid == rfid);

        public function card(rfid : String) : Card
            return libraryCards.find(function(libraryCard) return libraryCard.rfid == rfid);
    }
}
