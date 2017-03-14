package views;

import mithril.M;
import haxecontracts.*;
import haxe.Timer;

using DateTools;

enum ScreenState {
    Welcome;
    EnterPin(data : {previousAttemptFailed : Bool});
    DisplayBorrowedItems(items : Iterable<Data.LoanItem>);
    ThankYou;
    TooManyInvalidPin;
    RemoveCard;
    InvalidCard;
    InvalidLoanItem;
    ItemAlreadyBorrowed;
}

class ScreenView implements HaxeContracts implements Mithril
{
    var pinBuffer : String = "";
    var messageTimer : Timer;

    var _onPinCodeEntered : Null<String -> Void>;
    var currentState : ScreenState;

    public function display(state : ScreenState) {
        Contract.requires(state != null);
        if(messageTimer != null) messageTimer.stop();
        currentState = state;
        M.redraw();
        //trace('ScreenState change: $state');
    }

    public function displayMessage(state : ScreenState, waitMs : Int, ?thenDisplay : ScreenState) {
        if(thenDisplay == null) thenDisplay = currentState;

        display(state);

        messageTimer = new Timer(waitMs);
        messageTimer.run = display.bind(thenDisplay);
    }

    public function new(initialState)
        display(initialState);

    public function onPinCodeEntered(callback : String -> Void) {
        _onPinCodeEntered = callback;
    }

    public function view() {
        return switch currentState {
            case Welcome: 
                welcome();
            case EnterPin(data): 
                enterPin(data.previousAttemptFailed);
            case TooManyInvalidPin:
                tooManyInvalidPin();
            case DisplayBorrowedItems(items):
                displayBorrowedItems(items);
            case ThankYou:
                thankYou();
            case InvalidCard:
                invalidCard();
            case InvalidLoanItem:
                invalidLoanItem();
            case ItemAlreadyBorrowed:
                itemAlreadyBorrowed();
            case _: 
                m('.content.red', 'View not found: $currentState');
        }
    }

    ///////////////////////////////////////////////////////

    function welcome() m('.content', [
        m('p', 'Welcome to the library borrowing machine!'),
        m('p', m('strong', 'Please insert your card into the reader.'))
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
        if(_onPinCodeEntered != null) {
            var callback = _onPinCodeEntered;
            _onPinCodeEntered = null;        
            callback(pin);
        }
    }

    ///////////////////////////////////////////////////////

    function tooManyInvalidPin() m('.content', [
        m('.red', 'Incorrect PIN too many times.'),
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

    function invalidCard() m('.content', [
        m('.red', 'Library card not valid.'),
        m('p', 'Please contact support.')
    ]);

    ///////////////////////////////////////////////////////

    function thankYou() m('.content',
        m('p', 'Thank you for using the automatic borrowing service!')
    );

    ///////////////////////////////////////////////////////

    function invalidLoanItem() m('.content', [
        m('.red', 'Loan item not valid.'),
        m('p', 'Please contact support.')
    ]);

    ///////////////////////////////////////////////////////

    function itemAlreadyBorrowed() m('.content', [
        m('.red', 'Loan item already borrowed.'),
        m('p', 'Please contact support.')
    ]);
}