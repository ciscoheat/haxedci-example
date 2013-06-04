package dci.examples;
import dci.examples.contexts.Console;
import dci.examples.moneytransfer.contexts.Account;
import dci.examples.moneytransfer.contexts.MoneyTransfer;
import dci.examples.moneytransfer.contexts.PayBills;
import dci.examples.moneytransfer.data.Creditor;
import dci.examples.moneytransfer.data.Ledger;
import haxe.Timer;
import jQuery.Callbacks;
import jQuery.Deferred;
import jQuery.JQuery;
import jQuery.JQueryStatic;
import jQuery.Promise;
import js.Lib;

class Main 
{
	static var neoAccount : Account;
	static var bills : Array<Creditor>;
	
	static var console : Console;
	
	static function main() 
	{
		new JQuery(initializeMatrix);
		//new JQuery(visitRestaurant);
	}

	static function setupConsole(testInput : String -> Void)
	{
		console = new Console(new JQuery("#content"), new JQuery("#input"), testInput);
	}
	
	static function visitRestaurant()
	{
		
	}
	
	static function initializeMatrix()
	{
		setupConsole(testMatrixInput);
		setupAccountsAndBills();
		
		var totalToPay = Lambda.fold(bills, function(cr, a) { return cr.amountOwed + a; }, 0.0);
		var type = console.output;
		var newline = console.newline;
				
		type("Hello Neo...", 1000)
		.then(type.bind("It's time to pay your bills, Neo.", 500))
		.then(newline)
		.then(newline)
		.then(type.bind("Current account balance: " + neoAccount.balance()))
		.then(type.bind('1 - Pay bills ($totalToPay)'))
		.then(newline);
	}

	static function testMatrixInput(i : String)
	{
		switch(i.toLowerCase())
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
			case 'dir':
				console.output("Maybe in the next version of Matrix.");
			case _:
				console.output("Try again, Neo.");
		}
	}
	
	static function setupAccountsAndBills()
	{
		var ledger = new Ledger();
		ledger.message = "Initial balance";
		ledger.amount = 1000;
		
		var ledgers = new Array<Ledger>();
		ledgers.push(ledger);
		
		neoAccount = new Account(ledgers);
		
		var foodBill = new Creditor();
		foodBill.account = new Account(new Array<Ledger>());
		foodBill.amountOwed = 300;
		foodBill.name = "Food bill";
		
		bills = [foodBill];		
	}
}
