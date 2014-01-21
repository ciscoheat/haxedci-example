# DCI in Haxe
[Haxe](http://haxe.org) is a nice multiplatform language which in its third release (May 2013), enables a complete DCI implementation. This repository is a supplement to the [haxedci](https://github.com/ciscoheat/haxedci) library, giving a small introduction in this readme file, and having a larger example ready for download.

This document is supposed to give you an introduction to DCI, as well as describing the library usage. At the end you can find multiple DCI resources for further exploration.

## Short introduction
DCI stands for Data, Context, Interaction. One of the key aspects of DCI is to separate what a system *is* (data) from what it *does* (function). Data and function has very different rates of change so they should be separated, not as it currently is, put in classes together.

DCI also embodies true object-orientation where runtime Interactions between a network of objects in a particular Context is understood _and_ coded as first class citizens.

## Example: A money transfer
(Thanks to [Marc Grue](https://github.com/marcgrue) for the original tutorial.)

Let's take a simple Data class Account with some basic methods:

#### Account.hx
```actionscript
package;

class Account {
    public var name(default, null) : String;
	public var balance(default, null) : Int;

	public function new(name, balance) {
		this.name = name;
		this.balance = balance;
	}

	public function increaseBalance(amount: Int) { 
		balance += amount;
	}

	public function decreaseBalance(amount: Int) { 
		balance -= amount;
	}
}
```
This is what we in DCI sometimes call a "dumb" data class. It only "knows" about its own data and how to manipulate that. The concept of a transfer between two accounts is outside its responsibilities and we delegate this to a Context - the MoneyTransfer Context class. In this way we can keep the Account class very slim and avoid that it gradually takes on more and more responsibilities for each use case it participates in.

From a users point of view we might think of a money transfer as 

- "Move money from one account to another"

and after some more thought specify it further: 

- "Withdraw amount from a source account and deposit the amount in a destination account"

That could be our "Mental Model" of a money transfer. Interacting concepts like our "Source" and "Destination" accounts of our mental model we call "Roles" in DCI, and we can define them and what they do to accomplish the money transfer in a DCI Context:

#### MoneyTransfer.hx
```actionscript
package;

class MoneyTransfer implements dci.Context {
	@role var source = {
		var roleInterface : {
			function decreaseBalance(a : Int) : Void;
		}
		
		function withdraw()	{
			self.decreaseBalance(amount);
			destination.deposit();
		}
	}

	@role var destination =	{
		var roleInterface : {
			function increaseBalance(a : Int) : Void;
		}
		
		function deposit() {
			self.increaseBalance(amount);
		}
	}
	
	@role var amount : Int;
	
	public function new(source, destination, amount) {
		this.source = source;
		this.destination = destination;
		this.amount = amount;
	}
	
	public function execute() {
		source.withdraw();
	}
}
```
**(Detailed syntax explanation follows in the Usage section later.)**

We want our source code to map as closely to our mental model as possible so that we can confidently and easily overview and reason about _how the objects will interact at runtime_! 

We want to expect no surprises at runtime. With DCI we have all runtime interactions right there! No need to look through endless convoluted abstractions, tiers, polymorphism etc to answer the reasonable question _where is it actually happening, goddammit?!_

To execute this MoneyTransfer context, lets create two accounts, the Context, and execute it:

#### Main.hx
```actionscript
package ;

class Main {	
	static function main() {
		var savings = new Account("Savings", 1000);
		var home = new Account("Home", 0);

		trace("Before transfer:");
		trace(savings.name + ": $" + savings.balance);
		trace(home.name + ": $" + home.balance);

		// Creating and executing the Context:
		new MoneyTransfer(savings, home, 500).execute();

		trace("After transfer:");
		trace(savings.name + ": $" + savings.balance);
		trace(home.name + ": $" + home.balance);
	}	
}
```
Hopefully you have grasped the basics now, but please keep reading for the details...

## Library usage
To use haxedci, you need to be able to create Contexts. Lets build the `MoneyTransfer` class step-by-step from scratch:

Start by defining a class and let it implement `dci.Context`.
```actionscript
class MoneyTransfer implements dci.Context {
}
```
Remember the mental model of a money transfer? "Withdraw *amount* from a *source* account and deposit the amount in a *destination* account". The three highlighted nouns are the Roles that we will use in the Context. Lets put them there. They are defined using the `@role` metadata:
```actionscript
class MoneyTransfer implements dci.Context {
	@role var source = {
		var roleInterface : Account;
	} 

	@role var destination = {
		var roleInterface : Account;
	} 

	@role var amount = {
		var roleInterface : Int;
	} 
}
```
Using this syntax, we have now defined three Roles and a **RoleInterface** for each one. A RoleInterface describes what is required for an object to play this Role.

### Defining a RoleInterface
There are a couple of ways of defining a RoleInterface which we will explore now. For starters, the variable has to be named `roleInterface`.

We have started out quick and easy by a broad definition: The source and destination Roles must be an `Account` object:
```actionscript
@role var source = {
	var roleInterface : Account;
} 
```
Thinking about it however, we're not interested in the whole `Account`. Since we want to focus on what happens in the Context and right now for a specific Role, all we need for playing the `source` Role is a way of decreasing the balance. The `Account` class has a `decreaseBalance` method, let's use it:
```actionscript
@role var source = {
	var roleInterface : {
		function decreaseBalance(a : Int) : Void;
	}
}
```
Now we're using [Haxe class notation](http://haxe.org/manual/struct#class-notation) to define the RoleInterface. Let's do the same for the `destination` Role, but it needs to increase the balance instead:
```actionscript
@role var destination = {
	var roleInterface : {
		function increaseBalance(a : Int) : Void;
	}
}
```
The `amount` role will be simpler. We're only using it as an `Int`, so we can specify the RoleInterface directly on the definition:
```actionscript
@role var amount : Int;
```
Our MoneyTransfer class now looks like this:
```actionscript
class MoneyTransfer implements dci.Context {
	@role var source = {
		var roleInterface : {
			function decreaseBalance(a : Int) : Void;
		}
	}

	@role var destination =	{
		var roleInterface : {
			function increaseBalance(a : Int) : Void;
		}
	}
	
	@role var amount : Int;
}
```
What are the advantages of this structural typing? Why not just put the class there and be done with it?

The most obvious advantage is that we're making the Role more generic. Any object fulfilling the type of the RoleInterface can now be a money source, not just Accounts.

Another very interesting advantage is that when specifying a smaller RoleInterface, we only see what the Roles can do in the current Context. This is called "Full OO", a powerful concept that you can [read more about here](https://groups.google.com/d/msg/object-composition/umY_w1rXBEw/hyAF-jPgFn4J).

Using a complete class can be tempting because it's quick and you'll get full access in case you need something. It can be good as as start, but don't be lazy with your code. Work on the class API, consider what it does and why. Then refine your RoleInterfaces. DCI is as much about clear and readable code as matching a mental model and separating data from function.

### RoleMethods
Now we have the Roles and their interfaces for accessing the underlying Data. A good start, so lets add the core of a DCI Context: functionality. It is implemented through **RoleMethods**.

Getting back to the mental model again, we know that we want to "Withdraw amount from a source account and deposit the amount in a destination account". So lets model that in a RoleMethod for the `source` Role:
```actionscript
@role var source = {
	var roleInterface : {
		function decreaseBalance(a : Int) : Void;
	}
	
	function withdraw()	{
		self.decreaseBalance(amount);
		destination.deposit();
	}
}
```
This is a very close mapping of the mental model to code, which is the goal of DCI. Note how we're using the RoleInterface method only for the actual Data operation, the rest is functionality, collaboration between Roles. We have the need for another RoleMethod on destination called `deposit`:
```actionscript
@role var destination =	{
	var roleInterface : {
		function increaseBalance(a : Int) : Void;
	}
	
	function deposit() {
		self.increaseBalance(amount);
	}
}
```
### Accessors: this, self and context
A RoleMethod is a stateless method with access only to its RolePlayer and the current Context. You can access them through variables that is automatically available in RoleMethods:

- `this`- Points to the current Context
- `self` - The current RolePlayer
- `context` - An alias for `this`.

### More about functionality
Functionality can change frequently, and will match the mental model. RoleMethods will come and go as requirement changes. The Data however will probably remain stable much longer. An `Account` will stay the same, no matter how fancy web functionality is available. So take care when designing your Data classes. A well-defined Data structure can support a lot of functionality through its RoleInterface.

When designing RoleMethods, be careful not to end up with one big method doing all the work. That is an imperative approach which limits the power of DCI, since we're aiming for communication between Roles, not a procedural algorithm that tells the Roles what to do. Make the methods small, and let the mental model of the Context become the guideline. A [Use case](http://www.usability.gov/how-to-and-tools/methods/use-cases.html) is a formalization of a mental model that is supposed to map to a Context in DCI.

A difference between that kind of procedure orientation and object orientation is that in the former, we ask: “What happens?” In the latter, we ask: “Who does what?” Even in a simple example, a reader looses the “who” and thereby important locality context that is essential for building a mental model of the algorithm. ([From the DCI FAQ](http://fulloo.info/doku.php?id=what_is_the_advantage_of_distributing_the_interaction_algorithm_in_the_rolemethods_as_suggested_by_dci_instead_of_centralizing_it_in_a_context_method))

### Adding a constructor
Let's add a constructor to the class:
```actionscript
class MoneyTransfer implements dci.Context {
	@role var source = {
		var roleInterface : {
			function decreaseBalance(a : Int) : Void;
		}
		
		function withdraw()	{
			self.decreaseBalance(amount);
			destination.deposit();
		}
	}

	@role var destination =	{
		var roleInterface : {
			function increaseBalance(a : Int) : Void;
		}
		
		function deposit() {
			self.increaseBalance(amount);
		}
	}
	
	@role var amount : Int;

	public function new(source, destination, amount) {
		this.source = source;
		this.destination = destination;
		this.amount = amount;
	}	
}
```
Nothing special about this one, just assign the Roles as normal instance variables. This is called *Role-binding*, and there are two important things to remember:

1. All Roles are bound as an atomic operation before an Interaction starts. 
1. A Role should not be unbound.

Rebinding Roles during executing complicates things immensely, and isn't. So put the binding in one place, you can factorize it out of the constructor to a "bindRoles" method if you want. Note that the Roles be rebound before another Interaction in the same Context occurs.

### Interaction(s)
Now we have talked about **Interactions**, which is the final concept to learn before we can use the Context. It is simply a starting point for executing a Context. All an Interaction should do is to call a RoleMethod, so the Roles start interacting with each other.

There may be many Interactions in a Context, but in this case we only need one, so lets call it `execute`.
```actionscript
package;

class MoneyTransfer implements dci.Context {
	@role var source = {
		var roleInterface : {
			function decreaseBalance(a : Int) : Void;
		}
		
		function withdraw()	{
			self.decreaseBalance(amount);
			destination.deposit();
		}
	}

	@role var destination =	{
		var roleInterface : {
			function increaseBalance(a : Int) : Void;
		}
		
		function deposit() {
			self.increaseBalance(amount);
		}
	}
	
	@role var amount : Int;
	
	public function new(source, destination, amount) {
		this.source = source;
		this.destination = destination;
		this.amount = amount;
	}
	
	public function execute() {
		source.withdraw();
	}
}
```
Now when we can interact with our MoneyTransfer Context, it's ready for use! You saw how it's done earlier, but here are the essentials:
```actionscript
class Main {	
	static function main() {
		var savings = new Account("Savings", 1000);
		var home = new Account("Home", 0);

		new MoneyTransfer(savings, home, 500).execute();
	}	
}
```

## Advantages
Ok, we have learned new concepts and a different way of structuring our program. But why should we do all this?

The advantage we get from using Roles and RoleMethods in a Context, is that we know exactly where our functionality is. It's not spread out in multiple classes anymore. When we talk about "money transfer", we know exactly where in the code it is handled now. Another thing is that we keep the code simple. No facades or other abstractions, just the methods we need.

DCI is a new paradigm, which forces the mind in different directions than the normal OO-thinking, which is really class-oriented, since functionality are spread out in classes, not in Roles. DCI on the other hand is separating Data (RoleInterfaces) from Function (RoleMethods), which is a good mind-exercise, and a beautiful system architecture as a result! No polymorphism, no intergalactic GOTOs (or virtual methods as they are also called), everything is kept where it should, in Context.

## Next steps
Clone this repository or [download it](https://github.com/ciscoheat/haxedci-example/archive/master.zip), then open the [FlashDevelop](http://www.flashdevelop.org/) project file, or just execute run.bat (or the "run" script if you're on Linux), to see an advanced example in action:

* A much larger network of communicating objects
* Nested Contexts
* Bank Account transfers
* Restaurant visits
* An asynchronous DOS console
* ...and more!
 
## DCI Resources
Website - [fulloo.info](http://fulloo.info) <br>
FAQ - [DCI FAQ](fulloo.info/doku.php?id=faq) <br>
Support - [stackoverflow](http://stackoverflow.com/questions/tagged/dci), tagging the question with **dci** <br>
Discussions - [Object-composition](https://groups.google.com/forum/?fromgroups#!forum/object-composition) <br>
Wikipedia - [DCI entry](http://en.wikipedia.org/wiki/Data,_Context,_and_Interaction) <br>

Good luck with DCI, and have fun!
