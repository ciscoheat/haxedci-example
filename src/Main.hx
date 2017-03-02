import js.Browser;
import mithril.M;
import Data.Book;
import Data.Card;
import Data.Bluray;
import Data.LoanItem;
import DragDrop.DragDropItem;

class Main implements Context implements HaxeContracts implements Mithril
{
	// Entry point
	static function main() 
		new Main().start();

	static function q(query : String)
		return Browser.document.querySelector(query);

	/////////////////////////////////////////////
	
	function new() {}
	
	function start() {
		// Set up models

		//
		var bookshelf : Array<LoanItem> = [
			new Book({ rfid: '787', title: 'Anna Karenina', loanTime: 21}), 
			new Bluray({ rfid: '788', title: 'War and Peace', loanTime: 21, length: 168}),
			new Book({ rfid: '789', title: 'Master and Man', loanTime: 14})
		];

		var workspace : Array<DragDropItem> = [
			new Card({rfid: '123456789', name: 'Leo Tolstoy'})
		];

		var cardReader = new CardReader();

		var scanner = [];

		new views.MainView(bookshelf, cardReader, workspace, scanner).mount();

		// Enable the "physical" equipment
		cardReader.start();

		// Start the app by enabling drag'n'drop functionality
		var surfaces = [
			HtmlElements.Bookshelf => cast bookshelf,
			HtmlElements.CardReader => cardReader.contents,
			HtmlElements.Workspace => workspace,
			HtmlElements.Scanner => scanner
		];
		
		new DragDrop(surfaces).start();
	}
}
