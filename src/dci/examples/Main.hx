package dci.examples;
import dci.examples.moneytransfer.contexts.Account;
import dci.examples.moneytransfer.contexts.MoneyTransfer;
import dci.examples.moneytransfer.contexts.PayBills;
import dci.examples.moneytransfer.data.Creditor;
import dci.examples.moneytransfer.data.Ledger;

class Main 
{
	static function main() 
	{
		var ledger = new Ledger();
		ledger.message = "Initial balance";
		ledger.amount = 2000;
		
		var ledgers = new Array<Ledger>();
		ledgers.push(ledger);
		
		var myAccount = new Account(ledgers);		
		
		var foodBill = new Creditor();
		foodBill.account = new Account(new Array<Ledger>());
		foodBill.amountOwed = 300;
		foodBill.name = "Food bill";
		
		trace("Source balance: $" + myAccount.balance());
		
		new PayBills(myAccount, [foodBill]).pay();
						
		trace("Source balance after paying bills: $" + myAccount.balance());
	}
}
