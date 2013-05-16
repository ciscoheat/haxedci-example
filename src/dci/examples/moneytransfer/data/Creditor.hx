package dci.examples.moneytransfer.data;
import dci.examples.moneytransfer.contexts.Account;

class Creditor
{
	public function new() 
	{}
	
	public var name(default, default) : String;
	public var amountOwed(default, default) : Float;
	public var account(default, default) : Account;
	
	public function toString()
	{
		return '$name, $$$amountOwed';
	}
}
