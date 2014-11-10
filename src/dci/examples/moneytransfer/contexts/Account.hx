package dci.examples.moneytransfer.contexts;
import haxedci.Context;
import dci.examples.moneytransfer.data.Ledger;

class Account implements Context
{
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

	@role var ledgers : Array<Ledger> =
	{
		function balance() : Float
		{
			return Lambda.fold(self, function(a, b) { return a.amount + b; }, 0.0);
		}

		function addEntry(message : String, amount : Float) : Void
		{
			var ledger = new Ledger();
			ledger.message = message;
			ledger.amount = amount;

			self.push(ledger);
		}
	}
}
