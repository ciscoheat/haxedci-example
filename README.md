# DCI in Haxe
[Haxe](http://haxe.org) is a nice multiplatform language which enables a full DCI implementation. This repository is a supplement to the [haxedci](https://github.com/ciscoheat/haxedci) library, having a larger example ready for download.

This document is supposed to give you an introduction to DCI, as well as describing the library usage. At the end you'll find multiple DCI resources for further exploration.

## Short introduction
DCI stands for Data, Context, Interaction. The key aspects of the DCI architecture are:

- Separating what the system *is* (data) from what it *does* (function). Data and function have different rates of change so they should be separated, not as it currently is, put in classes together.
- Create a direct mapping from the user's mental model to code. The computer should think as the user, not the other way around.
- Make system behavior a first class entity.
- Great code readability with no surprises at runtime.

## Example: A money transfer
(Thanks to [Marc Grue](https://github.com/marcgrue) for the original money transfer tutorial.)

Let's take a simple Data class Account with some basic methods:

#### Account.hx
```haxe
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

That could be our "Mental Model" of a money transfer. Interacting concepts like our "Source" and "Destination" accounts of our mental model we call "Roles" in DCI, and we can define them and what they do to accomplish the money transfer in a DCI Context.

Our source code should map as closely to our mental model as possible so that we can confidently and easily overview and reason about _how the objects will interact at runtime_. We want no surprises at runtime. With DCI we have all runtime interactions right there! No need to look through endless convoluted abstractions, tiers, polymorphism etc to answer the reasonable question _where is it actually happening, goddammit?!_

## Library usage
To use haxedci, you need to be able to create Contexts. Lets build the `MoneyTransfer` class step-by-step from scratch:

Start by defining a class and let it implement `haxedci.Context`.
```haxe
class MoneyTransfer implements haxedci.Context {
}
```
Remember the mental model of a money transfer? "Withdraw *amount* from a *source* account and deposit the amount in a *destination* account". The three italicized nouns are the Roles that we will use in the Context. Lets put them there. They are defined using the `@role` metadata:
```haxe
class MoneyTransfer implements haxedci.Context {
	@role var source : Account;
	@role var destination : Account;
	@role var amount : Int;
}
```
Using this syntax, we have now defined three Roles and a **RoleObjectContract** for each one. A RoleObjectContract describes what is required for an object to play this Role.

### Defining a RoleObjectContract
There are two ways of defining a RoleObjectContract that we will explore now.

We have started out quick and easy by a broad definition: The source and destination Roles must be an `Account` object:
```haxe
@role var source : Account;
```
Thinking about it however, we're not interested in the whole `Account`. Since we want to focus on what happens in the Context and right now for a specific Role, all we need for playing the *source* Role is a way of decreasing the balance. The `Account` class has a `decreaseBalance` method, let's use it:
```haxe
@role var source : {
	function decreaseBalance(a : Int) : Void;
};
```
We're using [Class notation for structure types](http://haxe.org/manual/types-structure-class-notation.html) to define the RoleObjectContract. Let's do the same for the *destination* Role, but it needs to increase the balance instead:
```haxe
@role var destination : {
	function increaseBalance(a : Int) : Void;
};
```
The *amount* role will be simpler. We're only using it as an `Int`, so we can specify the RoleObjectContract directly on the definition:
```haxe
@role var amount : Int;
```
Our `MoneyTransfer` class now looks like this:
```haxe
class MoneyTransfer implements haxedci.Context {
	@role var source : {
		function decreaseBalance(a : Int) : Void;
	};

	@role var destination : {
		function increaseBalance(a : Int) : Void;
	};

	@role var amount : Int;
}
```
What are the advantages of this structural typing? Why not just put the class there and be done with it?

The most obvious advantage is that we're making the Role more generic. Any object fulfilling the type of the RoleObjectContract can now be a money source, not just `Account`.

Another interesting advantage is that when specifying a more compressed RoleObjectContract, we only observe what the Roles can do in the current Context. This is called *"Full OO"*, a powerful concept that you can [read more about here](https://groups.google.com/d/msg/object-composition/umY_w1rXBEw/hyAF-jPgFn4J).

Using a whole class can be tempting because it's quick and you'll get full access in case you need something. It can be good as as start, but don't be lazy with your code. Work on the public class API, consider what it does, how it's named and why. Then refine your RoleObjectContracts. DCI is as much about clear and readable code as matching a mental model and separating data from function.

### RoleMethods
Now we have the Roles and their contracts for accessing the underlying Data. That's a good start, so lets add the core of a DCI Context: functionality. It is implemented through **RoleMethods**.

Getting back to the mental model again, we know that we want to "Withdraw amount from a source account and deposit the amount in a destination account". So lets model that in a RoleMethod for the `source` Role:
```haxe
@role var source : {
	function decreaseBalance(a : Int) : Void;
} =
{
	function withdraw() : Void {
		self.decreaseBalance(amount);
		destination.deposit();
	}
}
```
The `} =` syntax looks a bit strange at first, but the rest is a very close mapping of the mental model to code, which is the goal of DCI. Note how we're using the RoleObjectContract method only for the actual Data operation, the rest is functionality, collaboration between Roles. This collaboration requires a RoleMethod on destination called `deposit`:
```haxe
@role var destination : {
	function increaseBalance(a : Int) : Void;
} =
{
	function deposit() : Void {
		self.increaseBalance(amount);
	}
}
```
**Important:** If you want syntax autocompletion for the RoleMethods, you need to specify a return value for them explicitly!

### Accessors: self and this
A RoleMethod is a method with access only to its RolePlayer and the current Context. You can access the current RolePlayer through the `self` identifier which is automatically available in RoleMethods. `this` is not allowed in RoleMethods, as it can create confusion what it really references, the RolePlayer or the Context.

There are other rules enforced by the compiler that reduces the number of surprises in the code, which is one of the foremost goals of DCI - Readable code. Hopefully time will be found later to list them here.

### More about functionality and RoleMethods
Functionality can change frequently, as requirements changes. The Data however will probably remain stable much longer. An `Account` will stay the same, no matter how fancy web functionality is available. So take care when designing your Data classes. A well-defined Data structure can support a lot of functionality through a RoleObjectContract.

When designing functionality using RoleMethods in a Context, be careful not to end up with one big method doing all the work. That is an imperative approach which limits the power of DCI, since we're aiming for communication between Roles, not a procedural algorithm that tells the Roles what to do. Make the methods small, and let the mental model of the Context become the guideline. A [Use case](http://www.usability.gov/how-to-and-tools/methods/use-cases.html) is a formalization of a mental model that is supposed to map to a Context in DCI.

> A difference between [the imperative] kind of procedure orientation and object orientation is that in the former, we ask: _"What happens?"_ In the latter, we ask: _"Who does what?"_ Even in a simple example, a reader looses the "who" and thereby important locality context that is essential for building a mental model of the algorithm. ([From the DCI FAQ](http://fulloo.info/doku.php?id=what_is_the_advantage_of_distributing_the_interaction_algorithm_in_the_rolemethods_as_suggested_by_dci_instead_of_centralizing_it_in_a_context_method))

### Adding a constructor
Let's add a constructor to the class:
```haxe
class MoneyTransfer implements haxedci.Context {
	public function new(source, destination, amount) {
		this.source = source;
		this.destination = destination;
		this.amount = amount;
	}

	@role var source : {
		function decreaseBalance(a : Int) : Void;
	} =
	{
		function withdraw() : Void {
			self.decreaseBalance(amount);
			destination.deposit();
		}
	}

	@role var destination : {
		function increaseBalance(a : Int) : Void;
	} = { // <-- An alternative if you prefer braces on the same line
		function deposit() : Void {
			self.increaseBalance(amount);
		}
	}

	@role var amount : Int;
}
```
There's nothing special about it, just assign the Roles as normal instance variables. This is called *Role-binding*, and there are two important things to remember:

1. All Roles *must* be bound in the same function.
1. A Role should not be left unbound.

Rebinding individual Roles during executing complicates things, and is hardly supported by any mental model. So put the binding in one place only, you can factorize it out of the constructor to a separate method if you want. The Roles can be rebound before another Interaction in the same Context occurs, which can be useful during recursion for example, but it must always happen in the same function.

### System Operations
We have just mentioned **Interactions**, which is the last part of the DCI acronym. An Interaction is a flow of messages through the Roles in a Context, like the one we have defined based on the mental model. To start an Interaction we need an entry point for the Context, a public method in other words. This is called a **System Operation**, and all it should do is to call a RoleMethod, so the Roles start interacting with each other.

There may be many System Operations in a Context, but in this case we only need one, so lets call it `transfer`. Avoid using a generic name like "execute", instead give your API meaning by letting every method name carry meaningful information.
```haxe
class MoneyTransfer implements haxedci.Context {
	public function new(source, destination, amount) {
		this.source = source;
		this.destination = destination;
		this.amount = amount;
	}

	public function transfer() {
		source.withdraw();
	}

	@role var source : {
		function decreaseBalance(a : Int) : Void;
	} =
	{
		function withdraw() : Void {
			self.decreaseBalance(amount);
			destination.deposit();
		}
	}

	@role var destination : {
		function increaseBalance(a : Int) : Void;
	} =
	{
		function deposit() : Void {
			self.increaseBalance(amount);
		}
	}

	@role var amount : Int;
}
```
With this System Operation as our entrypoint, the `MoneyTransfer` Context is ready for use! Let's create two accounts and the Context, and finally make the transfer:

#### Main.hx
```haxe
package ;

class Main {
	static function main() {
		var savings = new Account("Savings", 1000);
		var home = new Account("Home", 0);

		trace("Before transfer:");
		trace(savings.name + ": $" + savings.balance);
		trace(home.name + ": $" + home.balance);

		// Creating and executing the Context:
		new MoneyTransfer(savings, home, 500).transfer();

		trace("After transfer:");
		trace(savings.name + ": $" + savings.balance);
		trace(home.name + ": $" + home.balance);
	}
}
```

## Advantages
Ok, we have learned new concepts and a different way of structuring our program. But why should we do all this?

The advantage we get from using Roles and RoleMethods in a Context, is that we know exactly where our functionality is. It's not spread out in multiple classes anymore. When we talk about a "money transfer", we know exactly where in the code it is handled now. Another good thing is that we keep the code simple. No facades, design patterns or other abstractions, just the methods we need.

The Roles and their RoleMethods gives us a view of the Interaction between objects instead of their inner structure. This enables us to reason about *system* functionality, not just class functionality. In other words, DCI embodies true object-orientation where runtime Interactions between a network of objects in a particular Context is understood *and* coded as first class citizens.

We are using the terminology and mental model of the user. We can reason with non-programmers using their terminology, see the responsibility of each Role in the RoleMethods, and follow the mental model as specified within the Context.

DCI is a new paradigm, which forces the mind in different directions than the common OO-thinking. What we call object-orientation today is really class-orientation, since functionality is spread throughout classes, instead of contained in Roles which interact at runtime. When you use DCI to separate Data (RoleObjectContracts) from Function (RoleMethods), you get a beautiful system architecture as a result. No polymorphism, no intergalactic GOTOs (aka virtual methods), everything is kept where it should be, in Context!

## Next steps
Clone this repository or [download it](https://github.com/ciscoheat/haxedci-example/archive/master.zip), then open the [FlashDevelop](http://www.flashdevelop.org/) project file, or just execute run.bat (or the "run" script if you're on Linux), to see an advanced example in action:

* A much larger network of communicating objects
* Nested Contexts
* Bank Account transfers
* Restaurant visits
* An asynchronous DOS console
* ...and more!

A nice example of how well DCI maps to Use cases is found in the recreation of the classic Snake game, created with haxedci and Haxeflixel: [SnakeDCI](https://github.com/ciscoheat/SnakeDCI)

## DCI Resources
**Recommended:** [DCI – How to get ahead in system architecture](http://www.silexlabs.org/wwx2014-speech-andreas-soderlund-dci-how-to-get-ahead-in-system-architecture/) - My latest DCI speech.

Website - [fulloo.info](http://fulloo.info) <br>
FAQ - [DCI FAQ](http://fulloo.info/doku.php?id=faq) <br>
Support - [stackoverflow](http://stackoverflow.com/questions/tagged/dci), tagging the question with **dci** <br>
Discussions - [Object-composition](https://groups.google.com/forum/?fromgroups#!forum/object-composition) <br>
Wikipedia - [DCI entry](http://en.wikipedia.org/wiki/Data,_Context,_and_Interaction)

Good luck with DCI, and have fun!
