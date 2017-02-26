import js.Browser;
import mithril.M;

class Main implements Context implements HaxeContracts implements Mithril
{
	// Entry point
	static function main() 
		new Main().start();

	static function q(query : String)
		return Browser.document.querySelector(query);
	
	function new() {}
	
	function start() {
		var booksOnShelf = ['Anna Karenina', 'War and Peace', 'Master and Man'];

		M.render(q("#bookshelf"), booksOnShelf.map(function(book) 
			m('.book', book)
		));

		// Start drag-drop functionality
		new DragDrop().start();

		trace("Started!");
	}
}