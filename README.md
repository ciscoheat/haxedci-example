# DCI in Haxe
[Haxe](http://haxe.org) is a nice multiplatform language which in its third release (May 2013), enables a complete DCI implementation. This repository is a supplement to the [haxedci](https://github.com/ciscoheat/haxedci) library, giving a small introduction in this readme file, and having a larger example ready for download.

If you don't know what DCI is, go to [fulloo.info](http://fulloo.info) for documentation, details, overview and more. Or keep reading to scratch the surface a little.

## Short introduction
DCI stands for Data, Context, Interaction. One of the key aspects of DCI is to separate what a system *is* (data, class properties) from what it *does* (function, communication with other objects). Data and function has very different rates of change so they should be separated, not as it currently is in object-orientation, put together in classes.

The foundation is that a Context rounds up Data objects that take on the part as Roles, then an Interaction takes place as a flow of messages through the Roles. The Roles define a network of communicating objects and the Role methods force the objects to collaborate according to the distributed interaction algorithm.

## Hello World
A Hello World example is not too informative, since the power of DCI is shown when having a large number of communicating objects, but it can be useful to get familiar with the concepts, so here it is:

#### contexts/Greeting.hx
```actionscript
package contexts;
import dci.Context;

// RoleInterfaces
typedef ISomeone = {name: String};
typedef IMessage = String;

// Context
class Greeting implements Context
{
    // Roles (field name = type name camelCased)
    @role var someone : Someone;
	@role var message : Message;
	
	public function new(someone : ISomeone, message : IMessage)
	{
		this.someone = new Someone(someone);
		this.message = new Message(message);
	}
	
	// Interaction
	public function greet()
	{
		someone.greet();
	}
}

// Role
@:build(Dci.role(Greeting))
private abstract Someone(ISomeone)
{
	// RoleInterface implementation
	public function name() { return this.name; }
	
	// RoleMethod
	public function greet()
	{
        var c : Greeting = context;
		trace(c.message + " " + self.name() + "!");
	}
}

// Role
@:build(Dci.role(Greeting))
private abstract Message(IMessage)
{}
```

#### Main.hx
```actionscript
package ;
import contexts.Greeting

class Main 
{	
	static function main() 
	{
		new Greeting({name: "World"}, "Hello").greet();
	}	
}
```
So what's going on here? There are three classes:

* Greeting
* Someone (abstract)
* Message (abstract)

The `Greeting` class is a *Context*, based on a mental model that a Greeting is " **Someone** being sent a **Message** ". Note that these are the two other classes, and they are also present as *Roles* in the `Greeting` class. The exact name match is very important, because DCI is about mapping the end users mental model to code. (The haxedci library enforces that roles have the same field names (camelCased) in the Context class as the abstract class name.)

Let's look at the `Someone` class. It takes the `ISomeone` typedef as underlying type, which is called a *RoleInterface*. At the top of the file there are two typedefs, `ISomeone` and `IMessage`, specifying what is required to play each Role. The implementation is simple, just invoke and return the same method on `this`, since `this` is refering to the underlying object playing the Role. For **Message** it's even simpler since the Role has no methods to implement.

To execute this `Greeting` Context, we use an *Interaction* to trigger it. As you see in Main.hx, it's a simple method invocation on the instantiated Context. All the interaction does is kicking off a *RoleMethod*, where the Roles start communicating with each other. For doing this, there are two keywords: `context` and `self` injected in each RoleMethod. `context` is the current Context, where the Role has access to other roles for communication. `self` is a reference to the Role itself. Haxe is currently a bit too good in optimizing, so the type information is lost on `context`, hence the `var c : Greeting = context` declaration in the RoleMethod, to get autocompletion. The same can be done with `self` if required.

> **A note about "this":** It's not recommended to use `this` in RoleMethods, since it gives access to the whole underlying class, and we're only interested in what the Roles can do in the current Context. This is called "Full OO", a powerful concept that you can read more about [here](https://groups.google.com/d/msg/object-composition/umY_w1rXBEw/hyAF-jPgFn4J).

So when the Interaction is started, the objects passed to the Context constructor now takes on their Role as **Someone** and **Message**, and a greeting is sent to **Someone** as stated in the mental model. We're finished!

Catching on the concept? Don't be put down if it feels like a lot to grasp. DCI is a new paradigm, which forces the mind in different directions than the normal OO-thinking, which is really class-oriented when you think about it, since functionality are put in classes, not in Roles. DCI on the other hand is separating form (RoleInterfaces) from function (RoleMethods), which is a good mind-exercise, and a beautiful system architecture as a result! No polymorphism, no intergalactic GOTOs (or virtual methods as they are also called), everything is kept where it should, in Context.

## Next steps
Clone this repository or [download it](https://github.com/ciscoheat/haxedci-example/archive/master.zip), then open the [FlashDevelop](http://www.flashdevelop.org/) project file, or just execute run.bat (or the "run" script if you're on Linux), to see an advanced example in action:

* A much larger network of communicating objects
* Nested Contexts
* Bank Account transfers
* Restaurant visits
* An asynchronous DOS console
* ...and more!
 
Then you can start looking at [fulloo.info](http://fulloo.info) for information, and if you need help you can ask on [stackoverflow](http://stackoverflow.com/questions/tagged/dci), tagging the question with **dci**. There is also a google group called [object-composition](https://groups.google.com/forum/?fromgroups#!forum/object-composition) for lengthier discussions. 

A FAQ is started in the [wiki](https://github.com/ciscoheat/haxedci-example/wiki) of this repository, you can send me (ciscoheat) a message here on github or gmail if you have a question that you'd like me to include there.

Good luck with DCI, and have fun!!

(PS. Because of a limitation with the Haxe `@:allow` metadata, contexts must have a package, in case you're wondering about that in the Hello World example.)
