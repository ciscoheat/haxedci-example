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
    public var loanTime(default, set) : Int;
}

///// LoanItem implementations /////

class Book implements HaxeContracts implements DataClass implements LoanItem
{
    public var rfid : String;
    public var title : String;
    public var loanTime : Int;
}

class Bluray implements HaxeContracts implements DataClass implements LoanItem
{
    public var rfid : String;
    public var title : String;
    public var length : Int;
    public var loanTime : Int;
}

///// Other items /////

class Card implements HaxeContracts implements DataClass implements DragDropItem// implements RfidItem
{
    public var rfid : String;
    public var name : String;
}
