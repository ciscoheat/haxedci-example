import haxe.ds.Option;
import Data.RfidItem;
import Data.LoanItem;

class ItemScanner implements HaxeContracts
{
    public var contents(default, null) : Array<DragDrop.DragDropItem> = [];
	
    var rfidScanner : RfidScanner;
    var libraryItems : Array<LoanItem>;

	public function new(libraryItems) {
		this.rfidScanner = new RfidScanner(detectRfid, 100);
        this.libraryItems = libraryItems;
	}

    function detectRfid() {
        if(contents.length == 0) return None;

        return try Some(cast(contents[0], RfidItem).rfid)
        catch(e : Dynamic) None;
    }

    public function registerSingleItemChange(onItemChange : Option<LoanItem> -> Void) {
		rfidScanner.registerSingleRfidChange(function(rfid : Option<String>) {
            onItemChange(switch rfid {
                case None: None;
                case Some(rfid):
                    var item = libraryItems.find(function(item) return item.rfid == rfid);
                    if(item == null) None
                    else Some(item);
            });
        });
    }

	@invariants function inv() {
		Contract.invariant(rfidScanner != null);
	}
}