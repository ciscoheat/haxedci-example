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
    var scannedItems : Array<LoanItem>;
    var authorizedCard : Card;

    public function new(scanner, cardReader, screen, printer, keypad) {
        this.scanner = scanner;
        this.cardReader = cardReader;
        this.screen = screen;
        this.printer = printer;
        this.library = Data;
        this.keypad = keypad;
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
        scannedItems = [];
        authorizedCard = null;
    }

    @role var cardReader : {
        function scanRfid(callback : Option<String> -> Void) : Void;

        public function waitForCardChange() {            
            self.scanRfid(self.rfidChanged);
        }

        function rfidChanged(data : Option<String>) switch data {
            case None:
                // No card, keep waiting
                self.waitForCardChange();

            case Some(rfid):
                // New RFID found. Look up current card in library database, display pin screen if valid.
                var card = library.cards().find(function(card) return card.rfid == rfid);
                if(card != null) {
                    self.createCardRemoveWaitLoop();
                    keypad.waitForEnterPin(card);
                } else {
                    // Card not found, ignore it.
                    self.waitForCardChange();
                }
        }

        function createCardRemoveWaitLoop() {
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

        public function validatePin(card : Card, pin : String) {
            if(card.pin == pin) {
                authorizedCard = card;
                screen.displayScannedItems();
                scanner.waitForItem();
            }
            else if(--pinAttemptsLeft > 0)
                keypad.waitForEnterPin(card);
            else
                screen.displayInvalidPin();
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

        public function displayInvalidPin() {
            display(InvalidPin);
        }
    };

    @role var scanner : {
        function scanRfid(callback : Option<String> -> Void) : Void;
        function lastScannedRfid() : Option<String>;

        public function waitForItem()
            self.scanRfid(self.rfidScanned);

        function rfidScanned(rfid : Option<String>) {
            // If the card is removed, return immediately.
            if(authorizedCard == null) return;
            switch rfid {
                case None: 
                    self.waitForItem();
                case Some(rfid):
                    var alreadyScanned = scannedItems.find(function(item) return item.rfid == rfid);

                    if(alreadyScanned != null) {
                        scannedItems.remove(alreadyScanned);
                        scannedItems.push(alreadyScanned);
                        screen.displayScannedItems();
                        self.waitForItem();
                    } else {
                        var item = library.items().find(function(item) return item.rfid == rfid);

                        if(item == null)
                            self.waitForItem();
                        else {
                            // TODO: Call borrow single library item context.
                            scannedItems.push(item);
                            screen.displayScannedItems();
                            self.waitForItem();
                        }
                    }
            }
        }
    }

    @role var keypad : {
        function onPinCodeEntered(callback : String -> Void) : Void;

        public function waitForEnterPin(card : Card) {
            screen.displayEnterPin();
            self.onPinCodeEntered(cardReader.validatePin.bind(card));
        }
    };

    @role var printer : {};

    @role var library : {
        public var libraryItems(default, null) : Array<LoanItem>;
        public var libraryCards(default, null) : Array<Card>;

        public function items() : Array<LoanItem> return libraryItems;
        public function cards() : Array<Card> return libraryCards;
    }
}
