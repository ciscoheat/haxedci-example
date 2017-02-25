import js.Browser;
import mithril.M;

class Main implements Context implements HaxeContracts implements Mithril
{
	// Entry point
	static function main() {
		new Main().start();
	}

	static function q(query : String) return Browser.document.querySelector(query);
	
	function new() {
		Contract.ensures(
			BOOKSHELF != null && SCREEN != null && CARDREADER != null &&
			WORKSPACE != null && SCANNER != null && PRINTER != null
		);
				
		this.BOOKSHELF = q('#bookshelf');
		this.PRINTER = q('#printer');
		this.SCREEN = q('#screen');
		this.CARDREADER = q('#card-reader');
		this.WORKSPACE = q('#workspace');
		this.SCANNER = q('#scanner');
	}
	
	function start() {
		// Loaded from js in index.html
		var dragula : Dynamic = Reflect.field(Browser.window, "dragula");

		dragula(['#bookshelf', '#workspace', '#scanner', '#card-reader'].map(q), {
			accepts: function(el, target, source, sibling) {
				return new DragDrop(el, target).acceptsDrop();
			}
		}).on('drop', function(el, target, source, sibling) {
			new DragDrop(el, target).onDrop();
		});

		var booksOnShelf = ['Anna Karenina', 'War and Peace', 'Master and Man'];

		M.render(q("#bookshelf"), booksOnShelf.map(function(book) 
			m('.book', book)
		));

		trace("Started!");
	}
	
	@role var BOOKSHELF : {
		var id : String;
	}
	
	@role var PRINTER : {
		var id : String;
	}
	
	@role var SCREEN : {
		var id : String;
	}
	
	@role var CARDREADER : {
		var id : String;
	}

	@role var WORKSPACE : {
		var id : String;
	}
	
	@role var SCANNER : {
		var id : String;
	}	
}

class DragDrop
{
	var droppedItem : js.html.HtmlElement;	
	var targetElement : js.html.HtmlElement;

	public function new(droppedItem, targetElement) {
		this.droppedItem = droppedItem;
		this.targetElement = targetElement;
	}
	
	public function acceptsDrop() {
		switch targetElement.id {
			// Scanner can only take one item
			// TODO: Access the real scanner.
			case "scanner" if(targetElement.children.length > 0): return false;
			case _:
		}

		return switch droppedItem.id {
			case "card": 
				targetElement.id != "bookshelf";
			case _:
				targetElement.id != "card-reader";
		}
	}

	public function onDrop() {
		trace(droppedItem);
		trace(targetElement);
		/*
		if(el.classList.contains('book')) {
			var from = source.id == "workspace" ? booksOnWorkspace : booksOnShelf
			var to = target.id == "workspace" ? booksOnWorkspace : booksOnShelf
			to.push(removeFirst(from, function(book) { return book.id == el.innerText }))

			console.log(to)
		}
		*/
	}
}