import haxe.ds.Option;
import views.ScreenView.ScreenState;
import Data.Card;
import Data.LoanItem;

/**
 *  Use case implementation.
 *  @see https://docs.google.com/spreadsheets/d/1TSpjKUhjvP9pMRukt_mInHVbdQWsXHzFjSymQ3VyGmE/edit#gid=2
 */
class BorrowLibraryItems implements dci.Context
{
    static var maxPinAttempts(default, never) : Int = 3;

    var pinAttemptsLeft : Int;

    public function new(scanner, cardReader, screen, printer) {
        this.scanner = scanner;
        this.cardReader = cardReader;
        this.screen = screen;
        this.printer = printer;
        this.library = Data;
        this.scannedItems = [];
    }
    
    public function waitForCard() {
        cardReader.waitForCardChange();
    }
    
    @role var cardReader : {
        function registerSingleRfidChange(event : Option<String> -> Void) : Void;
        
        public function waitForCardChange() {
            pinAttemptsLeft = maxPinAttempts;
            scannedItems.clear();
            self.registerSingleRfidChange(rfidChanged);
        }

        function rfidChanged(data : Option<String>) switch data {
            case None: 
                screen.displayThankYou();
            case Some(rfid):
                // Register again immediately to detect remove event across the whole Context.
                self.registerSingleRfidChange(rfidChanged);

                var card = library.cards().find(function(card) return card.rfid == rfid);

                if(card != null)
                    screen.displayEnterPin(card);
        }

        public function validatePin(card : Card, pin : String) {
            if(card.pin == pin)
                screen.displayScannedItems();
            else if(--pinAttemptsLeft > 0)
                screen.displayEnterPin(card);
            else
                screen.displayInvalidPin();
        }
    }

    var screenTimer : haxe.Timer;

    @role var screen : {
        var state(default, set) : ScreenState;
        function registerSinglePinCodeEntered(callback : String -> Void) : Void;
        
        public function displayThankYou() {
            self.state = ThankYou;

            if(screenTimer != null) screenTimer.stop();
            screenTimer = new haxe.Timer(4000);
            screenTimer.run = function() {
                if(self.state.equals(ThankYou)) self.state = Welcome;
            }
            cardReader.waitForCardChange();
        }

        public function displayEnterPin(card : Card) {
            self.state = EnterPin({previousAttemptFailed: pinAttemptsLeft < 3});
            self.registerSinglePinCodeEntered(cardReader.validatePin.bind(card));
        }

        public function displayScannedItems() {
            self.state = DisplayBorrowedItems(scannedItems);
            scanner.waitForItem();
        }

        public function displayInvalidPin() {
            self.state = InvalidPin;
        }
    }

    @role var scanner : {
        function registerSingleRfidChange(event : Option<String> -> Void) : Void;

        public function waitForItem() {
            self.registerSingleRfidChange(rfidScanned);
        }

        function rfidScanned(rfid : Option<String>) switch rfid {
            case None: self.waitForItem();
            case Some(rfid):
                trace("Scanned RFID " + rfid);
                var item = library.items().find(function(item) return item.rfid == rfid);
                if(item == null)
                    self.waitForItem();
                else if(scannedItems.isAlreadyScanned(rfid))
                    self.waitForItem();
                else
                    scannedItems.addItem(item);
        }
    }

    @role var scannedItems : {
        function iterator() : Iterator<LoanItem>;
        function push(item : LoanItem) : Void;
        function splice(pos : Int, len : Int) : Iterable<LoanItem>;
        
        public function isAlreadyScanned(rfid : String) : Bool
            return self.exists(function(item) return item.rfid == rfid);

        public function addItem(item : LoanItem) {
            trace("Borrowed " + item.title);
            self.push(item);
            // TODO: Call BorrowLibraryItem Context.
            screen.displayScannedItems();
        }

        // TODO: Not leading anywhere
        public function clear()
            self.splice(0, -1);
    }

    @role var library : {
        public var libraryItems(default, null) : Array<LoanItem>;
        public var libraryCards(default, null) : Array<Card>;

        public function items() : Array<LoanItem> return libraryItems;
        public function cards() : Array<Card> return libraryCards;
    }

    @role var printer : {
        public function roleMethod() {
            
        }
    }    
}

/**
 *  For borrowing a single library item.
 */
 /*
class BorrowLibraryItem implements dci.Context
{
    public function new(firstRole, secondRole) {
        this.firstRole = firstRole;
        this.secondRole = secondRole;
    }
    
    public function systemOperation() {
        firstRole.roleMethod();
    }
    
    @role var firstRole : {
        function contract() : Void;
        
        public function roleMethod() {
            secondRole.otherRoleMethod();
        }
    }
    
    @role var secondRole : {
        function contract() : Void;
        
        public function otherRoleMethod() {
            self.contract();
        }
    }
}
*/