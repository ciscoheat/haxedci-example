package dci.examples.moneytransfer.contexts;

class MoneyTransfer implements dci.Context
{
	@role var sourceAccount =
	{
		var roleInterface : {
			function withdraw(amount : Float) : Void;
			function balance() : Float;
		}
		
		function transfer()
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

	public function new(source, destination, amount)
	{
		bindRoles(source, destination, amount);
	}

	function bindRoles(source, destination, amt)
	{
		sourceAccount = source;
		destinationAccount = destination;
		amount = amt;
		
		// Object identity assertions
		if (untyped sourceAccount != source)
			throw "Object identity broken for sourceAccount";

		if (untyped destinationAccount != destination)
			throw "Object identity broken for sourceAccount";

		if (untyped amount != amt)
			throw "Object identity broken for amount";
	}
	
	// Interaction
	public function execute()
	{
		sourceAccount.transfer();
	}
	
	public function executeAndDeclineIfNotEnough()
	{
		if (sourceAccount.balance() < amount)
			throw "Declined: Not enough money in account.";
		else
			execute();
	}
}
