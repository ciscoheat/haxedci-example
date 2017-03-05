package views;

import mithril.M;

using DateTools;

enum ScreenState {
    Welcome;
    EnterPin(data : {previousAttemptFailed : Bool});
    DisplayBorrowedItems(items : Iterable<Data.LoanItem>);
    ThankYou;
    InvalidPin;
    AlreadyBorrowed;
    RemoveCard;
}

class ScreenView implements Mithril
{
    public var state(default, set) : ScreenState = Welcome;

    function set_state(s : ScreenState) : ScreenState {
        state = s;
        M.redraw();
        return state;
    }

    var pinBuffer : String = "";
    var onPinCodeEntered : Null<String -> Void>;

    public function new() {}

    public function registerSinglePinCodeEntered(callback : String -> Void) {
        onPinCodeEntered = callback;
    }

    public function view() {
        return switch state {
            case Welcome: 
                welcome();
            case EnterPin(data): 
                enterPin(data.previousAttemptFailed);
            case InvalidPin:
                invalidPin();
            case DisplayBorrowedItems(items):
                displayBorrowedItems(items);
            case ThankYou:
                thankYou();
            case _: 
                m('.content.red', 'View not found: $state');
        }
    }

    ///////////////////////////////////////////////////////

    function welcome() m('.content', [
        m('p', 'Welcome to the library borrowing machine!'),
        m('p', 'Insert your card into the reader to get started.')
    ]);

    ///////////////////////////////////////////////////////

    function enterPin(previousAttemptFailed : Bool) [
        m('.content', 
            if(previousAttemptFailed) m('.red', 'Incorrect PIN. Enter your 4-digit PIN.')
            else m('p', 'Enter your 4-digit PIN.')
        ),
        m('.content', m('p', 
            if(pinBuffer.length == 0) M.trust("&nbsp;") 
            else "".rpad("*", pinBuffer.length)
        )),
        m('.content.keypad', 
            ['1','2','3','4','5','6','7','8','9','0'].map.fn(key => m('.key', {
                onclick: enterPinKeyPressed.bind(key)
            }, key))
        )
    ];

    function enterPinKeyPressed(key : String) {
        pinBuffer += key;
        if(pinBuffer.length < 4) return;

        var pin = pinBuffer;
        pinBuffer = "";
        if(onPinCodeEntered != null) {
            var callback = onPinCodeEntered;
            onPinCodeEntered = null;        
            callback(pin);
        }
    }

    ///////////////////////////////////////////////////////

    function invalidPin() m('.content', [
        m('.red', 'Incorrect PIN 3 times.'),
        m('p', 'Please remove your card before trying again.')
    ]);

    ///////////////////////////////////////////////////////

    function displayBorrowedItems(items : Iterable<Data.LoanItem>) {
        m('.content', [
            m('p', 'Scan the items you want to borrow on the dark red area.'),
            m('p', [
                m('button.-success', {style:"margin-right:2px"}, 'Finish with receipt'),
                m('button.-success', 'Finish without receipt'),
            ]),
            m('table', [ 
                m('thead', 
                    m('tr',
                        [m('th', 'Title'), m('th', 'Return date')]
                    )
                ),
                m('tbody', [for(item in items) {
                    var returnDate = Date.now().delta(item.loanTimeDays * 24 * 60 * 60 * 1000);
                    m('tr',
                        [m('td', item.title), m('td', returnDate.format("%Y-%m-%d"))]
                    );
                }])
            ])
        ]);
    }

    ///////////////////////////////////////////////////////

    function thankYou() m('.content',
        m('p', 'Thank you for using the automatic borrowing service!')
    );
}