package contexts;
import dci.Context;

typedef SourceAccountInterface = 
{
	function Withdraw(amount : Float) : Void;
}

typedef DestinationAccountInterface = 
{
	function Deposit(amount : Float) : Void;
}

typedef MoneyTransferRoles =
{
	private var sourceAccount : SourceAccount;
	private var destinationAccount : DestinationAccount;
	private var amount : Amount;
}

@:build(Dci.context())
class MoneyTransfer
{
	// Roles
	@role var sourceAccount : SourceAccount;
	@role var destinationAccount : DestinationAccount;
	@role var amount : Amount;

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
private abstract Amount(Float) to Float
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
		var context : MoneyTransferRoles = Context.Current;
		
		this.Withdraw(context.amount);
		context.destinationAccount.Deposit(context.amount);
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