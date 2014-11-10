package dci.examples.restaurant.contexts;
import haxedci.Context;
import dci.examples.moneytransfer.contexts.Account;
import dci.examples.moneytransfer.contexts.MoneyTransfer;
import haxe.Timer;
import jQuery.Deferred;
import jQuery.Promise;
import js.html.MenuElement;

private typedef IMenu = Array<String>;

/**
 * Simulation of serving food at a restaurant.
 */
class ServeFood implements Context
{
	public function new(waiter, chef, menu, guests, account)
	{
		// Role binding
		this.waiter = waiter;
		this.chef = chef;
		this.menu = menu;
		this.guests = guests;
		this.bill = 0;
		this.account = account;
	}

	///// System Operations /////

	public function guestsArriving() : Promise
	{
		return waiter.guestsArriving();
	}

	public function guestsOrdering(choice : Int) : Promise
	{
		return waiter.takeOrder(choice);
	}

	public function guestsPaying() : Promise
	{
		return bill > 0
			? waiter.collectPayment()
			: new Deferred().resolve().promise();
	}

	///// Roles and their RoleMethods /////

	@role var waiter : {
		var name : String;
	} =
	{
		function guestsArriving() : Promise
		{
			var output = guests.output;

			return output('Good evening, my name is ${self.name}, I\'ll be your waiter.')
			.then(output.bind("This is on the menu for tonight:"))
			.then(output.bind(""))
			.then(guests.selectFood);
		}

		function takeOrder(choice : Int) : Promise
		{
			if (choice >= 1 && choice <= menu.length)
			{
				var text = menu.choice(choice) + ", an excellent choice. I'll be right back.";
				return guests.output(text).then(chef.cook.bind(choice));
			}
			else
			{
				return guests.output("Sorry sir, we don't have that on the menu tonight.");
			}
		}

		function serve(food : String)
		{
			var price = Std.random(90) + 10;
			guests.eat(food, price);
		}

		function collectPayment() : Promise
		{
			// Just create a temp account.
			var restaurantAccount = new Account([]);

			// A small delay for payment processing
			return guests.output('Your total is $$${bill}.', 2000)
			.then(function() {
				try {
					new MoneyTransfer(account, restaurantAccount, bill).transferAndDeclineIfNotEnough();
					return guests.output("Thank you very much, sir.");
				}
				catch (e : String) {
					var def = new Deferred();
					guests.output("Sorry sir, your card was declined.").then(def.reject);
					return def;
				}
			});
		}
	}

	@role var chef : {
		var cookingSkill : Int;
	} =
	{
		function cook(choice : Int)
		{
			var def = new Deferred();
			var points = 2;
			var wait = 0;

			if (Std.random(10) < self.cookingSkill)
			{
				points--;
				wait += 2000;
				Timer.delay(def.notify.bind("You hear a crash in the kitchen."), wait);
			}

			if (Std.random(10) < self.cookingSkill)
			{
				points--;
				wait += 2000;
				Timer.delay(def.notify.bind("Something smells burnt."), wait);
			}

			wait += 3000;

			Timer.delay(function()
			{
				var foodName = menu.choice(choice);
				var dish = switch(points)
				{
					case 0:
						"something that looks like a charcoaled roadkill.";
					case 1:
						'a slightly disfigured $foodName.';
					case 2:
						'a rather nice looking $foodName.';
					case _:
						throw "Never send a human to do a machine's job.";
				}

				def.resolve(dish);
			}, wait);

			// Three arguments: done, fail, progress
			return def.promise().then(
				function(food) waiter.serve(food),
				null,
				function(msg) guests.output(msg)
			);
		}
	}

	@role var guests : {
		function output(msg : String, ?delay : Int) : Promise;
	} =
	{
		function selectFood()
		{
			menu.display();
		}

		function eat(food : String, price : Int)
		{
			this.bill += price;

			self.output("You are served " + food)
			.then(self.output.bind('That will be $$$price, sir. You can pay when you leave.'));
		}
	}

	@role var menu : Array<String> =
	{
		function display()
		{
			var index = 0;

			for (item in self)
				guests.output(++index + " - " + item);

			guests.output("");
		}

		function choice(choice : Int) return self[choice-1];
	}

	@role var bill : Int;
	@role var account : Account;
}
