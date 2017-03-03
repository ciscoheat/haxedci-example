import haxe.ds.Option;
import Data.RfidItem;

class ItemScanner implements HaxeContracts
{
	var rfidScanner : RfidScanner;
    public var contents(default, null) : Array<DragDrop.DragDropItem> = [];

	public function new() {
		rfidScanner = new RfidScanner(detectRfid, 100);
	}

    function detectRfid() {
        if(contents.length == 0) return None;

        return try Some(cast(contents[0], RfidItem).rfid)
        catch(e : Dynamic) None;
    }

    public function registerSingleItemChange(onItemChange : Option<String> -> Void) {
		rfidScanner.registerSingleRfidChange(onItemChange);
    }

	@invariants function inv() {
		Contract.invariant(rfidScanner != null);
	}
}