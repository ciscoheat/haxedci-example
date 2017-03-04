import haxe.ds.Option;
import views.ScreenView.ScreenState;
import Data.Card;
import Data.LoanItem;
import haxecontracts.Contract.assert;

/**
 *  Use case implementation.
 *  @see https://docs.google.com/spreadsheets/d/1TSpjKUhjvP9pMRukt_mInHVbdQWsXHzFjSymQ3VyGmE/edit#gid=2
 */
class BorrowLibraryItems implements dci.Context
{
    static var maxPinAttempts(default, never) : Int = 3;

    var pinAttemptsLeft : Int;
    var scannedItems : Array<LoanItem>;

    public function new(scanner, cardReader, screen, printer) {
        this.scanner = scanner;
        this.cardReader = cardReader;
        this.screen = screen;
        this.printer = printer;
    }
    
    public function waitForCard() {
        cardReader.waitForCardChange();
    }
    
    @role var cardReader : {
        function registerSingleCardChange(callback : Option<Card> -> Void) : Void;
        function currentCard() : Option<Card>;
        
        public function waitForCardChange() {
            pinAttemptsLeft = maxPinAttempts;
            scannedItems = [];
            self.registerSingleCardChange(cardChanged);
        }

        function cardChanged(data : Option<Card>) switch data {
            case None: 
                screen.displayThankYou();
            case Some(card):

                // Register again to detect remove event.
                self.registerSingleCardChange(cardChanged);
                screen.displayEnterPin();
        }

        public function validatePin(pin : String) {
            switch currentCard() {
                case None: 
                    assert(false, "No card in reader.");
                case Some(card):
                    if(card.pin == pin)
                        screen.displayScannedItems();
                    else if(--pinAttemptsLeft > 0)
                        screen.displayEnterPin();
                    else
                        screen.displayInvalidPin();
            }
        }
    }

    @role var screen : {
        var state(default, set) : ScreenState;
        function registerSinglePinCodeEntered(callback : String -> Void) : Void;
        
        public function displayThankYou() {
            self.state = ThankYou;
            self.waitThenDisplayWelcomeScreen();
        }

        public function displayEnterPin() {
            self.state = EnterPin({previousAttemptFailed: pinAttemptsLeft < 3});
            self.registerSinglePinCodeEntered(cardReader.validatePin);
        }

        public function displayScannedItems() {
            self.state = DisplayBorrowedItems(scannedItems);
            scanner.waitForItem();
        }

        public function displayInvalidPin() {
            self.state = InvalidPin;
        }

        function waitThenDisplayWelcomeScreen() {
            haxe.Timer.delay(function() {
                if(self.state.equals(ThankYou)) self.state = Welcome;
            }, 4000);
            cardReader.waitForCardChange();
        }
    }

    @role var printer : {
        
        
        public function roleMethod() {
            
        }
    }

    @role var scanner : {
        function registerSingleItemChange(onItemChange : Option<LoanItem> -> Void) : Void;

        public function waitForItem() {
            self.registerSingleItemChange(itemScanned);
        }

        function itemScanned(item : Option<LoanItem>) switch item {
            case None: self.waitForItem();
            case Some(item):
                trace("Scanned " + item.title);
                scannedItems.push(item);
                screen.displayScannedItems();
        }
    }
}