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

///// Interfaces (artefacts that makes sense to a user in a context) /////

interface RfidItem
{
    final rfid : String;
}

interface LoanItem extends RfidItem
{
    final title : String;
    final loanTimeDays : Int;
}

interface ScannedItem
{
    var item(default, null) : LoanItem;
    var returnDate(default, null) : Date;
}

///// Data classes (what the system is) /////

/**
 *  Some additional interfaces are used for the data classes:
 * 
 *  - @:publicFields metadata - making all class fields public
 *  - HaxeContracts: Design by Contract library
 *  - DataClass: A convenient way of creating and ensuring integrity of data objects
 *  - DragDropItem: A marker interface for objects that can be drag-dropped
 *
 */
 @:publicFields
class Book implements HaxeContracts implements DataClass 
implements DragDropItem 
implements LoanItem
{
    @:validate(_.length > 0) final rfid : String;
    @:validate(_.length > 0) final title : String;
    @:validate(_ > 0) final loanTimeDays : Int;
}

@:publicFields
class Bluray implements HaxeContracts implements DataClass 
implements DragDropItem 
implements LoanItem
{
    @:validate(_.length > 0) final rfid : String;
    @:validate(_.length > 0) final title : String;
    @:validate(_ > 0) final length : Int;
    @:validate(_ > 0) final loanTimeDays : Int;
}

@:publicFields
class LibraryCard implements HaxeContracts implements DataClass 
implements DragDropItem 
implements RfidItem
{
    @:validate(_.length > 0) final rfid : String;
    @:validate(_.length > 0) final name : String;
    @:validate(~/^\d{4}$/) final pin : String;
}

@:publicFields
class LibraryLoan implements HaxeContracts implements DataClass
{
    @:validate(_.length > 0) final loanItemRfid : String;
    @:validate(_.length > 0) final borrowerRfid : String;
    final created : Date;
    final returnDate : Date;
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
