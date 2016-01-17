package dci.examples.moneytransfer.contexts;

class MoneyTransfer implements haxedci.Context
{
	public function new(source, destination, amount)
	{
		this.sourceAccount = source;
		this.destinationAccount = destination;
		this.amount = amount;
	}

	public function transfer()
	{
		sourceAccount.transfer(false);
	}

	public function transferButDeclineIfNotEnough()
	{
		sourceAccount.transfer(true);
	}

	var amount : Float;

	@role var sourceAccount : {
		function withdraw(amount : Float) : Void;
		function balance() : Float;
	} =
	{
		function transfer(declineIfNotEnough : Bool)
		{
			if (declineIfNotEnough && self.balance() < amount)
				throw "Declined: Not enough money in account.";
			
			self.withdraw(amount);
			destinationAccount.deposit(amount);
		}
	}

	@role var destinationAccount : {
		function deposit(amount : Float);
	};
}
