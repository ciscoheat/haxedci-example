/**
 *  Id's for unique html elements.
 */
@:enum abstract HtmlElements(String) to String {
  var Bookshelf = "bookshelf";
  var Printer = "printer";
  var Screen = "screen";
  var CardReader = "card-reader";
  var Workspace = "workspace";
  var Scanner = "scanner";

  @:to public function toElement()
      return js.Browser.document.querySelector('#$this');
}