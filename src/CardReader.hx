import haxe.ds.Option;
import Data.Card;

class CardReader implements HaxeContracts
{
	var rfidScanner : RfidScanner;

    var currentCard : Card;

	public static function q(query : String)
		return js.Browser.document.querySelector(query);
	
	public function new() {
		rfidScanner = new RfidScanner(detectRfid, onRfidChange);
	}

    function detectRfid() {
        var scanner = q('#card-reader');
        return if(scanner.children.length == 0) None
        else Some(scanner.children[0].id);
    }

    function onRfidChange(rfid) {
        Contract.requires(rfid != null);

        switch rfid {
            case None: 
                trace("RFID removed.");
            case Some(id):
        		trace('RFID detected: $id');
        }
    }

	public function start() {
		rfidScanner.startDetection(100);
        trace('Card reader started');
	}

	@invariants function inv() {
		Contract.invariant(rfidScanner != null);
	}
}