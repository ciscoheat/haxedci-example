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
	
	static function testinput(i : String)
	{
		if (i.length == 0) return;
		
		if (i != '1') 
		{
			type("Try again, Neo.");
			return;
		}
			
		try 
		{
			new PayBills(neoAccount, bills).pay();
			
			type("Account balance after paying bills: " + neoAccount.balance());
		}
		catch (e : String)
		{
			type(e);
		}			
	}
	
	static function main() 
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
		
		var total = Lambda.fold(bills, function(cr, a) { return cr.amountOwed + a; }, 0.0);
		
		type("Hello Neo...")
		.then(function() {
			var p = new Deferred();
			Timer.delay(function() { type("It's time to pay your bills, Neo.").then(p.resolve); }, 1000);
			return p;
		})
		.then(function() { return newline(); } )
		.then(function() { return newline(); } )
		.then(function() { return type("Current account balance: " + neoAccount.balance()); } )
		.then(function() { return type('1 - Pay bills ($total)'); } )
		.then(newline);
		
		new JQuery("#screen").on('click', function() {
			new JQuery("#input").focus();
		});
		
		new JQuery("#input").focus().keydown(function(e) {
			if (e.which == 13)
			{				
				var i = new JQuery(e.target).val();
				new JQuery(e.target).val("");
				testinput(i);
			}
		});
	}
	
	static function newline() : Promise
	{
		return type(""); 
	}
	
	static function type(txt : String) : Promise
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
				
				el.text(el.text().substr(0, el.text().length-1) + type + '|');

				if (char == txtLen) 
				{
					el.text(el.text().substr(0, el.text().length - 1));
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
