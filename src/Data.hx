import DragDrop.DragDropItem;

/**
 *  Used as a in-memory database for library items and cards.
 *  The Main class is used to set up the data, hence the "allow" access
 *  control for Main.
 */
@:allow(Main) class Data 
{
    public static var libraryItems(default, null) : Array<LoanItem>;
    public static var libraryCards(default, null) : Array<Card>;
    public static var libraryLoans(default, null) : Array<LibraryLoan>;
}

///// Interfaces (artefacts that makes sense to the user) /////

interface RfidItem
{
    public var rfid(default, set) : String;
}

interface LoanItem extends DragDropItem extends RfidItem
{
    public var title(default, set) : String;
    public var loanTimeDays(default, set) : Int;
}

///// LoanItem implementations /////

class Book implements HaxeContracts implements DataClass implements LoanItem
{
    @validate(_.length > 0) public var rfid : String;
    @validate(_.length > 0) public var title : String;
    @validate(_ > 0) public var loanTimeDays : Int;
}

class Bluray implements HaxeContracts implements DataClass implements LoanItem
{
    @validate(_.length > 0) public var rfid : String;
    @validate(_.length > 0) public var title : String;
    @validate(_ > 0) public var length : Int;
    @validate(_ > 0) public var loanTimeDays : Int;
}

///// Other data /////

class Card implements HaxeContracts implements DataClass implements DragDropItem implements RfidItem
{
    @validate(_.length > 0) public var rfid : String;
    @validate(_.length > 0) public var name : String;
    @validate(~/\d{4}/) public var pin : String;
}

class LibraryLoan implements HaxeContracts implements DataClass
{
    @validate(_.length > 0) public var loanItemRfid : String;
    @validate(_.length > 0) public var borrowerRfid : String;
    public var created : Date;
    public var returnDate : Date;
}

// This is to simplify the example, to avoid adding data references in ScreenView for example.
typedef ScannedItem = {
    item: LoanItem,
    returnDate: Date
}
