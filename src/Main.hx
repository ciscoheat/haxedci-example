import js.Browser;
import mithril.M;
import Data.Book;
import Data.Card;

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
		// Set up models
		var books = [
			new Book({ rfid: '787', title: 'Anna Karenina', loanTime: 21}), 
			new Book({ rfid: '788', title: 'War and Peace', loanTime: 21}),
			new Book({ rfid: '789', title: 'Master and Man', loanTime: 14})
		];

		var cards = [
			new Card({rfid: '123456789', name: 'Leo Tolstoy'})
		];

		var cardReader = new CardReader();

		new views.MainView(books, cardReader).mount();

		// Enable the "physical" equipment
		cardReader.start();

		// Start the app by enabling drag'n'drop functionality
		new DragDrop().start();
	}
}
