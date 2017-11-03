package contexts;

import haxe.ds.Option;
import haxe.Timer;
import views.ScreenView.ScreenState;
import Data.LibraryCard;
import Data.LoanItem;
import Data.ScannedItem;
import Data.ReceiptItem;

/**
 *  Use case implementation.
 *  @see https://docs.google.com/spreadsheets/d/1TSpjKUhjvP9pMRukt_mInHVbdQWsXHzFjSymQ3VyGmE/edit#gid=2
 */
class LibraryBorrowMachine implements dci.Context
{
    static var maxPinAttempts(default, never) : Int = 3;

    ///// Non-Role state that supports the Context /////

    var pinAttemptsLeft : Int;
    var authorizedCard : LibraryCard;
    var lastScannedRfid : Option<String>;

    ///// Constructor and System Operations /////

    public function new(scanner, cardReader, screen, printer, keypad, finishButtons) {
        // Role binding
        this.scanner = scanner;
        this.cardReader = cardReader;
        this.screen = screen;
        this.printer = printer;
        this.keypad = keypad;
        this.finishButtons = finishButtons;
        this.library = Data;
        this.scannedItems = new Array<ScannedItem>();
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
        scannedItems.clearItems();
        pinAttemptsLeft = maxPinAttempts;
        authorizedCard = null;
        lastScannedRfid = None;
    }

    ///// Roles /////

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
                self.createWaitLoopForCardRemoval();

                // Look up current card in library database, display pin screen if valid.
                var card = library.card(rfid);

                if(card != null)
                    screen.displayEnterPin();
                else
                    screen.displayInvalidCard();
        }

        function createWaitLoopForCardRemoval() {
            var removeCardLoop = new haxe.Timer(50);
            removeCardLoop.run = function() {
                self.scanRfid(function(data) {
                    // An "equals" test is required because data is an Enum.
                    if(data.equals(None)) {
                        removeCardLoop.stop();
                        restart();
                    }
                });
            }
        }

        public function validatePin(pin : String) {
            self.scanRfid(function(data) switch data {
                case Some(rfid):
                    var card = library.card(rfid);

                    if(card == null) {
                        screen.displayInvalidCard();
                    }
                    else if(card.pin == pin) {
                        // PIN ok, authorize card and move to
                        // scanning of items.
                        authorizedCard = card;
                        screen.displayScannedItems();
                        scanner.waitForItem();
                    }
                    else if(--pinAttemptsLeft > 0) {
                        screen.displayEnterPin();
                    }
                    else {
                        screen.displayTooManyInvalidPin();
                    }

                case None:
                    // LibraryCard already removed.
            });
        }
    }

    @role var scanner : {
        function scanRfid(callback : Option<String> -> Void) : Void;

        public function waitForItem() {
            self.scanRfid(self.rfidScanned);
        }

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
                        case Ok(loan):
                            scannedItems.addItem(new ReceiptItem(item, loan.returnDate));
                            screen.displayScannedItems();
                            self.waitForItem();
                        case InvalidLoanItem:
                            screen.displayInvalidLoanItemMessage();
                            self.waitForItem();
                        case ItemAlreadyBorrowed:
                            screen.displayAlreadyBorrowedMessage();
                            self.waitForItem();
                        case InvalidBorrower:
                            // LibraryCard is invalid, don't wait for another item.
                            screen.displayInvalidCard();
                    }
            }
        }
    }

    @role var scannedItems : {
        function iterator() : Iterator<ScannedItem>;
        function push(item : ScannedItem) : Int;
        function splice(pos : Int, len : Int) : Iterable<ScannedItem>;
        var length(default, null) : Int;

        public function addItem(item : ScannedItem)
            self.push(item);

        public function clearItems()
            self.splice(0, self.length);

        public function alreadyScanned(rfid : String) : Bool
            return self.exists(function(scannedItem) return scannedItem.item.rfid == rfid);
    }

    @role var screen : {
        function display(s : ScreenState) : Void;
        function displayMessage(state : ScreenState, waitMs : Int, ?thenDisplay : ScreenState) : Void;

        public function displayWelcome()
            display(Welcome);
        
        public function displayThankYouMessage()
            displayMessage(ThankYou, 4000, Welcome);

        public function displayEnterPin() {
            // Listen to keypad event
            keypad.waitForEnterPin();
            display(EnterPin({previousAttemptFailed: pinAttemptsLeft < 3}));
        }

        public function displayScannedItems() {
            // Listen to finish button events
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
            self.onFinishWithoutReceiptClicked(screen.displayDontForgetLibraryCard);
            self.onFinishWithReceiptClicked(printer.printReceipt);
        }
    }

    @role var keypad : {
        function onPinCodeEntered(callback : String -> Void, ?pos : haxe.PosInfos) : Void;

        public function waitForEnterPin() {
            self.onPinCodeEntered(cardReader.validatePin);
        }
    }

    @role var printer : {
        function print(line : String) : Void;
        function cutPaper() : Void;
        
        public function printReceipt() : Void {
            var buffer = [Date.now().format("%Y-%m-%d"), ""];

            for(scanned in scannedItems) {
                buffer.push(scanned.item.title);
                buffer.push("Return on " + scanned.returnDate.format("%Y-%m-%d"));
                buffer.push("");
            }

            var timer = new Timer(80);
            timer.run = function() {
                self.print(buffer.pop());
                if(buffer.length == 0) {
                    timer.stop();
                    self.cutPaper();
                    screen.displayDontForgetLibraryCard();
                }
            }
        }
    }

    @role var library : {
        var libraryItems(default, null) : Array<LoanItem>;
        var libraryCards(default, null) : Array<LibraryCard>;

        public function item(rfid : String) : LoanItem 
            return libraryItems.find(function(loanItem) return loanItem.rfid == rfid);

        public function card(rfid : String) : LibraryCard
            return libraryCards.find(function(libraryCard) return libraryCard.rfid == rfid);
    }
}
