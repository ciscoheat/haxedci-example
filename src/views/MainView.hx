package views;

import mithril.M;
import views.HtmlElements;
import contexts.DragDropMechanics.DragDropItem;
import gadgets.ReceiptPrinter;

/**
 *  Uses the HTML in index.html to display app elements.
 */
class MainView implements Mithril
{
    var screenView : ScreenView;
    var cardReader : Array<DragDropItem>;
    var bookshelf : Array<DragDropItem>;
    var workspace : Array<DragDropItem>;
    var itemScanner : Array<DragDropItem>;
    var printer : ReceiptPrinter;

    public function new(bookshelf, cardReader, workspace, itemScanner, screenView, printer) {
        this.bookshelf = bookshelf;
        this.workspace = workspace;
        this.cardReader = cardReader;
        this.itemScanner = itemScanner;
        this.screenView = screenView;
        this.printer = printer;
    }

    /**
     *  Mount mithril components for the app elements.
     */
    public function mount() {
        // Using the abstract HtmlElements enum to refer directly to
        // the HTML element, as a compiler-checked enum value instead of a string:
        M.mount(Screen, screenView);

		M.mount(Bookshelf, {view: surfaceView.bind(bookshelf)});
        M.mount(CardReader, {view: surfaceView.bind(cardReader)});
        M.mount(Scanner, {view: surfaceView.bind(itemScanner)});
        M.mount(Workspace, {view: surfaceView.bind(workspace)});

        M.mount(Printer, printer);
    }

    // In a larger example, different surfaces would probably have their own view template,
    // but here the items look the same no matter where they are.
    function surfaceView(surface : Array<DragDropItem>) return surface.map(function(item) {
        return switch Type.getClass(item) {
            case Data.LibraryCard: 
                m('img.card[src=images/card.svg]');
            case Data.Book:
                var item : Data.Book = cast item;
                m('.book.cover', item.title);
            case Data.Bluray:
                var item : Data.Bluray = cast item;
                m('.bluray.cover', item.title);                
            case unknown: 
                m('div', {style:"color:red"}, 'View not found for: ' + Type.getClassName(unknown));
        }
    });
}
