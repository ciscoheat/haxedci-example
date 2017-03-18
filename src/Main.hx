import Data.Book;
import Data.LibraryCard;
import Data.Bluray;
import Data.RfidItem;
import contexts.DragDropMechanics;
import contexts.LibraryBorrowMachine;
import views.HtmlElements;

class Main
{
	// Entry point
	static function main() 
		new Main().start();

	/////////////////////////////////////////////
	
	function new() {}
	
	function start() {
		
		///// Set up data for the system /////

		Data.libraryItems = [
			new Book({ rfid: 'ITEM787', title: 'Anna Karenina', loanTimeDays: 21}), 
			new Bluray({ rfid: 'ITEM788', title: 'War and Peace', loanTimeDays: 14, length: 168}),
			new Book({ rfid: 'ITEM789', title: 'Master and Man', loanTimeDays: 21})
		];

		Data.libraryCards = [
			new LibraryCard({rfid: 'CARD54321', name: 'Leo Tolstoy', pin: '1234'})
		];

		Data.libraryLoans = [];

		///// Set up views /////

		var bookshelf : Array<DragDropItem> = cast Data.libraryItems.array();
		var workspace : Array<DragDropItem> = cast Data.libraryCards.array();

		var scannerContents = [];
		var scanner = new gadgets.RfidScanner(function() {
			// The RFID scanner needs to return a String if something is in it,
			// this is a quick'n dirty way of doing that.
			return try Some(cast(scannerContents[0], RfidItem).rfid)
			catch(e : Dynamic) None;
		});

		var cardReaderContents = [];
		var cardReader = new gadgets.RfidScanner(function() {
			return try Some(cast(cardReaderContents[0], RfidItem).rfid)
			catch(e : Dynamic) None;
		});

		var printer = new gadgets.ReceiptPrinter();
		var screen = new views.ScreenView();
		var keypad = screen;
		var finishButtons = screen;

		// Display models in the main view with Mithril
		new views.MainView(bookshelf, cardReaderContents, workspace, scannerContents, screen, printer).mount();

		// Start the browser app by enabling drag'n'drop functionality
		var surfaces = [
			HtmlElements.Bookshelf => bookshelf,
			HtmlElements.CardReader => cardReaderContents,
			HtmlElements.Workspace => workspace,
			HtmlElements.Scanner => scannerContents
		];
		new DragDropMechanics(surfaces).start();

		// Start the Context that will do the actual borrowing
		new LibraryBorrowMachine(scanner, cardReader, screen, printer, keypad, finishButtons).start();
	}
}
