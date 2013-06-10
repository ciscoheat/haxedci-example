package dci.examples.restaurant.contexts;
import dci.Context;
import dci.examples.moneytransfer.contexts.Account;
import dci.examples.moneytransfer.contexts.MoneyTransfer;
import haxe.Timer;
import jQuery.Deferred;
import jQuery.Promise;
import js.html.MenuElement;

private typedef IWaiter = {
	var name : String;
}

private typedef IChef = {
	var cookingSkill : Int;
}

private typedef IGuests = {
	function output(msg : String, ?delay : Int) : Promise;
}

private typedef IMenu = Array<String>;

class ServeFood implements Context
{
	@role var waiter : Waiter;
	@role var chef : Chef;
	@role var guests : Guests;
	@role var menu : Menu;
	@role var bill : Int;
	
	public function new(waiter : IWaiter, chef : IChef, menu : IMenu, guests : IGuests)
	{
		this.waiter = new Waiter(waiter);
		this.chef = new Chef(chef);
		this.menu = new Menu(menu);
		this.guests = new Guests(guests);
		this.bill = 0;
	}
	
	public function guestsArriving() : Promise
	{
		return guests.tell(waiter.name);
	}
	
	public function guestsOrdering(choice : Int) : Promise
	{
		return waiter.order(choice);
	}
	
	public function guestsPaying(account : Account) : Promise
	{
		return waiter.pay(account);
	}
}

@:build(Dci.role(ServeFood))
@:arrayAccess private abstract Menu(IMenu) from IMenu to IMenu
{
	function iterator()
	{
		return this.iterator();
	}
	
	public function display()
	{
		var c : ServeFood = context;
		
		var index = 0;
		for (item in this)
		{
			c.guests.output(++index + " - " + item);
		}
		
		c.guests.output("");
	}
	
	public function choice(choice : Int)
	{
		return this[choice-1];
	}
}

@:build(Dci.role(ServeFood))
private abstract Chef(IChef)
{
	public function cook(choice : Int) 
	{
		var c : ServeFood = context;
		var self : Chef = c.chef;
		
		var def = new Deferred();
		var points = 2;
		var wait = 0;
		
		if (Std.random(10) < this.cookingSkill)
		{
			points--;
			wait += 2000;
			
			Timer.delay(function() 
			{
				def.notify("You hear a crash in the kitchen.");
			}, wait);
		}

		if (Std.random(10) < this.cookingSkill)
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
			var foodName = c.menu.choice(choice);
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

@:build(Dci.role(ServeFood))
private abstract Guests(IGuests) from IGuests to IGuests
{
	public function output(msg : String, ?delay : Int)
	{
		return this.output(msg, delay);
	}
	
	public function tell(name : String) : Promise
	{
		return this.output('Good evening, my name is $name, I\'ll be your waiter.')
		.then(function() { return this.output("This is on the menu for tonight:"); })
		.then(function() { this.output(""); })
		.then(function() { context.menu.display(); });
	}
	
	public function serve(food : String, bill : Int)
	{
		var c : ServeFood = context;

		c.bill += bill;

		this.output("You are served " + food)
		.then(function() { return this.output('That will be $$$bill, sir. You can pay when you leave.'); });
	}
}

@:build(Dci.role(ServeFood))
private abstract Waiter(IWaiter) from IWaiter to IWaiter 
{
	public var name(get, never) : String;
	public function get_name() { return this.name; }

	public function order(choice : Int) : Promise
	{
		var c : ServeFood = context;
		var self : Waiter = c.waiter;
		
		var text = c.menu.choice(choice) + ", an excellent choice. I'll be right back.";
		
		return c.guests.output(text)
		.then(function() { return c.chef.cook(choice); })
		.then(
			function(food) { self.deliver(food); },
			null,
			function(msg) { c.guests.output(msg); }
		);
	}
	
	public function deliver(food : String)
	{
		var c : ServeFood = context;
		var bill = Std.random(90) + 10;
		
		c.guests.serve(food, bill);
	}
	
	public function pay(account : Account)
	{
		var c : ServeFood = context;
		
		// Just create a temp account.
		var restaurantAccount = new Account([]);		
		
		return c.guests.output('Your total is $$${c.bill}.')
		.then(function() {
			new MoneyTransfer(account, restaurantAccount, c.bill).executeAndDeclineIfNotEnough();
		})
		.then(function() { return c.guests.output("Thank you very much, sir."); });
	}
}