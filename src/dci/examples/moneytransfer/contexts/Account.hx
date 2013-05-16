package dci.examples.moneytransfer.contexts;
import dci.examples.moneytransfer.data.Ledger;

typedef ILedgers = Array<Ledger>;

@:build(Dci.context())
class Account
{
	@role var ledgers : Ledgers;
	
	public function new(ledgers : ILedgers)
	{
		this.ledgers = new Ledgers(ledgers);
	}	
	
	public function balance() : Float
	{
		return ledgers.balance();
	}
	
	public function deposit(amount : Float)
	{
		ledgers.addEntry("Depositing", amount);
	}
	
	public function withdraw(amount : Float)
	{
		ledgers.addEntry("Withdrawing", -amount);
	}	
}

@:build(Dci.role(Account))
@:arrayAccess private abstract Ledgers(ILedgers)
{
	// Required for iteration of an abstract type:
	public var length(get, never) : Int;
	function get_length() return this.length;
	
	public function balance()
	{
		return Lambda.fold(this, function(a, b) { return a.amount + b; }, 0.0); 
	}
	
	public function addEntry(message, amount)
	{		
		var ledger = new Ledger();
		ledger.message = message;
		ledger.amount = amount;
		
		this.push(ledger);
	}
}