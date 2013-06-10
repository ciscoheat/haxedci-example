package dci.examples.contexts;
import dci.examples.moneytransfer.contexts.Account;
import dci.examples.moneytransfer.contexts.PayBills;
import dci.examples.moneytransfer.data.Creditor;
import dci.examples.restaurant.contexts.Restaurant;
import jQuery.Deferred;
import jQuery.Promise;

class Matrix implements dci.Context 
{
	@role var console : Console;
	@role var bills : Array<Creditor>;
	@role var neoAccount : Account;
	@role var process : Deferred;

	public function new(console : Console, bills : Array<Creditor>, neoAccount : Account)
	{
		this.console = console;
		this.bills = bills;
		this.neoAccount = neoAccount;
	}

	public function start() : Deferred
	{
		process = new Deferred();
		
		var type = this.console.output;
		var newline = this.console.newline;

		type("Hello Neo...", 1000)
		.then(type.bind("It's time to pay your bills, Neo.", 500))
		.then(newline)
		.then(newline)
		.then(menu)
		.then(newline)
		.then(process.notify);
		
		return process;
	}
	
	function menu() : Deferred
	{
		var totalToPay = Lambda.fold(bills, function(cr, a) { return cr.amountOwed + a; }, 0.0);
		var type = this.console.output;
		var def = new Deferred();
		
		type("Current account balance: " + neoAccount.balance())
		.then(type.bind('1 - Pay bills ($totalToPay)'))
		.then(type.bind('2 - Order some food'))
		.then(def.resolve);
		
		return def;
	}
	
	public function input(msg : String) : Promise
	{
		trace(msg);
		
		var def = new Deferred();
		
		switch(msg.toLowerCase())
		{
			case '':
			case '1':
				try 
				{
					new PayBills(neoAccount, bills).payBills();
					console.output("Account balance after paying bills: " + neoAccount.balance());
				}
				catch (e : String)
				{
					console.output(e);
				}
			case '2':				
				return console.start(new Restaurant(console, neoAccount)).then(menu);
			case 'dir':
				console.output("Maybe in the next version of Matrix.");
			case 'exit':
				console.output("Goodbye, Neo.");
				process.resolve();
			case _:
				console.output("Try again, Neo.");
		}
		
		return def.resolve();
	}
}