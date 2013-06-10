package dci.examples.moneytransfer.contexts;
import dci.Context;
import dci.examples.moneytransfer.data.Creditor;

typedef IAccount = {
	function withdraw(amount : Float) : Void;
	function balance() : Float;
}

typedef ICreditors = Iterable<Creditor>

class PayBills implements Context
{
	@role var account : Account;
	@role var creditors : Creditors;
	
	public function new(account : IAccount, creditors : ICreditors)
	{
		bindRoles(account, creditors);
	}
	
	function bindRoles(account, creditors)
	{
		this.account = new Account(account);
		this.creditors = new Creditors(creditors);
	}
		
	public function payBills()
	{
		account.payBills();
	}	
}

@:build(Dci.role(PayBills))
private abstract Creditors(ICreditors) from ICreditors to ICreditors
{
	function iterator()
	{
		return this.iterator();
	}
	
	public function owed() : Float
	{
		return Lambda.fold(this, function(cr, a) { return cr.amountOwed + a; }, 0.0);
	}
}

@:build(Dci.role(PayBills))
private abstract Account(IAccount) from IAccount to IAccount
{
	public function payBills()
	{
		var c : PayBills = context;
		
		var surplus = this.balance() - c.creditors.owed();
		
		// If not enough money, don't pay any bills.
		if (surplus < 0)
		{
			throw 'Not enough money to pay all bills, ${Math.abs(surplus)} more is needed.';
		}
		
		for (creditor in c.creditors)
		{
			new MoneyTransfer(this, creditor.account, creditor.amountOwed).execute();
		}
	}
}