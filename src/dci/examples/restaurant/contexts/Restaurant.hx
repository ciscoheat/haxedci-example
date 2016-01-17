package dci.examples.restaurant.contexts;
import dci.examples.matrix.Console;
import dci.examples.moneytransfer.contexts.Account;
import dci.examples.restaurant.data.Employee;
import jQuery.Deferred;
import jQuery.Promise;

/**
 * An online Restaurant with a waiter, menu, guests and the current order.
 */
class Restaurant implements haxedci.Context
{
	/**
	 * The process is a system-level concept and should not play a
	 * Role in this Context.
	 */
	var process : Deferred;

	public function new(console, account)
	{
		// Make a random chef
		var chef = new Employee();
		chef.name = "Mr. Blumensay";
		chef.birth = new Date(1970, 1, 1, 0, 0, 0);
		chef.cookingSkill = Std.random(10);

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

		// And finally, todays menu.
		var menu = new Array<String>();
		menu.push("Peking Duck");
		menu.push("Shepherds Pie");
		menu.push("Crab Cake");
		menu.push("Roast Beef");

		// Bind the Roles
		this.guests = console;
		this.waiter = waiter;
		this.menu = menu;
		this.order = new ServeFood(waiter, chef, menu, console, account);
	}

	public function start() : Deferred
	{
		process = new Deferred();
		order.guestsArriving().then(process.notify);
		return process;
	}

	public function input(msg : String) : Promise
	{
		var def = new Deferred();
		var choice = Std.parseInt(msg);

		if (choice != null)
		{
			return order.guestsOrdering(choice);
		}
		else
		{
			switch(msg.toLowerCase())
			{
				case '':

				case "quit", "exit", "leave", "goodbye", "bye", "pay", "go home", "go back":
					order.guestsPaying().done(function() waiter.bidFarewell().then(process.resolve));

				case _:
					var name = Std.random(10) == 9 ? "Neo" : "sir";
					guests.output('Pardon me, $name?');
			}
		}

		return def.resolve().promise();
	}

	///// Roles and their RoleMethods /////

	@role var waiter : {
		var name : String;
	} =
	{
		function bidFarewell() : Promise
		{
			return guests.output('Goodbye, have a nice evening sir.')
			.then(guests.output.bind(''));
		}
	}

	@role var guests : {
		function output(msg : String, ?delay : Int, ?padding : Int) : Promise;
	};

	@role var menu : {
		function iterator() : Iterator<String>;
	};
	
	@role var order : {
		function guestsOrdering(choice : Int) : Promise;
		function guestsArriving() : Promise;
		function guestsPaying() : Promise;
	};
}
