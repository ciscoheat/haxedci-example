package dci.examples;
import dci.examples.contexts.Console;
import dci.examples.contexts.Matrix;
import dci.examples.moneytransfer.contexts.Account;
import dci.examples.moneytransfer.data.Creditor;
import dci.examples.moneytransfer.data.Ledger;
import jQuery.JQuery;

class Main 
{
	static function main() 
	{
		// Start when jQuery is ready.
		new JQuery(initializeMatrix);
	}
	
	static function initializeMatrix()
	{		
		// Create an Account with initial balance of $1000
		var ledger = new Ledger();
		ledger.message = "Initial balance";
		ledger.amount = 1000;
		
		var neoAccount = new Account([ledger]);
		
		// Create bills that must be payed.
		var foodBill = new Creditor();
		foodBill.account = new Account([]);
		foodBill.amountOwed = 300;
		foodBill.name = "Food bill";
		
		var bills = [foodBill];
		
		// Create a new console and start a "Matrix" process on it.
		var console = new Console(new JQuery("#content"), new JQuery("#input"));
		console.start(new Matrix(console, bills, neoAccount));
	}	
}
