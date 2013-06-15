package dci.examples.restaurant.contexts;
import dci.examples.matrix.Console;
import dci.examples.moneytransfer.contexts.Account;
import dci.examples.restaurant.data.Employee;
import jQuery.Deferred;
import jQuery.Promise;

class Restaurant implements dci.Context
{
	@role var chef : Chef;
	@role var waiter : Waiter;
	@role var console : Console;
	@role var process : Deferred;
	@role var menu : IMenu;
	
	var order : ServeFood;
	var account : Account;

	public function new(console : Console, account : Account) 
	{
		this.console = console;
		this.account = account;
		
		// Make a random chef
		var chef = new Employee();
		chef.name = "Mr. Chef";
		chef.birth = new Date(1970, 1, 1, 0, 0, 0);
		chef.cookingSkill = Std.random(10);
		
		this.chef = new Chef(chef);
		
		// And a random waiter
		var waiter = new Employee();
		waiter.name = switch(Std.random(5))
		{
			case 0: "Jeeves";
			case 1: "James";
			case 2: "John";
			case 3: "Julian";
			case _: "Delbert";
		}
		
		this.waiter = new Waiter(waiter);
		
		// And finally, todays menu.
		var menu = new Array<String>();
		menu.push("Peking Duck");
		menu.push("Shepherds Pie");
		menu.push("Crab Cake");
		menu.push("Roast Beef");
		
		this.menu = menu;
	}

	public function start() : Deferred
	{
		process = new Deferred();
		order = new ServeFood(waiter, chef, menu, console);
		
		order.guestsArriving().then(process.notify);
		return process;
	}
	
	public function input(msg : String) : Promise
	{
		var def = new Deferred();		
		var choice = Std.parseInt(msg);
		
		if (choice != null && choice > 0 && choice <= menu.length)
		{
			return order.guestsOrdering(choice);
		}
		else if (choice != null)
		{
			console.output("Sorry sir, we don't have that on the menu tonight.");
		}
		else
		{
			switch(msg.toLowerCase())
			{
				case "quit", "exit", "leave", "goodbye", "bye", "pay", "go home", "go back":
					try
					{
						order.guestsPaying(account)
						.then(function() { return console.output('Goodbye, have a nice evening sir.'); })
						.then(console.newline)
						.then(process.resolve);
					}
					catch (e : String)
					{
						console.output("Sorry sir, your card was declined.");
					}
					
				case _:
					var name = Std.random(10) == 9 ? "Neo" : "sir";
					console.output('Pardon me, $name?');
			}
		}
		
		return def.resolve().promise();
	}
}

typedef IMenu = Array<String>;

typedef IChef = {
	var cookingSkill : Int;
};

@:build(Dci.role(Restaurant))
private abstract Chef(IChef) from IChef to IChef 
{
	public function roleMethod() 
	{
		var c : Restaurant = context;
		
	}
}

typedef IWaiter = {
	var name : String;
};

@:build(Dci.role(Restaurant))
private abstract Waiter(IWaiter) from IWaiter to IWaiter 
{
	public function roleMethod() 
	{
		var c : Restaurant = context;
		
	}
}