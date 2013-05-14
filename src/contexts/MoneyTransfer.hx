package contexts;
import dci.Context;
import dci.ContextStorage;

typedef SourceAccountInterface = 
{
	function Withdraw(amount : Float) : Void;
}

typedef DestinationAccountInterface = 
{
	function Deposit(amount : Float) : Void;
}

class MoneyTransfer implements dci.Context
{
	@role @:allow(contexts) var sourceAccount : SourceAccount;
	@role @:allow(contexts) var destinationAccount : DestinationAccount;
	@role @:allow(contexts) var amount : Amount;

	public function new(source, destination, amount)
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
	public function Execute()
	{
		sourceAccount.Transfer();
	}
}

@:build(Dci.role(MoneyTransfer))
private abstract Amount(Float) from Float to Float
{
	public inline function new(amount)
	{
		this = amount;
	}	
}

@:build(Dci.role(MoneyTransfer))
private abstract SourceAccount(SourceAccountInterface)
{
	public inline function new(account)
	{
		this = account;
	}
	
	public function Transfer()
	{
		// First one gets Autocomplete, second one and "context" doesn't?
		//var context2 : MoneyTransfer = dci.ContextStorage.current;
		//var context2 = cast(ContextStorage.current, MoneyTransfer);
		
		this.Withdraw(context.amount);
		context.destinationAccount.Deposit(context.amount);
	}
	
	public function Withdraw(amount : Float)
	{
		this.Withdraw(amount);
	}
}

@:build(Dci.role(MoneyTransfer))
private abstract DestinationAccount(DestinationAccountInterface)
{
	public inline function new(account)
	{
		this = account;
	}
	
	public function Deposit(amount : Float)
	{
		this.Deposit(amount);
	}
}