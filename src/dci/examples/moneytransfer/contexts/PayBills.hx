package dci.examples.moneytransfer.contexts;
import dci.Context;
import dci.examples.moneytransfer.data.Creditor;

typedef ISource =
{
	function withdraw(amount : Float) : Void;
	function balance() : Float;
}

typedef ICreditors = Iterable<Creditor>

class PayBills implements Context
{
	@role var source : Source;
	@role var creditors : Creditors;
	
	public function new(source : ISource, creditors : ICreditors)
	{
		bindRoles(source, creditors);
	}
	
	function bindRoles(source, creditors)
	{
		this.source = new Source(source);
		this.creditors = new Creditors(creditors);
	}
	
	public function pay()
	{
		source.payBills();
	}
}

@:build(Dci.role(PayBills))
private abstract Creditors(ICreditors) from ICreditors to ICreditors
{
	public inline function new(creditors)
	{
		this = creditors;
	}
	
	function iterator()
	{
		return this.iterator();
	}	
}

@:build(Dci.role(PayBills))
private abstract Source(ISource) from ISource to ISource
{
	public inline function new(source)
	{
		this = source;
	}
	
	public function payBills()
	{
		var c : PayBills = context;
		
		// If not enough money, don't pay anything.
		var surplus = this.balance() - Lambda.fold(c.creditors, function(cr, a) { return cr.amountOwed + a; }, 0.0);
		
		if (surplus < 0)
		{
			throw 'Not enough money to pay all bills, $$${Math.abs(surplus)} more is needed.';
		}
		
		for (creditor in c.creditors)
		{
			new MoneyTransfer(this, creditor.account, creditor.amountOwed).Execute();
		}
	}
}