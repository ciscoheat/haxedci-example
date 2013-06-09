package dci.examples;
import dci.examples.contexts.Console;
import dci.examples.contexts.Matrix;
import dci.examples.moneytransfer.contexts.Account;
import dci.examples.moneytransfer.data.Creditor;
import dci.examples.moneytransfer.data.Ledger;
import jQuery.JQuery;

class Main 
{
	static var neoAccount : Account;
	static var bills : Array<Creditor>;
	
	static var console : Console;
	
	static function main() 
	{
		new JQuery(initializeMatrix);
	}

	static function visitRestaurant()
	{
		
	}
	
	static function initializeMatrix()
	{		
		setupAccountsAndBills();
		
		console = new Console(new JQuery("#content"), new JQuery("#input"));
		console.start(new Matrix(console, bills, neoAccount));
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
