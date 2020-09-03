package contexts;

import js.Browser;
import js.html.HtmlElement;
import views.HtmlElements;

using HtmlTools;

/**
 *  Javascript drag'n'drop library, loaded in index.html.
 *  @see https://github.com/bevacqua/dragula
 */
typedef Dragula = Dynamic;

/**
 *  A marker interface for objects that can be drag'n'dropped.
 */
interface DragDropItem {}

/**
 *  This class handles drag-drop functionality in the browser for HTML elements. 
 *  
 *  It is strongly coupled to the browser with both HTML and a
 *  javascript library, so it doesn't use DCI or any generalizations.
 */
@:nullSafety(Off) class DragDropMechanics implements HaxeContracts
{
	/**
	 *  Map of HTML id:s -> Array of drag'n'droppable items
	 */
	var surfaces : Map<String, Array<DragDropItem>>;
	
	/**
	 *  Dragula API, used to cancel the drag-drop operation so
	 *  Mithril can redraw the DOM based on the updated state.
	 */
	var drake : {cancel: ?Bool -> Void};

	public function new(surfaces : Map<String, Array<DragDropItem>>) {
		Contract.requires(surfaces != null);
		this.surfaces = surfaces;
	}

	public function start() {
		Contract.requires(Reflect.field(Browser.window, "dragula") != null);

		var dragula : Dragula = Reflect.field(Browser.window, "dragula");

		// Register all surfaces as a drag-drop container
		drake = dragula([for(id in surfaces.keys()) HtmlTools.q('#$id')], {
			accepts: acceptsDrop
		})
		.on('drag', onDrag)
		.on('drop', onDrop);
	}
	
	function acceptsDrop(droppedItem : HtmlElement, targetElement : HtmlElement) : Bool {
		Contract.requires(droppedItem != null);
		Contract.requires(targetElement.id.length > 0);
		
		return switch targetElement.id {
			// Scanner and CardReader can only take one item
			case Scanner:
				surfaces.get(targetElement.id).length < 1;
			case CardReader:
				surfaces.get(targetElement.id).length < 1 && droppedItem.classList.contains("card");
			case _:
				if(droppedItem.classList.contains("card")) {
					// Card can not be dropped on the bookshelf
					targetElement.id != Bookshelf;
				} else {
					// Only the card can be dropped on the card reader
					targetElement.id != CardReader;
				}
		}
	}

	// Temp data for storing the dragged item
	var dragData : {source : Array<DragDropItem>, sourcePos : Int};

	function onDrag(el : HtmlElement, sourceEl : HtmlElement) {
		Contract.requires(el != null);
		Contract.requires(surfaces.exists(sourceEl.id), "No surface found: " + sourceEl.id);

		var surface = surfaces.get(sourceEl.id);
		var pos = sourceEl.children.elPos(el);
		Contract.assert(pos >= 0, "Item not found in surface " + sourceEl.id);

		this.dragData = {
			source: surface,
			sourcePos: pos
		}

		//trace("Dragging from " + sourceEl.id + '[$pos]');
	}

	function onDrop(el : HtmlElement, targetEl : HtmlElement, _, sibling : Null<HtmlElement>) {
		Contract.requires(this.dragData != null);
		Contract.requires(el != null);
		Contract.requires(surfaces.exists(targetEl.id), "No surface found: " + targetEl.id);
		
		var target = surfaces.get(targetEl.id);

		var targetPos = sibling == null 
			? targetEl.children.length - 1 
			: targetEl.children.elPos(sibling) - 1;

		// Splice from source to target
		var removed = this.dragData.source.splice(this.dragData.sourcePos, 1);
		target.insert(targetPos, removed[0]);
		this.dragData = null;

		//trace('Dropped ${removed} in ' + targetEl.id + '[$targetPos]');

		// Cancel the drag so elements won't change, then
		// redraw with Mithril immediately to update the DOM.
		drake.cancel(true);		
		mithril.M.redraw();
	}
}
