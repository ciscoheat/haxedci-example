import haxe.ds.Option;
import Data.Card;

class CardReader implements HaxeContracts
{
	var rfidScanner : RfidScanner;
    public var contents(default, null) : Array<DragDrop.DragDropItem> = [];

	public function new() {
		rfidScanner = new RfidScanner(detectRfid, 100);
	}

    function detectRfid() {
        if(contents.length == 0) return None;

        return try Some(cast(contents[0], Card).rfid)
        catch(e : Dynamic) None;
    }

    public function registerSingleCardChange(onCardChange : Option<String> -> Void) {
		rfidScanner.registerSingleRfidChange(onCardChange);
    }

	@invariants function inv() {
		Contract.invariant(rfidScanner != null);
        Contract.invariant(contents.length < 2, "More than one item in card reader.");
        Contract.invariant(contents.length == 0 || Std.is(contents[0], Card), "Invalid item in reader.");
	}
}