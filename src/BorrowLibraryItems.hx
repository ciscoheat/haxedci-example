import haxe.ds.Option;

/**
 *  Use case implementation.
 *  @see https://docs.google.com/spreadsheets/d/1TSpjKUhjvP9pMRukt_mInHVbdQWsXHzFjSymQ3VyGmE/edit#gid=2
 */
class BorrowLibraryItems implements dci.Context
{
    public function new(scanner, cardReader, screen, printer) {
        this.scanner = scanner;
        this.cardReader = cardReader;
        this.screen = screen;
        this.printer = printer;
    }
    
    public function waitForCard() {
        cardReader.waitForChange();
    }
    
    @role var scanner : {
        
        
        public function roleMethod() {
            
        }
    }
    
    @role var cardReader : {
        function registerSingleCardChange(callback : haxe.ds.Option<String> -> Void) : Void;
        
        public function waitForChange() {
            self.registerSingleCardChange(rfidChanged);
        }

        function rfidChanged(data : Option<String>) {
            trace(data);
            self.waitForChange();
        }
    }

    @role var screen : {
        
        
        public function roleMethod() {
            
        }
    }

    @role var printer : {
        
        
        public function roleMethod() {
            
        }
    }
}