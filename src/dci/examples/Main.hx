package dci.examples;
import dci.examples.matrix.Console;
import dci.examples.matrix.Matrix;
import dci.examples.moneytransfer.contexts.Account;
import dci.examples.moneytransfer.contexts.ValidateCreditCard;
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
		// Create an Account with initial balance of $1000
		var ledger = new Ledger();
		ledger.message = "Initial balance";
		ledger.amount = 1000;

		var neoAccount = new Account([ledger]);

		// Create bills that must be payed using a Creditor object.
		var foodBill = new Creditor();
		foodBill.account = new Account([]);
		foodBill.amountOwed = 300;
		foodBill.name = "Groceries";

		var bills = [foodBill];

		// The Console is a terminal emulator.
		// It needs a html element for output and a text field for input.
		var console = new Console(new JQuery("#content"), new JQuery("#input"));

		// A demonstration of a credit card validation Context.
		if (!new ValidateCreditCard(4916239259614484).isValid())
			console.output("Invalid credit card number!");

		// Start the "Matrix" process on the Console.
		console.start(new Matrix(console, bills, neoAccount));
	}
}
