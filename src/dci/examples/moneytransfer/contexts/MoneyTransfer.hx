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
		sourceAccount.transfer();
	}

	public function transferAndDeclineIfNotEnough()
	{
		if (sourceAccount.balance() < amount)
			throw "Declined: Not enough money in account.";
		else
			transfer();
	}

	@role var amount : Float;

	@role var sourceAccount : {
		function withdraw(amount : Float) : Void;
		function balance() : Float;
	} =
	{
		function transfer() : Void
		{
			self.withdraw(amount);
			destinationAccount.deposit(amount);
		}
	}

	@role var destinationAccount : {
		function deposit(amount : Float) : Void;
	};
}
