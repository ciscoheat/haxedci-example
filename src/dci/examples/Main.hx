package dci.examples;
import dci.examples.matrix.Console;
import dci.examples.matrix.Matrix;
import dci.examples.moneytransfer.contexts.Account;
import dci.examples.moneytransfer.data.Creditor;
import dci.examples.moneytransfer.data.Ledger;
import jQuery.JQuery;

/*
 * DCI stands for Data, Context, Interaction. 
 * 
 * Brief: A Context rounds up Data objects that take on the part as Roles,
 * then an Interaction takes place as a flow of messages through the Roles. 
 * The Roles define a network of communicating objects and the Role methods 
 * force the objects to collaborate according to the distributed interaction 
 * algorithm.
 * 
 * Detailed information, tutorials and more at http://fulloo.info/
 */

class Main 
{
	static function main() 
	{
		// Start when jQuery is ready.
		new JQuery(initializeMatrix);
	}
	
	static function initializeMatrix()
	{
		// Create some Data objects.
		 
		// Create an Account with initial balance of $1000
		var ledger = new Ledger();
		ledger.message = "Initial balance";
		ledger.amount = 1000;
		
		var neoAccount = new Account([ledger]);
		
		// Create bills that must be payed using a Creditor object.
		var foodBill = new Creditor();
		foodBill.account = new Account([]);
		foodBill.amountOwed = 300;
		foodBill.name = "Food bill";
		
		var bills = [foodBill];
		
		// A Console is a Context for basic I/O. 
		// It needs a html element for output, and a text field for input.
		// Create a Console and start the "Matrix" process.
		var console = new Console(new JQuery("#content"), new JQuery("#input"));
		
		console.start(new Matrix(console, bills, neoAccount));
	}	
}
