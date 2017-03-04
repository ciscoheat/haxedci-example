import haxe.ds.Option;
import Data.Card;

class CardReader implements HaxeContracts
{
	var rfidScanner : RfidScanner;
    var cardDatabase : Array<Data.Card>;

    public var contents(default, null) : Array<DragDrop.DragDropItem> = [];

	public function new(cardDatabase) {
		this.rfidScanner = new RfidScanner(detectRfid, 100);
        this.cardDatabase = cardDatabase;
	}

    public function currentCard() : Option<Card> {
        if(contents.length == 0) return None;

        return try Some(cast(contents[0], Card))
        catch(e : Dynamic) None;        
    }

    public function registerSingleCardChange(onCardChange : Option<Card> -> Void) {
		rfidScanner.registerSingleRfidChange(function(rfid) switch rfid {
            case None: onCardChange(None);
            case Some(rfid): 
                var card = cardDatabase.find(function(card) return card.rfid == rfid);
                onCardChange(card == null ? None : Some(card));
        });
    }

    function detectRfid() : Option<String> {
        return switch currentCard() {
            case None: None;
            case Some(card): Some(card.rfid);
        }
    }

	@invariants function inv() {
		Contract.invariant(rfidScanner != null);
        Contract.invariant(contents.length < 2, "More than one item in card reader.");
        Contract.invariant(contents.length == 0 || Std.is(contents[0], Card), "Invalid item in reader.");
	}
}