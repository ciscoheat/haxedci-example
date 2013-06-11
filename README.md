# DCI in Haxe
[Haxe](http://haxe.org) is a nice multiplatform language which in its third release (May 2013), enables a complete DCI implementation. This repository is a supplement to the [haxedci](https://github.com/ciscoheat/haxedci) library, giving a small introduction in this readme file, and having a larger example ready for download.

If you don't know what DCI is, go to [fulloo.info](http://fulloo.info) for documentation, details, overview and more. Or keep reading to scratch the surface a little.

## Short introduction
DCI stands for Data, Context, Interaction. One of the key aspects of DCI is to separate what a system *is* (form, class properties) from what it *does* (function, methods). Form and function has very different rates of change so they should be separated, not as it currently is, put in classes together.

A Context rounds up Data objects that take on the part as Roles, then an Interaction takes place as a flow of messages through the Roles. The Roles define a network of communicating objects and the Role methods force the objects to collaborate according to the distributed interaction algorithm.

## Simple example
A Hello World example is not too informative, since the power of DCI is shown when having a large number of communicating objects, but here it is anyway:

#### Greeter.hx
```actionscript
package ;
import dci.Context;

typedef ISomeone = String;
typedef IMessage = String;

class Greeter implements Context
{
    @role var someone : Someone;
	@role var message : Message;
	
	public function new(someone : ISomeone, message : IMessage)
	{
		this.someone = new Someone(someone);
		this.message = new Message(message);
	}
	
	public function greet()
	{
		trace(message + " " + someone.name() + "!");
	}
}

@:build(Dci.role(Greeter))
private abstract Someone(ISomeone)
{
	public function name()
	{
		return this;
	}
}

@:build(Dci.role(Greeter))
private abstract Message(IMessage)
{}
```

#### Main.hx
```actionscript
package ;

class Main 
{	
	static function main() 
	{
		new Greeter("world", "Hello").greet();
	}	
}
```
So what's going on here? There are three classes:

* Greeter
* Someone (abstract)
* Message (abstract)

The `Greeter` class is based on a mental model that **Someone** is being sent a **Message**. Note that these are the two other classes, and they are also present as Roles in the `Greeter` class. The exact name match is very important, because DCI is about mapping the end users mental model to code.

The mental model states that **Someone** has a name, so this will be indicated by a so-called *RoleMethod* in the `Someone` class. Naturally that method is called `Someone.name`.

The **Message** class is nothing more than its *RoleInterface*... What is that then? Look at the top of the file, there are two typedefs, `ISomeone` and `IMessage`. In this case they are simply strings, but for more complex roles they will specify a more advanced type (or form) required to play the Role. But in this simple case, they will be strings since nothing more is required of those objects.

To execute this `Greeter` Context, we use an *Interaction* to trigger it. As you see in Main.hx, it's a simple method invocation on the instantiated Context. Inside the interaction, the objects sent to the constructor now takes their Role as **Someone** and **Message**, and are outputted as a greeting.

Catching on the concept? Don't be put down if you think it's a lot to grasp. DCI is a whole new paradigm, which forces the mind in different directions than the normal OO-thinking.

## Next steps
Clone this repository or [download it](https://github.com/ciscoheat/haxedci-example/archive/master.zip), then open the [FlashDevelop](http://www.flashdevelop.org/) project file, or just execute run.bat (or the "run" script if you're on Linux), too see an advanced example in action:

* A much larger network of communicating objects
* Nested Contexts
* Bank Account transfers
* Restaurant visits
* An asynchronous DOS console
* ...and more! 
 
Then you can start looking at [fulloo.info](http://fulloo.info) for information, and if you need help you can ask on [stackoverflow](http://stackoverflow.com/questions/tagged/dci), tagging the question with **dci**. There is also a google group called [object-composition](https://groups.google.com/forum/?fromgroups#!forum/object-composition). Send me (ciscoheat) a message here on github or gmail if you like too, I'm happy to answer any questions when I have some time to spare.

Good luck, and have fun!!
