package views;

/**
 *  Id's for unique html elements in the app.
 */
@:enum abstract HtmlElements(String) to String {
	var Bookshelf = "bookshelf";
	var Printer = "printer";
	var Screen = "screen";
	var CardReader = "card-reader";
	var Workspace = "workspace";
	var Scanner = "scanner";

	/**
	 *  Auto-convert enum to html element with matching id.
	 */
	@:to public function toElement()
		return js.Browser.document.querySelector('#$this');
}
