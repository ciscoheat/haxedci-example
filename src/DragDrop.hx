import js.Browser;
import js.html.HtmlElement;

typedef Dragula = Dynamic;

// id for unique app elements, represented in html
@:enum abstract AppElements(String) to String {
  var Bookshelf = "bookshelf";
  var Printer = "printer";
  var Screen = "screen";
  var CardReader = "card-reader";
  var Workspace = "workspace";
  var Scanner = "scanner";
  var Card = "card";
}

class DragDrop implements HaxeContracts
{
	static function q(query : String)
		return Browser.document.querySelector(query);

	public function new() {}

	public function start() {
		Contract.requires(Reflect.field(Browser.window, "dragula") != null);

		// Loaded from js in index.html
		var dragula : Dragula = Reflect.field(Browser.window, "dragula");

		dragula([Bookshelf, Workspace, Scanner, CardReader].map.fn(id => q('#' + id)), {
			accepts: acceptsDrop
		}).on('drop', onDrop);
	}
	
	function acceptsDrop(droppedItem : HtmlElement, targetElement : HtmlElement) : Bool {
		Contract.requires(droppedItem != null);
		Contract.requires(targetElement.id.length > 0);
		
		switch targetElement.id {
			// Scanner can only take one item
			// TODO: Access the real scanner.
			case Scanner if(targetElement.children.length > 0): 
				return false;
			case _:
		}

		return switch droppedItem.id {
			case Card: 
				targetElement.id != Bookshelf;
			case _:
				targetElement.id != CardReader;
		}
	}

	function onDrop(droppedItem : HtmlElement, targetElement : HtmlElement) {
		Contract.requires(droppedItem != null);
		Contract.requires(targetElement.id.length > 0);
		
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