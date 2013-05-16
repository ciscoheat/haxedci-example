package dci.examples;
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

class Main 
{
	static var neoAccount : Account;
	static var bills : Array<Creditor>;
		
	static function main() 
	{
		setupAccountsAndBills();
		setupConsoleCommunication();
		
		var totalToPay = Lambda.fold(bills, function(cr, a) { return cr.amountOwed + a; }, 0.0);
				
		type("Hello Neo...", 1000)
		.then(type.bind("It's time to pay your bills, Neo.", 500))
		.then(newline)
		.then(newline)
		.then(type.bind("Current account balance: " + neoAccount.balance()))
		.then(type.bind('1 - Pay bills ($totalToPay)'))
		.then(newline);
	}

	static function testinput(i : String)
	{
		switch(i)
		{
			case '':
			case '1':
				try 
				{
					new PayBills(neoAccount, bills).pay();			
					type("Account balance after paying bills: " + neoAccount.balance());
				}
				catch (e : String)
				{
					type(e);
				}				
			case _:
				type("Try again, Neo.");
		}			
	}
	
	static function setupConsoleCommunication()
	{
		var input = new JQuery("#input");

		input.focus().keyup(function(e) {
			if (e.which == 13) 
			{
				var i = new JQuery(e.target).val();
				new JQuery(e.target).val("");
				testinput(i);
			}
		});		

		new JQuery("#screen").on('click', input.focus);		
	}
	
	static function setupAccountsAndBills()
	{
		var ledger = new Ledger();
		ledger.message = "Initial balance";
		ledger.amount = 2000;
		
		var ledgers = new Array<Ledger>();
		ledgers.push(ledger);
		
		neoAccount = new Account(ledgers);
		
		var foodBill = new Creditor();
		foodBill.account = new Account(new Array<Ledger>());
		foodBill.amountOwed = 300;
		foodBill.name = "Food bill";
		
		bills = [foodBill];		
	}

	static function type(txt : String, delay = 0)
	{
		var p = new Deferred();
		typeString(txt).then(function() { Timer.delay(function() { p.resolve(); }, delay); } );
		return p.promise();
	}
	
	static function newline(delay = 0) : Promise
	{
		return type("", delay);
	}
	
	static function typeString(txt : String) : Promise
	{
		var el = new JQuery("#content");
		var lines = el.find('div').length;
		
		if (lines > 22)
			el.find('div:first').remove();
		
		var timeOut;
		var txtLen = txt.length;
		var char = 0;
		var typeIt = null;
		
		var def : Deferred = new Deferred();
		
		el = new JQuery("<div />").appendTo(el);
		
		if (txt.length == 0) 
		{
			el.html("&nbsp;");
			return def.resolve().promise();
		}
		
		(typeIt = function() 
		{
			var humanize = Math.round(Math.random() * (50 - 30)) + 30;
			timeOut = Timer.delay(function() 
			{
				var type = txt.substr(char++, 1);
				var currentText = el.text().substr(0, el.text().length - 1);
				
				el.text(currentText + type + '|');

				if (char == txtLen) 
				{
					el.text(currentText + type);
					def.resolve();
				}
				else
				{
					typeIt();
				}

			}, humanize);
		})();
		
		return def.promise();
	}
}
