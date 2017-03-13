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

    public function new(scanner, cardReader, screen, printer, keypad) {
        this.scanner = scanner;
        this.cardReader = cardReader;
        this.screen = screen;
        this.printer = printer;
        this.library = Data;
        this.keypad = keypad;
        this.scannedItems = new Array<LoanItem>();
    }
    
    public function start() {
        screen.displayWelcome();
        resetState();
        cardReader.waitForCardChange();
    }

    function restart() {
        screen.displayThankYou();
        resetState();
        cardReader.waitForCardChange();
    }

    function resetState() {
        pinAttemptsLeft = maxPinAttempts;
        scannedItems.clearItems();
        authorizedCard = null;
    }

    @role var cardReader : {
        function scanRfid(callback : Option<String> -> Void) : Void;

        public function waitForCardChange() {            
            self.scanRfid(self.rfidScanned);
        }

        function rfidScanned(data : Option<String>) switch data {
            case None:
                // No card, keep waiting
                self.waitForCardChange();

            case Some(rfid):
                // Create a wait loop detecting card removal.
                self.createCardRemovedWaitLoop();

                // Look up current card in library database, display pin screen if valid.
                var card = library.cards().find(function(card) return card.rfid == rfid);

                if(card != null)
                    keypad.waitForEnterPin();
                else
                    screen.displayInvalidCard();
        }

        function createCardRemovedWaitLoop() {
            var removeCardTimer = new haxe.Timer(50);
            removeCardTimer.run = function() {
                self.scanRfid(function(data) {
                    if(data.equals(None)) {
                        removeCardTimer.stop();
                        restart();
                    }
                });
            }
        }

        public function validatePin(pin : String) {
            self.scanRfid(function(data) switch data {
                case Some(rfid):
                    var card = library.cards().find(function(card) return card.rfid == rfid);
                    if(card == null) {
                        screen.displayInvalidCard();
                    }
                    else if(card.pin == pin) {
                        authorizedCard = card;
                        scanner.waitForItem();
                    }
                    else if(--pinAttemptsLeft > 0) {
                        keypad.waitForEnterPin();
                    }
                    else
                        screen.displayTooManyInvalidPin();

                case None:
                    // Card already removed.
            });
        }
    }

    @role var scanner : {
        function scanRfid(callback : Option<String> -> Void) : Void;
        function lastScannedRfid() : Option<String>;

        public function waitForItem() {
            screen.displayScannedItems();
            self.scanRfid(self.rfidScanned);
        }

        function rfidScanned(rfid : Option<String>) {
            // If the card has been removed, return immediately.
            if(authorizedCard == null) return;
            switch rfid {
                case None: 
                    self.waitForItem();
                case Some(rfid):
                    var alreadyScanned = scannedItems.find(function(item) return item.rfid == rfid);

                    if(alreadyScanned != null) {
                        scannedItems.moveToBottom(alreadyScanned);
                        self.waitForItem();
                    } else {
                        var item = library.items().find(function(item) return item.rfid == rfid);

                        if(item == null)
                            self.waitForItem();
                        else {
                            switch new BorrowLoanItem(item, authorizedCard).borrow() {
                                case Ok:
                                    scannedItems.addItem(item);
                                    self.waitForItem();
                                case InvalidLoanItem:
                                    screen.displayInvalidLoanItem();
                                    self.waitForItem();
                                case InvalidBorrower:
                                    screen.displayInvalidCard();
                                case ItemAlreadyBorrowed:
                                    screen.displayAlreadyBorrowed();
                            }
                        }
                    }
            }
        }
    }

    @role var scannedItems : {
        function iterator() : Iterator<LoanItem>;
        function push(item : LoanItem) : Int;
        function indexOf (item : LoanItem, ?fromIndex : Int) : Int;
        function splice(pos : Int, len : Int) : Iterable<LoanItem>;

        public function moveToBottom(item : LoanItem) {
            var find = self.indexOf(item);
            if(find >= 0) {
                self.splice(find, 1);
                self.push(item);
            }
        }

        public function addItem(item : LoanItem) {
            self.push(item);
        }

        public function clearItems() {
            self.splice(0, -1);
        }
    }

    @role var screen : {
        function display(s : ScreenState) : Void;
        function displayMessage(state : ScreenState, waitMs : Int, ?thenDisplay : ScreenState) : Void;

        public function displayWelcome() {
            display(Welcome);
        }
        
        public function displayThankYou() {
            displayMessage(ThankYou, 4000, Welcome);
        }

        public function displayEnterPin() {
            display(EnterPin({previousAttemptFailed: pinAttemptsLeft < 3}));
        }

        public function displayScannedItems() {
            display(DisplayBorrowedItems(scannedItems));
        }

        public function displayTooManyInvalidPin() {
            display(TooManyInvalidPin);
        }

        public function displayInvalidCard() {
            display(InvalidCard);
        }

        public function displayInvalidLoanItem() {
            displayMessage(InvalidLoanItem, 3000);
        }

        public function displayAlreadyBorrowed() {
            displayMessage(ItemAlreadyBorrowed, 3000);
        }
    };

    @role var keypad : {
        function onPinCodeEntered(callback : String -> Void) : Void;

        public function waitForEnterPin() {
            screen.displayEnterPin();
            self.onPinCodeEntered(cardReader.validatePin);
        }
    };

    @role var printer : {

    };

    @role var library : {
        public var libraryItems(default, null) : Array<LoanItem>;
        public var libraryCards(default, null) : Array<Card>;

        public function items() : Array<LoanItem> return libraryItems;
        public function cards() : Array<Card> return libraryCards;
    }
}
