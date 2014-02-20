package dci.examples.moneytransfer.contexts;

class MoneyTransfer implements haxedci.Context
{
	public function new(source, destination, amount)
	{
		bindRoles(source, destination, amount);
	}

	function bindRoles(source, destination, amt)
	{
		sourceAccount = source;
		destinationAccount = destination;
		amount = amt;		
	}
	
	public function transfer()
	{
		sourceAccount.transfer();
	}
	
	public function transferButDeclineIfNotEnough()
	{
		if (sourceAccount.balance() < amount)
			throw "Declined: Not enough money in account.";
		else
			transfer();
	}
	
	@role var sourceAccount =
	{
		var roleInterface : {
			function withdraw(amount : Float) : Void;
			function balance() : Float;
		}
		
		function transfer() : Void
		{
			self.withdraw(amount);
			destinationAccount.deposit(amount);
		}
	}
	
	@role var destinationAccount =
	{
		var roleInterface : {
			function deposit(amount : Float) : Void;
		}
	}
	
	@role var amount : Float;
}
