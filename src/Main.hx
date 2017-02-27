import js.Browser;
import mithril.M;

class Main implements Context implements HaxeContracts implements Mithril
{
	// Entry point
	static function main() 
		new Main().start();

	public static function q(query : String)
		return Browser.document.querySelector(query);

	/////////////////////////////////////////////
	
	function new() {}
	
	function start() {
		var booksOnShelf = ['Anna Karenina', 'War and Peace', 'Master and Man'];

		M.render(q("#bookshelf"), booksOnShelf.map(function(book) 
			m('.book', book)
		));

		M.render(q('#workspace'), m('img#card[src=/images/card.svg]'));

		// Start drag-drop functionality
		new DragDrop().start();

		new CardReader().start();

		trace("Started!");
	}
}

class CardReader implements HaxeContracts
{
	var rfidScanner : RfidScanner;

	public static function q(query : String)
		return Browser.document.querySelector(query);
	
	public function new() {
		rfidScanner = new RfidScanner(function() {
			var scanner = q('#card-reader');
			return if(scanner.children.length == 0) None
			else Some(scanner.children[0].id);
		}, function(rfid) {
			trace('RFID detected: $rfid');
		});
	}

	public function start() {
		rfidScanner.startDetection(100);
	}

	@invariants function inv() {
		Contract.invariant(rfidScanner != null);
	}
}