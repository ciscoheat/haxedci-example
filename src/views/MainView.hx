package views;
import mithril.M;
import HtmlElements;
import DragDrop.DragDropItem;

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

    public function new(bookshelf, cardReader, workspace, itemScanner, screenView) {
        this.bookshelf = bookshelf;
        this.workspace = workspace;
        this.cardReader = cardReader;
        this.itemScanner = itemScanner;
        this.screenView = screenView;
    }

    /**
     *  Mount mithril components for the app elements.
     */
    public function mount() {
        // Using the abstract HtmlElements class, to refer directly to
        // the HTML element with an enum value:
        M.mount(Screen, screenView);

		M.mount(Bookshelf, {view: surfaceView.bind(bookshelf)});
        M.mount(CardReader, {view: surfaceView.bind(cardReader)});
        M.mount(Scanner, {view: surfaceView.bind(itemScanner)});
        M.mount(Workspace, {view: surfaceView.bind(workspace)});

        M.mount(Printer, {view: function()
            m('.box', 
                m('.slot')
            )
        });        
    }

    function surfaceView(surface : Array<DragDropItem>) return surface.map(function(item) {
        return switch Type.getClass(item) {
            case Data.Card: 
                m('img#card[src=images/card.svg]');
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
