package dci.examples.restaurant.contexts;
import dci.Context;
import js.html.MenuElement;

typedef IWaiter = {
	var name : String;
}

typedef IChef = {
	var cookingSkill : Int;
}

typedef IGuests = {
	function output(msg : String) : Void;
	function waitForKey() : String;
}

typedef IMenu = Iterable<String>;

class ServeFood implements Context
{
	@role var waiter : Waiter;
	@role var chef : Chef;
	@role var guests : Guests;
	@role var menu : Menu;
	
	public function new(waiter : IWaiter, chef : IChef, guests : IGuests) 
	{
		this.waiter = new Waiter(waiter);
		this.chef = new Chef(chef);
		this.guests = new Guests(guests);
		
		var menu = new Array<String>();
		menu.push("Peking Duck");
		menu.push("Shepherds Pie");
		menu.push("Crab Cakes");
		menu.push("Roast Beef");
		
		this.menu = new Menu(menu);
	}
	
	public function guestsArriving()
	{
		guests.tell(waiter.name);
	}
	
	public function guestsOrdering()
	{
		
	}
}

@:build(Dci.role(ServeFood))
private abstract Waiter(IWaiter)
{
	
}

@:build(Dci.role(ServeFood))
private abstract Menu(IMenu) from IMenu to IMenu
{
	function iterator()
	{
		return this.iterator();
	}
	
	public function display()
	{
		var c : ServeFood = context;
		
		var index = 0;
		for (item : String in this)
		{
			c.guests.output(++index + " - " + item);
		}
	}
}

@:build(Dci.role(ServeFood))
private abstract Chef(IChef)
{
	
}

@:build(Dci.role(ServeFood))
private abstract Guests(IGuests)
{
	public function tell(name : String)
	{
		this.output('Good evening, my name is {$name}, I\'ll be your waiter for tonight.');
		this.output("This is on the menu for tonight:");
		this.output("");
		
		context.menu.display();
	}
}
