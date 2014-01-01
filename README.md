# DCI in Haxe
[Haxe](http://haxe.org) is a nice multiplatform language which in its third release (May 2013), enables a complete DCI implementation. This repository is a supplement to the [haxedci](https://github.com/ciscoheat/haxedci) library, giving a small introduction in this readme file, and having a larger example ready for download.

If you don't know what DCI is, go to [fulloo.info](http://fulloo.info) for documentation, details, overview and more. Or keep reading to scratch the surface a little.

## Short introduction
DCI stands for Data, Context, Interaction. One of the key aspects of DCI is to separate what a system *is* (form, class properties) from what it *does* (function, methods). Form and function has very different rates of change so they should be separated, not as it currently is, put in classes together.

## Hello World
A Hello World example is not too informative, since the power of DCI is shown when having a large number of communicating objects, but it can be useful to get familiar with the concepts, so here it is:

#### Greeting.hx
```actionscript
package;

// Greeting: Someone is being greeted with a message.
class Greeting implements dci.Context
{
	@role var someone =
	{
		var roleInterface : {
			var name : String;
		}
		
		function greet()
		{
			trace(message + " " + self.name + "!");
		}
	}
	
	@role var message : String;
	
	public function new(someone, message)
	{
		this.someone = someone;
		this.message = message;
	}
	
	// Interaction
	public function greet()
	{
		someone.greet();
	}
}
```

#### Main.hx
```actionscript
package ;

class Main 
{	
	static function main() 
	{
		new Greeting({name: "World"}, "Hello").greet();
	}	
}
```
The `Greeting` class is a *Context*, based on the idea that a Greeting is " **someone** being greeted with a **message** ". Someone and message are present as *Roles* in the `Greeting` class. The name match is important, because DCI is about mapping the end users mental model to code. We want to use the terms that matters to the user.

Let's look at the `someone` Role. First it has a *RoleInterface*, which describes the required fields for any object to play this Role. In this case, a name is needed to be greeted. Then we have a *RoleMethod* called `greet`. A RoleMethod is a function defined in a Role, which will be attached to the object playing the Role when the object is executing within the Context. But only within, because the RoleMethods are only meaningful within a Context. The `message` Role is even simpler since it has no methods to implement, so you can just specify a Type and it will become its RoleInterface.

## Defining a RoleInterface

There are a couple of ways of defining a Role and its RoleInterface. You have probably noticed already that the variable has to be named `roleInterface`.

[Haxe class notation](http://haxe.org/manual/struct#class-notation) is useful for class methods:
```actionscript
var roleInterface : {
	var x(default, null) : Int;
	var y : Int;
	function add( p : Point ) : Void;
}
```

Or if you want to specify a single Type for the Role:
```actionscript
var roleInterface : Array<String>;
```

The latter way can be tempting because it's quick and you'll get the full "API" of a class, but a nice thing with specifying a more exact RoleInterface is that we're only interested in what the Roles can do in the current Context. This is called "Full OO", a powerful concept that you can [read more about here](https://groups.google.com/d/msg/object-composition/umY_w1rXBEw/hyAF-jPgFn4J).

## Executing the Context

To execute our `Greeting` Context, we use an *Interaction* to trigger it. As you see in Main.hx, it's only a method invocation on the instantiated Context. The only thing the Interaction should do is to kick off a RoleMethod, so the Roles start communicating with each other. 

In the `greet` RoleMethod, the `someone` role is accessed using `self`, which always points to the current Role. `this` points to the Context in RoleMethods.

The advantage we get from using Roles, RoleMethods and even a Context, is that we know exactly where our functionality is. It's not spread out in multiple classes anymore. When we talk about "a greeting", we know exactly where in the code it is handled now. Another thing is that we keep the code simple. No facades or other abstractions, just the methods we need, automatically added to the objects playing a Role in the Context.

## Interaction sequence

What happens during an interaction? In this case, when it is started, the objects passed to the Context constructor now takes on their Role as **someone** and **message**, and a greeting is sent to **someone** as stated in the mental model. That's all that happens in this simple example, but a larger Context will have many Roles communicating over many RoleMethods, similar to a [sequence diagram](http://en.wikipedia.org/wiki/Sequence_diagram). In essence, the Context rounds up Data objects that take on the part as Roles, then an Interaction takes place as a flow of messages through the Roles. The Roles define a network of communicating objects and the Role methods force the objects to collaborate according to the distributed interaction algorithm.

When designing the RoleMethods, be careful not to end up with one big method doing all the work. That is an imperative approach which limits the power of DCI, since we're aiming for communication between Roles, not a procedural algorithm that tells the Roles what to do. Make the methods small, and let the mental model of the Context become the guideline. A [Use case](http://www.usability.gov/how-to-and-tools/methods/use-cases.html) is a formalization of a mental model that is supposed to map to a Context in DCI.

Catching on the concept? Don't be put down if it feels like a lot to grasp. DCI is a new paradigm, which forces the mind in different directions than the normal OO-thinking, which is really class-oriented when you think about it, since functionality are spread out in classes, not in Roles. DCI on the other hand is separating data (RoleInterfaces) from function (RoleMethods), which is a good mind-exercise, and a beautiful system architecture as a result! No polymorphism, no intergalactic GOTOs (or virtual methods as they are also called), everything is kept where it should, in Context.

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
