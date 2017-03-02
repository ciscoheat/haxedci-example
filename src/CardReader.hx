import haxe.ds.Option;
import Data.Card;

class CardReader implements HaxeContracts
{
	var rfidScanner : RfidScanner;
    public var contents(default, null) : Array<DragDrop.DragDropItem> = [];

	public static function q(query : String)
		return js.Browser.document.querySelector(query);
	
	public function new() {
		rfidScanner = new RfidScanner(detectRfid, 100);
	}

    function detectRfid() {
        return if(contents.length == 0) None
        // TODO: Safe casting to Card
        else Some(cast(contents[0], Card).rfid);
    }

    function onRfidChange(rfid) {
        Contract.requires(rfid != null);

        switch rfid {
            case None: 
                trace("RFID removed.");
            case Some(id):
        		trace('RFID detected: $id');
        }

        rfidScanner.registerSingleRfidChange(onRfidChange);
    }

	public function start() {
		rfidScanner.registerSingleRfidChange(onRfidChange);
        trace('Card reader started');
	}

	@invariants function inv() {
		Contract.invariant(rfidScanner != null);
	}
}