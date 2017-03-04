import Data.Book;
import Data.Card;
import Data.Bluray;
import Data.LoanItem;
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
		var libraryItems : Array<LoanItem> = [
			new Book({ rfid: 'ITEM787', title: 'Anna Karenina', loanTimeDays: 21}), 
			new Bluray({ rfid: 'ITEM788', title: 'War and Peace', loanTimeDays: 14, length: 168}),
			new Book({ rfid: 'ITEM789', title: 'Master and Man', loanTimeDays: 21})
		];

		var libraryCards = [
			new Card({rfid: 'CARD54321', name: 'Leo Tolstoy', pin: '1234'})
		];

		var workspace : Array<DragDropItem> = cast libraryCards.array();
		var bookshelf : Array<DragDropItem> = cast libraryItems.array();

		var cardReader = new CardReader(libraryCards);
		var itemScanner = new ItemScanner(libraryItems);
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
