package dci.examples.moneytransfer.contexts;

typedef ISourceAccount = 
{
	function withdraw(amount : Float) : Void;
	function balance() : Float;
}

typedef IDestinationAccount = 
{
	function deposit(amount : Float) : Void;
}

typedef IAmount = Float;

class MoneyTransfer implements dci.Context
{
	@role var sourceAccount : SourceAccount;
	@role var destinationAccount : DestinationAccount;
	@role var amount : IAmount;

	public function new(source : ISourceAccount, destination : IDestinationAccount, amount : IAmount)
	{
		bindRoles(source, destination, amount);
	}

	function bindRoles(source, destination, amt)
	{
		sourceAccount = new SourceAccount(source);
		destinationAccount = new DestinationAccount(destination);
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

@:build(Dci.role(MoneyTransfer))
private abstract SourceAccount(ISourceAccount)
{
	public function transfer()
	{
		// Until autocompletion works for injected local vars, define it yourself:
		var c : MoneyTransfer = context;
		
		this.withdraw(c.amount);
		c.destinationAccount.deposit(c.amount);
	}
	
	// Until the automatic RoleInterface implementation is done, this definition is needed.
	public function withdraw(amount : Float)
	{
		this.withdraw(amount);
	}
	
	public function balance()
	{
		return this.balance();
	}
}

@:build(Dci.role(MoneyTransfer))
private abstract DestinationAccount(IDestinationAccount)
{
	// Until the automatic RoleInterface implementation is done, this definition is needed.
	public function deposit(amount : Float)
	{
		this.deposit(amount);
	}
}
