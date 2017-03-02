import DragDrop.DragDropItem;

interface Data {}

class Card implements HaxeContracts implements DataClass implements DragDropItem
{
    public var rfid : String;
    public var name : String;
}

interface LoanItem extends DragDropItem
{
    public var rfid(default, set) : String;
    public var title(default, set) : String;
    public var loanTime(default, set) : Int;
}

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
