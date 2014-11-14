package dci.examples.matrix;
import dci.examples.moneytransfer.contexts.Account;
import dci.examples.moneytransfer.contexts.PayBills;
import dci.examples.moneytransfer.data.Creditor;
import dci.examples.restaurant.contexts.Restaurant;
import jQuery.Deferred;
import jQuery.Promise;

/**
 * "Matrix" is a little game that is supposed to be played in a Console.
 * You are Neo and must pay some bills, or spend the money on food instead.
 */
class Matrix implements haxedci.Context
{
	var process : Deferred;

	public function new(console : Console, bills : Array<Creditor>, neoAccount : Account)
	{
		this.console = console;
		this.bills = bills;
		this.neoAccount = neoAccount;
		this.process = new Deferred();
	}

	///// System Operations /////

	public function start() : Deferred
	{
		var effect = new MatrixEffect(console).start();

		var type = this.console.output;
		var newline = this.console.newline;

		var i = 13;
		while(--i > 0) newline();

		type("PRESS ANY KEY", 0, 245);

		console.getInput().one('keydown', function(e) {
			e.preventDefault();

			effect.clear();
			console.clear();

			type("Hello Neo...", 1250)
			.then(type.bind("It's time to pay your bills, Neo.", 500))
			.then(newline)
			.then(newline)
			.then(menu)
			.then(newline)
			.then(process.notify);
		});

		return process;
	}

	function menu() : Promise
	{
		var totalToPay = Lambda.fold(bills, function(cr, a) return cr.amountOwed + a, 0.0);
		var type = this.console.output;

		return type("Current account balance: " + neoAccount.balance())
		.then(type.bind('1 - Pay bills ($totalToPay)'))
		.then(type.bind('2 - Order some food'));
	}

	public function input(msg : String) : Promise
	{
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
				return console.load(new Restaurant(console, neoAccount)).then(menu);
			case 'dir', 'ls', 'ls -l':
				console.hackingDetected();
			case 'exit':
				console.exit().then(process.resolve);
			case _:
				console.unknownCommand();
		}

		return new Deferred().resolve();
	}

	///// Roles /////

	@role var console : Console =
	{
		function hackingDetected() : Promise
		{
			return
			self.output("Tell me, Mr. Anderson, what good is a directory listing if you're unable to...", 200)
			.then(self.output.bind("see?"))
			.then(self.turnOff);
		}

		function exit() : Promise
		{
			return self.output("Goodbye, Neo.").then(self.turnOff);
		}

		function unknownCommand() : Promise
		{
			return self.output("Try again, Neo.");
		}
	}

	@role var bills : Array<Creditor>;
	@role var neoAccount : Account;
}
