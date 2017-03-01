package views;
import mithril.M;
import HtmlElements;

/**
 *  Uses the HTML in index.html to display all items
 */
class MainView implements Mithril implements Context
{
    var bookshelf : Array<Data.Book>;
    var screen : ScreenView;
    var cardReader : CardReader;

    public function new(bookshelf, cardReader) {
        this.bookshelf = bookshelf;
        this.screen = new ScreenView();
    }

    public function mount() {


        // Using the abstract HtmlElements class to refer directly to
        // the HTML element with an enum value:
		M.mount(Bookshelf, {view: function() 
            return bookshelf.map(function(book) 
			    m('.book', book.title)
            )
        });

        M.mount(Printer, {view: function()
            m('.box', 
                m('.slot')
            )
        });

        M.mount(Screen, screen);

        M.mount(CardReader, null);
    }
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