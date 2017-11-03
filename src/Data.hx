import contexts.DragDropMechanics.DragDropItem;

/**
 *  Used as a in-memory database for library items, cards and loans.
 *  The Main class is used to set up the data, hence the "allow" access control for Main.
 */
@:allow(Main) class Data 
{
    public static var libraryItems(default, null) : Array<LoanItem>;
    public static var libraryCards(default, null) : Array<LibraryCard>;
    public static var libraryLoans(default, null) : Array<LibraryLoan>;
}

///// Interfaces (artefacts that makes sense to the user in a context) /////

interface RfidItem
{
    var rfid(default, set) : String;
}

interface LoanItem extends RfidItem
{
    var title(default, set) : String;
    var loanTimeDays(default, set) : Int;
}

interface ScannedItem
{
    var item(default, null) : LoanItem;
    var returnDate(default, null) : Date;
}

///// Data classes (what the system is) /////

/**
 *  Some additional interfaces are used for the data classes:
 *  - HaxeContracts: Design by Contract library
 *  - DataClass: A convenient way of creating and ensuring integrity of data objects
 *  - DragDropItem: A marker interface for objects that can be drag-dropped
 */

class Book implements HaxeContracts implements DataClass implements DragDropItem 
implements LoanItem
{
    @validate(_.length > 0) public var rfid : String;
    @validate(_.length > 0) public var title : String;
    @validate(_ > 0) public var loanTimeDays : Int;
}

class Bluray implements HaxeContracts implements DataClass implements DragDropItem 
implements LoanItem
{
    @validate(_.length > 0) public var rfid : String;
    @validate(_.length > 0) public var title : String;
    @validate(_ > 0) public var length : Int;
    @validate(_ > 0) public var loanTimeDays : Int;
}

class LibraryCard implements HaxeContracts implements DataClass implements DragDropItem 
implements RfidItem
{
    @validate(_.length > 0) public var rfid : String;
    @validate(_.length > 0) public var name : String;
    @validate(~/^\d{4}$/) public var pin : String;
}

class LibraryLoan implements HaxeContracts implements DataClass
{
    @validate(_.length > 0) public var loanItemRfid : String;
    @validate(_.length > 0) public var borrowerRfid : String;
    public var created : Date;
    public var returnDate : Date;
}

class ReceiptItem implements HaxeContracts 
implements ScannedItem
{
    public var item(default, null) : LoanItem;
    public var returnDate(default, null) : Date;

    public function new(item, returnDate) {
        this.item = item;
        this.returnDate = returnDate;
    }

    @invariants function invariants() {
        Contract.invariant(this.item != null);
        Contract.invariant(this.returnDate != null);
    }
}
