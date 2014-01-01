package dci.examples.moneytransfer.contexts;
import dci.Context;
import dci.examples.moneytransfer.data.Ledger;

class Account implements Context
{
	@role var ledgers = 
	{
		var roleInterface : Array<Ledger>;
		
		function balance()
		{
			return Lambda.fold(self, function(a, b) { return a.amount + b; }, 0.0);
		}
		
		function addEntry(message, amount)
		{
			var ledger = new Ledger();
			ledger.message = message;
			ledger.amount = amount;
			
			self.push(ledger);
		}
	}
	
	public function new(ledgers)
	{
		this.ledgers = ledgers;
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
