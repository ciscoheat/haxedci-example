import DragDrop.DragDropItem;

interface Data {}

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

///// Other items /////

class Card implements HaxeContracts implements DataClass implements DragDropItem implements RfidItem
{
    @validate(_.length > 0) public var rfid : String;
    @validate(_.length > 0) public var name : String;
    @validate(~/\d{4}/) public var pin : String;
}
