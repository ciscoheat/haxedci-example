package contexts;
import data.Ledger;

@:build(Dci.context())
class Account
{
	// Roles
	@role var ledgers : Ledgers;
	
	public function new(ledgers : Array<Ledger>)
	{
		this.ledgers = new Ledgers(ledgers);
	}	
	
	public function Balance()
	{
		return ledgers.Balance();
	}
	
	public function Deposit(amount : Float)
	{
		ledgers.AddEntry("Depositing", amount);
	}
	
	public function Withdraw(amount : Float)
	{
		ledgers.AddEntry("Withdrawing", -amount);
	}	
}

@:build(Dci.role(Account))
@:arrayAccess private abstract Ledgers(Array<Ledger>)
{
	public inline function new(ledgers : Array<Ledger>)
	{
		this = ledgers;
	}
	
	// Required for iteration of an abstract type:
	public var length(get, never) : Int;
	function get_length() return this.length;
	
	public function Balance()
	{
		return Lambda.fold(this, function(a, b) { return a.Amount + b; }, 0.0); 
	}
	
	public function AddEntry(message, amount)
	{		
		var ledger = new Ledger();
		ledger.Message = message;
		ledger.Amount = amount;
		
		this.push(ledger);
	}
}