import Data.Book;
import Data.Card;
import Data.Bluray;
import DragDrop.DragDropItem;

class Main implements HaxeContracts
{
	// Entry point
	static function main() 
		new Main().start();

	/////////////////////////////////////////////
	
	function new() {}
	
	function start() {
		// Set up models
		var bookshelf : Array<DragDropItem> = [
			new Book({ rfid: 'ITEM787', title: 'Anna Karenina', loanTime: 21}), 
			new Bluray({ rfid: 'ITEM788', title: 'War and Peace', loanTime: 21, length: 168}),
			new Book({ rfid: 'ITEM789', title: 'Master and Man', loanTime: 14})
		];

		var workspace : Array<DragDropItem> = [
			new Card({rfid: 'CARD12345', name: 'Leo Tolstoy'})
		];

		var cardReader = new CardReader();
		var itemScanner = new ItemScanner();
		var screen = new views.ScreenView();
		var printer = {};

		// Display models in the main view with Mithril
		new views.MainView(bookshelf, cardReader, workspace, itemScanner, screen).mount();

		// Start the browser app by enabling drag'n'drop functionality
		var surfaces = [
			HtmlElements.Bookshelf => cast bookshelf,
			HtmlElements.CardReader => cardReader.contents,
			HtmlElements.Workspace => workspace,
			HtmlElements.Scanner => itemScanner.contents
		];
		new DragDrop(surfaces).start();

		// Start the Context that will do the actual borrowing
		new BorrowLibraryItems(itemScanner, cardReader, screen, printer).waitForCard();
	}
}
