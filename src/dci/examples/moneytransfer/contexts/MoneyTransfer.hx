package dci.examples.moneytransfer.contexts;

typedef ISourceAccount = 
{
	function withdraw(amount : Float) : Void;
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
	@role var amount : Amount;

	public function new(source : ISourceAccount, destination : IDestinationAccount, amount : IAmount)
	{
		bindRoles(source, destination, amount);
	}

	function bindRoles(source, destination, amt)
	{
		sourceAccount = new SourceAccount(source);
		destinationAccount = new DestinationAccount(destination);
		amount = new Amount(amt);
		
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
}

@:build(Dci.role(MoneyTransfer))
private abstract Amount(IAmount) from IAmount to IAmount
{}

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
