package views;

import mithril.M;
import haxe.Timer;
import Data.ScannedItem;

enum ScreenState {
    Welcome;
    EnterPin(data : {previousAttemptFailed : Bool});
    DisplayBorrowedItems(scannedItems : Iterable<ScannedItem>);
    ThankYou;
    TooManyInvalidPin;
    InvalidCard;
    InvalidLoanItem;
    ItemAlreadyBorrowed;
    DontForgetLibraryCard;
}

/**
 *  View for the computer screen on the library borrowing machine.
 *  
 *  It also contains events for entering PIN code and clicking the
 *  "finished" buttons, because it's a touch screen.
 */
class ScreenView implements HaxeContracts implements Mithril
{
    var currentState : ScreenState = Welcome;
    var messageTimer : Timer = new Timer(1000);
    var pinBuffer : String = "";

    var _onPinCodeEntered = new SingleEventHandler<String -> Void>();
    var _onFinishWithoutReceiptClicked = new SingleEventHandler<Void -> Void>();
    var _onFinishWithReceiptClicked = new SingleEventHandler<Void -> Void>();

    ///////////////////////////////////////////////////////////////////////////

    public function new() {}

    public function display(state : ScreenState) {
        // If state is switched, stop current message display,
        // which could revert the current state otherwise.
        messageTimer.stop();
        currentState = state;
        M.redraw();
    }

    public function displayMessage(state : ScreenState, waitMs : Int, ?thenDisplay : ScreenState) {
        Contract.requires(waitMs > 0);
        if(thenDisplay == null) thenDisplay = currentState;

        display(state);

        messageTimer = new Timer(waitMs);
        messageTimer.run = display.bind(thenDisplay);
    }

    ///// Events /////

    public function onPinCodeEntered(callback : String -> Void, ?pos : haxe.PosInfos) : Void {
        Contract.requires(callback != null);
        _onPinCodeEntered.set(callback, pos);
    }

    public function onFinishWithoutReceiptClicked(callback : Void -> Void, ?pos : haxe.PosInfos) : Void {
        Contract.requires(callback != null);
        _onFinishWithoutReceiptClicked.set(callback, pos);
    }

    public function onFinishWithReceiptClicked(callback : Void -> Void, ?pos : haxe.PosInfos) : Void {
        Contract.requires(callback != null);
        _onFinishWithReceiptClicked.set(callback, pos);
    }

    ///// Contract invariants /////

    @invariants function inv() {
        Contract.invariant(currentState != null);
        Contract.invariant(pinBuffer != null);
        Contract.invariant(messageTimer != null);
    }    

    ///// View templates /////

    public function view() {
        return switch currentState {
            case Welcome: 
                welcome();
            case EnterPin(data): 
                enterPin(data.previousAttemptFailed);
            case TooManyInvalidPin:
                tooManyInvalidPin();
            case DisplayBorrowedItems(scannedItems):
                displayBorrowedItems(scannedItems);
            case ThankYou:
                thankYou();
            case InvalidCard:
                invalidCard();
            case InvalidLoanItem:
                invalidLoanItem();
            case ItemAlreadyBorrowed:
                itemAlreadyBorrowed();
            case DontForgetLibraryCard:
                dontForgetLibraryCard();
        }
    }

    ///////////////////////////////////////////////////////

    function welcome() m('.content', [
        m('p', 'Welcome to the library borrowing machine!'),
        m('p', m('strong', 'Please drag your card to the reader.')),
        m('p', 'Books are available on the top shelf.')
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
            ['1','2','3','4','5','6','7','8','9','0'].map(function(key) m('.key', {
                onclick: enterPinKeyPressed.bind(key)
            }, key))
        )
    ];

    function enterPinKeyPressed(key : String) {
        pinBuffer += key;
        if(pinBuffer.length < 4) return;

        var pin = pinBuffer;
        pinBuffer = "";
        _onPinCodeEntered.trigger(pin);
    }

    ///////////////////////////////////////////////////////

    function tooManyInvalidPin() m('.content', [
        m('.red', 'Incorrect PIN too many times.'),
        m('p', 'Please remove your card before trying again.')
    ]);

    ///////////////////////////////////////////////////////

    function displayBorrowedItems(scannedItems : Iterable<ScannedItem>) {
        Contract.requires(scannedItems != null);
        m('.content', [
            m('p', 'Scan the items you want to borrow on the dark red area.'),
            m('p', [
                m('button.-success', {
                    style:"margin-right:2px",
                    onclick: function() _onFinishWithReceiptClicked.trigger()
                }, 'Finish with receipt'),
                m('button.-success', {
                    onclick: function() _onFinishWithoutReceiptClicked.trigger()
                }, 'Finish without receipt')
            ]),
            m('table', [ 
                m('thead', 
                    m('tr',
                        [m('th', 'Title'), m('th', 'Return date')]
                    )
                ),
                m('tbody', [for(scanned in scannedItems) {
                    m('tr',
                        [m('td', scanned.item.title), m('td', scanned.returnDate.format("%Y-%m-%d"))]
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

    function thankYou() m('.content', [
        m('p', 'Thank you for using the automatic borrowing service!'),
    ]);

    ///////////////////////////////////////////////////////

    function dontForgetLibraryCard() m('.content', [
        m('p', m('strong', "Don't forget your library card!"))
    ]);

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