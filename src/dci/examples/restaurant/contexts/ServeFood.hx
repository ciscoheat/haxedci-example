package dci.examples.restaurant.contexts;
import dci.Context;
import dci.examples.moneytransfer.contexts.Account;
import dci.examples.moneytransfer.contexts.MoneyTransfer;
import haxe.Timer;
import jQuery.Deferred;
import jQuery.Promise;
import js.html.MenuElement;

private typedef IMenu = Array<String>;

class ServeFood implements Context
{
	@role var waiter =
	{
		var roleInterface : {
			var name : String;
		}
		
		function guestsArriving() : Promise
		{
			var output = guests.output;
			
			return output('Good evening, my name is ${self.name}, I\'ll be your waiter.')
			.then(function() { return output("This is on the menu for tonight:"); })
			.then(function() { return output(""); })
			.then(function() { guests.selectFood(); });
		}
		
		function takeOrder(choice : Int) : Promise
		{
			var text = menu.choice(choice) + ", an excellent choice. I'll be right back.";
			
			return guests.output(text)
			.then(function() { return chef.cook(choice); })
			.then(
				function(food) { self.serve(food); },
				null,
				function(msg) { guests.output(msg); }
			);
		}
		
		function serve(food : String)
		{
			var bill = Std.random(90) + 10;
			guests.eat(food, bill);
		}
		
		function pay(account : Account) : Promise
		{
			// Just create a temp account.
			var restaurantAccount = new Account([]);		
			
			return guests.output('Your total is $$${bill}.')
			.then(function() {
				new MoneyTransfer(account, restaurantAccount, bill).executeAndDeclineIfNotEnough();
			})
			.then(function() { return guests.output("Thank you very much, sir."); });
		}
	}
	
	@role var chef =
	{
		var roleInterface : {
			var cookingSkill : Int;
		}
		
		function cook(choice : Int) 
		{
			var def = new Deferred();
			var points = 2;
			var wait = 0;
			
			if (Std.random(10) < self.cookingSkill)
			{
				points--;
				wait += 2000;
				
				Timer.delay(function() 
				{
					def.notify("You hear a crash in the kitchen.");
				}, wait);
			}

			if (Std.random(10) < self.cookingSkill)
			{
				points--;
				wait += 2000;
				
				Timer.delay(function() 
				{
					def.notify("Something smells burnt.");
				}, wait);
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
						throw "Not possible.";
				}
				
				def.resolve(dish);
			}, wait);

			return def.promise();
		}
	}

	@role var guests =
	{
		var roleInterface : {
			function output(msg : String, ?delay : Int) : Promise;
		}
		
		function selectFood()
		{
			menu.display();
		}
		
		function eat(food : String, bill : Int)
		{
			// Note: this refers to the context.
			this.bill += bill;

			self.output("You are served " + food)
			.then(function() { return self.output('That will be $$$bill, sir. You can pay when you leave.'); });
		}
	}

	@role var menu =
	{
		var roleInterface : Array<String>;
		
		function display()
		{
			var index = 0;
			for (item in self)
			{
				guests.output(++index + " - " + item);
			}
			
			guests.output("");
		}
		
		function choice(choice : Int)
		{
			return self[choice-1];
		}
	}
	
	@role var bill : Int;
	
	public function new(waiter, chef, menu, guests)
	{
		this.waiter = waiter;
		this.chef = chef;
		this.menu = menu;
		this.guests = guests;
		this.bill = 0;
	}
	
	public function guestsArriving() : Promise
	{
		return waiter.guestsArriving();
	}
	
	public function guestsOrdering(choice : Int) : Promise
	{
		return waiter.takeOrder(choice);
	}
	
	public function guestsPaying(account : Account) : Promise
	{
		return bill > 0 
			? waiter.pay(account)
			: new Deferred().resolve().promise();
	}
}
