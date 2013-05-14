package ;
import contexts.Account;
import contexts.MoneyTransfer;
import data.Ledger;

/**
 * ...
 * @author Andreas
 */

class Main 
{
	static function main() 
	{
		var ledger = new Ledger();
		ledger.Message = "Initial balance";
		ledger.Amount = 2000;
		
		var ledgers = new Array<Ledger>();
		ledgers.push(ledger);
		
		var source = new Account(ledgers);
		var destination = new Account(new Array<Ledger>());
		
		var transfer = new MoneyTransfer(source, destination, 500);
		
		transfer.Execute();
		
		trace("Source balance: " + source.Balance());
		trace("Destination balance: " + destination.Balance());
	}
}
