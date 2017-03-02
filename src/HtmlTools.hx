import js.Browser;
import js.html.HtmlElement;
import js.html.HTMLCollection;

class HtmlTools
{
	public static function q(query : String)
		return Browser.document.querySelector(query);
	
	public static function elPos(collection : HTMLCollection, el : HtmlElement) : Int {
		for(i in 0...collection.length) {
			if(collection.item(i) == el) return i;
		}
		return -1;
	}
}
