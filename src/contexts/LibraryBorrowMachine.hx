package contexts;

import haxe.ds.Option;
import haxe.Timer;
import views.ScreenView.ScreenState;
import Data.LibraryCard;
import Data.LoanItem;
import Data.ScannedItem;
import Data.ReceiptItem;

@:publicFields private class State
{
    var pinAttemptsRemaining = LibraryBorrowMachine.maxPinAttempts;
    var authorizedCard : Null<LibraryCard>;
    final scannedItems : Array<ScannedItem> = [];

    public function new() {}
}

/**
 *  Use case implementation.
 *  @see https://docs.google.com/spreadsheets/d/1TSpjKUhjvP9pMRukt_mInHVbdQWsXHzFjSymQ3VyGmE/edit#gid=2
 */
class LibraryBorrowMachine implements dci.Context
{
    public static final maxPinAttempts = 3;

    final state : State;

    ///// Constructor and System Operations /////

    public function new(scanner, cardReader, screen, printer, keypad, finishButtons) {
        this.scanner = scanner;
        this.cardReader = cardReader;
        this.screen = screen;
        this.printer = printer;
        this.keypad = keypad;
        this.finishButtons = finishButtons;

        this.state = new State();
        this.scannedItems = state.scannedItems;
        this.library = Data;
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
        state.scannedItems.splice(0, state.scannedItems.length);
        state.pinAttemptsRemaining = maxPinAttempts;
        state.authorizedCard = null;
    }

    ///// Roles /////

    @role final cardReader : {
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
                switch library.card(rfid) {
                    case None:
                        screen.displayInvalidCard();
                    case Some(card):
                        screen.displayEnterPin();
                }
        }

        function createWaitLoopForCardRemoval() {
            final removeCardLoop = new haxe.Timer(50);
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
                    switch library.card(rfid) {
                        case None:
                            screen.displayInvalidCard();
                            
                        case Some(card):
                            if(card.pin == pin) {
                                // PIN ok, authorize card and move to scanning of items.
                                state.authorizedCard = card;
                                screen.displayScannedItems();
                                scanner.waitForItem();
                            }
                            else {
                                state.pinAttemptsRemaining--;

                                if(state.pinAttemptsRemaining > 0) {
                                    screen.displayEnterPin();
                                }
                                else {
                                    screen.displayTooManyInvalidPin();
                                }
                            }
                    }

                case None:
                    // LibraryCard already removed.
            });
        }
    }

    @role final scanner : {
        function scanRfid(callback : Option<String> -> Void) : Void;

        public function waitForItem()
            self.scanRfid(self.readLoanItem);

        function readLoanItem(rfid : Option<String>) {
            if(state.authorizedCard == null) return;

            switch rfid {
                case Some(rfid) if(!scannedItems.alreadyScanned(rfid)):
                    switch library.item(rfid) {
                        case None:
                            screen.displayInvalidLoanItemMessage();
                            self.waitForItem();

                        case Some(item):
                            self.borrowLoanItem(item);
                    }

                case _:
                    self.waitForItem();
            }
        }

        function borrowLoanItem(item : LoanItem) {
            if(state.authorizedCard == null) return;

            switch new BorrowLoanItem(item, state.authorizedCard).borrow() {
                case Ok(loan):
                    // Emulate a short database connection delay
                    Timer.delay(function() {
                        scannedItems.addItem(new ReceiptItem(item, loan.returnDate));
                        screen.displayScannedItems();
                        self.waitForItem();
                    }, Std.random(400) + 100);
                    return;
                case InvalidLoanItem:
                    screen.displayInvalidLoanItemMessage();
                case ItemAlreadyBorrowed:
                    screen.displayAlreadyBorrowedMessage();
                case InvalidBorrower:
                    // LibraryCard is invalid, don't wait for another item.
                    screen.displayInvalidCard();
                    return;
            }

            self.waitForItem();
        }
    }

    @role final scannedItems : {
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

    @role final screen : {
        function display(s : ScreenState) : Void;
        function displayMessage(state : ScreenState, waitMs : Int, ?thenDisplay : ScreenState) : Void;

        public function displayWelcome()
            display(Welcome);
        
        public function displayThankYouMessage()
            displayMessage(ThankYou, 4000, Welcome);

        public function displayEnterPin() {
            // Listen to keypad event
            keypad.waitForEnterPin();
            display(EnterPin({
                previousAttemptFailed: state.pinAttemptsRemaining < maxPinAttempts
            }));
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
            displayMessage(InvalidLoanItem, 100, DisplayBorrowedItems(scannedItems));

        public function displayAlreadyBorrowedMessage()
            displayMessage(ItemAlreadyBorrowed, 3000);

        public function displayDontForgetLibraryCard()
            display(DontForgetLibraryCard);
    }

    @role final finishButtons : {
        function onFinishWithoutReceiptClicked(callback : Void -> Void, ?pos : haxe.PosInfos) : Void;
        function onFinishWithReceiptClicked(callback : Void -> Void, ?pos : haxe.PosInfos) : Void;

        public function waitForFinishClick() {
            self.onFinishWithoutReceiptClicked(screen.displayDontForgetLibraryCard);
            self.onFinishWithReceiptClicked(printer.printReceipt);
        }
    }

    @role final keypad : {
        function onPinCodeEntered(callback : String -> Void, ?pos : haxe.PosInfos) : Void;

        public function waitForEnterPin() {
            self.onPinCodeEntered(cardReader.validatePin);
        }
    }

    @role final printer : {
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
                final current = buffer.pop();
                if(current == null) {
                    timer.stop();
                    self.cutPaper();
                    screen.displayDontForgetLibraryCard();
                } else {
                    self.print(current);
                }
            }
        }
    }

    @role final library : {
        var libraryItems(default, null) : Array<LoanItem>;
        var libraryCards(default, null) : Array<LibraryCard>;

        public function item(rfid : String) : Option<LoanItem> {
            final libraryItem = self.libraryItems.find(loanItem -> loanItem.rfid == rfid);
            return libraryItem == null ? None : Some(libraryItem);
        }

        public function card(rfid : String) : Option<LibraryCard> {
            final libraryCard = libraryCards.find(libraryCard -> libraryCard.rfid == rfid);
            return libraryCard == null ? None : Some(libraryCard);
        }
    }
}
