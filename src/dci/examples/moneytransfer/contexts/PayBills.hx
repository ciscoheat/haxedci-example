package dci.examples.moneytransfer.contexts;
import haxedci.Context;
import dci.examples.moneytransfer.data.Creditor;

class PayBills implements Context
{
	@role var account : {
		function withdraw(amount : Float) : Void;
		function balance() : Float;
	} =
	{
		function payBills() : Void
		{
			var surplus = self.balance() - creditors.owed();

			// If not enough money, don't pay any bills.
			if (surplus < 0)
			{
				throw 'Not enough money to pay all bills, ${Math.abs(surplus)} more is needed.';
			}

			for (creditor in creditors)
			{
				new MoneyTransfer(self, creditor.account, creditor.amountOwed).transfer();
			}
		}
	}

	@role var creditors : Iterable<Creditor> =
	{
		function owed() : Float	return Lambda.fold(self,
			function(cr, a) { return cr.amountOwed + a; }, 0.0
		);
	}

	public function new(account, creditors)
	{
		bindRoles(account, creditors);
	}

	function bindRoles(account, creditors)
	{
		this.account = account;
		this.creditors = creditors;
	}

	public function payBills()
	{
		account.payBills();
	}
}
