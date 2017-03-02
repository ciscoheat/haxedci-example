package views;
import mithril.M;
import HtmlElements;
import DragDrop.DragDropItem;

/**
 *  Uses the HTML in index.html to display all items
 */
class MainView implements Mithril implements Context
{
    var screenView : ScreenView;
    var cardReader : CardReader;

    var bookshelf : Array<Data.LoanItem>;
    var workspace : Array<DragDropItem>;
    var scanner : Array<DragDropItem>;

    public function new(bookshelf, cardReader, workspace, scanner) {
        this.bookshelf = bookshelf;
        this.workspace = workspace;
        this.cardReader = cardReader;
        this.scanner = scanner;

        this.screenView = new ScreenView();
    }

    /**
     *  Mount mithril components for the app elements.
     */
    public function mount() {
        // Using the abstract HtmlElements class, to refer directly to
        // the HTML element with an enum value:
		M.mount(Bookshelf, {view: bookshelfView});

        M.mount(Printer, {view: function()
            m('.box', 
                m('.slot')
            )
        });

        M.mount(Screen, screenView);

        M.mount(CardReader, null);

        M.mount(Scanner, {view: surfaceView.bind(scanner)});
        M.mount(Workspace, {view: surfaceView.bind(workspace)});
    }

    function surfaceView(surface : Array<DragDropItem>) return surface.map(function(item) {
        return switch Type.getClass(item) {
            case Data.Card: 
                m('img#card[src=/images/card.svg]');
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

    function bookshelfView() return bookshelf.map(function(item)
        return switch Type.getClass(item) {
            case Data.Book:
                m('.book.cover', item.title);
            case Data.Bluray:
                m('.bluray.cover', item.title);
            case unknown:
                m('div', {style:"color:red"}, 'View not found for: ' + Type.getClassName(unknown));
        }
    );
}

enum ScreenState {
    Welcome;
    EnterPin;
    DisplayBorrowedItems(items : Array<Data.LoanItem>);
    ThankYou;
    InvalidPin;
    AlreadyBorrowed;
    RemoveCard;
}

class ScreenView implements Mithril
{
    var state : ScreenState = Welcome;
    var pinBuffer : Array<Int> = [];

    public function new() {}

    public function view() {
        return switch state {
            case Welcome: welcome();
            case EnterPin: enterPin();
            case _: 
                m('.content', {style: "color:red"}, 'View not found: $state');
        }
    }

    function welcome() m('.content', [
        m('p', 'Welcome to the library borrowing machine!'),
        m('p', 'Insert your card into the reader to get started.')
    ]);

    function enterPin() [
        m('.content', m('p', 'Enter your 4-digit PIN.')),
        m('.content', m('p', 
            if(pinBuffer.length == 0) M.trust("&nbsp;") 
            else "".rpad("*", pinBuffer.length)
        )),
        m('.content.keypad', 
            ['1','2','3','4','5','6','7','8','9','0'].map.fn(key => m('.key', {
                onclick: keyClicked.bind(Std.parseInt(key))
            }, key))
        )
    ];

    function keyClicked(key : Int) {
        trace("Pressed " + key);
        pinBuffer.push(key);
    }
}