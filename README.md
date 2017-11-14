# DCI in Haxe

[Haxe](http://haxe.org) is a nice multiplatform language which enables a full compile-time DCI implementation. This repository is a supplement to the [haxedci](https://github.com/ciscoheat/haxedci) library. For an introduction to DCI, as well as for understanding the library usage, take a look at it first, then this larger example will make much more sense.

# Short introduction

DCI stands for Data, Context, Interaction. The key aspects of the DCI architecture are:

- Separating what the system *is* (data) from what it *does* (function). Data and function have different rates of change so they should be separated, not as it currently is, put in classes together.
- Create a direct mapping from the user's mental model to code. The computer should think as the user, not the other way around, and the code should reflect that.
- Make system behavior a first class entity.
- Great code readability with no surprises at runtime.

# The example: A Library borrow machine

This repo contains an example of how to use DCI together with MVC to model an automatic library borrowing machine. I'm sure you're eager to see what it looks like, so here's a demo:

**Demo:** [https://ciscoheat.github.io/haxedci](https://ciscoheat.github.io/haxedci) (PIN code is 1234. Source maps included.)

This example is based on [this use case](https://docs.google.com/spreadsheets/d/1TSpjKUhjvP9pMRukt_mInHVbdQWsXHzFjSymQ3VyGmE/edit#gid=2), which then maps as close as possible to code using DCI Contexts.

The main Context is called `LibraryBorrowMachine`, which we will go through now. Please open [its source code](https://github.com/ciscoheat/haxedci-example/blob/master/src/contexts/LibraryBorrowMachine.hx) in a window next to this document now, so you can follow along.

The first thing we see in the Context is some state. In larger Contexts, and especially in interactive ones like this library machine, some state can be required to support the functionality, containing details the use case doesn't concern itself about. It is recommended to keep it to a minimum, since state can usually be calculated instead, based on the data.

After the constructor, doing a simple role binding, we have the System Operations, methods that kicks off the Interaction between the Roles. Usually there is only one entry point, in this case simply called `start`. Another, private one, is called `restart`, used at the end of the use case.

## Reading the code

One of the primary goals of DCI is readable code, so lets take a look at the `start` method: 

```haxe
public function start() {
    resetState();
    screen.displayWelcome();
    cardReader.waitForCardChange();
}
```

After the Context has reset its state, it starts calling the RoleMethods, based on the use case that anyone involved in the project should understand, closing the gap between users, stakeholders and programmers.

Clearly named RoleMethods lets you grasp what will happen, so you can either skim past obvious things, like `screen.displayWelcome`, or dive into a specific part of the Context. At the end of a method you'll have to dive in anyway, since the interaction is distributed between the Roles. This is closely connected to how human beings reason about objects. A `cardReader` *does* things, to further the goal of the Context, which is to enable the user to borrow library items. It asks for help from other objects to reach the goal. It passes along some information to another object. And so on, until the problem is solved.

In this case it should wait for a card change. So lets scroll down a little bit to the `cardReader` Role and its `waitForCardChange` RoleMethod:

```haxe
public function waitForCardChange()
    self.scanRfid(self.rfidScanned);
```

The `cardReader` calls itself there, using its contract method `scanRfid`, asking it to scan for a RFID, then call `self.rfidScanned` when it's done:

```haxe
function rfidScanned(data : Option<String>) switch data {
    case None:
        // No card, keep waiting
        self.waitForCardChange();

    case Some(rfid):
    	// ...
}
```

`rfidScanned` is a private RoleMethod, meaning that only the `cardReader` can call it. It's useful in this case since `rfidScanned` is a continuation of `waitForCardChange`, that no other Role should call.

Using the convenient [Option](http://api.haxe.org/haxe/ds/Option.html) type, we can switch on the result, avoiding null references. So if nothing is found, we keep waiting. Otherwise, well, hopefully the code is simple enough to follow and understand.

Notice how local the code is. The `scanRfid` method is similar to an interface definition (though duck-typed in this case), but you can see it directly in the Context, no need to look up its definition in another file. With DCI we want to focus on objects and Roles, not classes.

Also notice how rare it is for a RoleMethod to return something. The Roles interact more through message passing than the old procedural approach with return values. This makes the system more object-oriented, and it also becomes easier to "rewire" the Context when the functionality evolves. Return values have a tendency to centralize the algorithm, eventually losing the idea of "who does what", which is important for building a mental model of the problem we're trying to solve.

## Role explanations

**cardReader**

Interacts with **keypad** and **screen** to authorize the PIN for a library card. Then passes control to:

**scanner**

That scans RFID on library items, adding them to:

**scannedItems**

Which is a list of what the user has borrowed so far.

**screen** 

Is used by the other Roles to display what's happening. Played by an MVC View object in this example.

**finishButtons** 

Is technically not a part of the Context as a Role, but since there is a close mapping of the *"Borrower indicates that borrowing is finished..."* part in the use case, they are included as a Role. This is an example of how the use case level and detail makes it difficult to create a perfect match between itself and the code.

**keypad** 

Is a simple event handling Role, but notable since it's played by the same object as **screen**, because the screen is a touch screen that displays a keypad. This shows the flexibility of a Context. If we would switch to a physical keypad for example, it's not much work to hook it in.

**printer** 

Prints the receipt of borrowed items, as a final action.

**library** 

Allows database access, so the RFID:s can be verified. Note that even though the Role-object-contract specifies an `Array`, we have a quite convenient API to it inside the Context, using the `item` and `card` RoleMethods. Writing those RoleMethods is a pleasure, because they are usually well defined in the use case, in user-understandable terms, and the code becomes so much more readable.

Of course, in a real situation the contract would be made for the actual database driver, not arrays. The `item` and `card` RoleMethods would stay the same though.

Note how the Roles are reflected in the use case, interacting to solve the specified problem.

## Other parts of the system

The DCI Context describes a network of communicating objects, making *system behavior* a first-class entity, for the first time in computer history. It requires support from other objects however, mainly domain objects in the form of simple and solid Data classes. The [Data.hx](https://github.com/ciscoheat/haxedci-example/blob/master/src/Data.hx) module contains the Data we're using in the Library borrowing machine. Open it up next to this document.

### Data.hx

As you see, the underlying data for the Context is so simple that it requires almost no explanation. An interesting thing is that the user doesn't really concern itself about `Book` and `Bluray` in the Context. Since the goal is to borrow any interesting items found at the library, the `LoanItem` interface is closer to how the user thinks about those items.

This moves us closer to a better use for interfaces, compared to the endless levels of abstractions created by the engineers, partitioning the system in a very improper way compared to Contexts, which encapsulates actual system functionality. With DCI we get a clean separation between the actual domain objects (data), and its behavior (context).

### Main.hx

Maybe it's time to see how the system is created and started? [Main.hx](https://github.com/ciscoheat/haxedci-example/blob/master/src/Main.hx) contains the entry point. It fills the `Data` class with the above mentioned data objects, then proceeds to create the objects used in the `LibraryBorrowMachine` Context. There are also a few simple "gadgets", simulations of the physical objects used in the real machine, and some MVC View objects.

After the `MainView` object is created to display everything in the browser, the Contexts are instantiated and their respective System Operation is called. This is an important part of understanding DCI. Inside the Context we will think of what the objects will do, not what they are.

```haxe
// The scanner is a RfidScanner
var scanner = new gadgets.RfidScanner(...);

// The cardReader is also a RfidScanner
var cardReader = new gadgets.RfidScanner(...);

// The screen is a MVC View
var screen = new views.ScreenView();

// The keypad is the same object as the one playing the screen Role
var keypad = screen;

// The "finish with/without receipt buttons" also
var finishButtons = screen;

// The printer is a simulation, not a real one
var printer = new gadgets.ReceiptPrinter();

// Inside the Context, we don't care what those objects really are, only what they
// can do, and how they interact to reach the goal of the Context.
new LibraryBorrowMachine(scanner, cardReader, screen, printer, keypad, finishButtons).start();
```

Before instantiating a Context, the system consisted only of this simple, inactive data, but now it comes to life through the functionality specified in the Context!

### Together with MVC

DCI and MVC complements each other, and if you've read my [Rediscovering MVC](https://github.com/ciscoheat/mithril-hx/wiki/Rediscovering-MVC) article, you know that an object can be any combination of M, V and C. 

There are only two View objects in this app, in the [src/views](https://github.com/ciscoheat/haxedci-example/tree/master/src/views) folder, which could sound a bit constrained if you're used to the usual "decoupling at any cost" way of designing MVC applications. This decoupling doesn't make much sense though, after Rediscovering MVC. Instead of thinking of every Role in the `LibraryBorrowMachine` Context as a separate View, we simply want to maintain the illusion that the user is directly manipulating the data, or the Model as it's called in MVC, bridging the gap between the human mental Model and the digital Model.

Also note that in the Views, we (or actually, the users of the app) are *thinking* about the Data. In the `LibraryBorrowMachine` the user is *doing* things, turning `Bluray` and `Book` into a `LoanItem`. But not when simply viewing and thinking about the Data. When there is no ongoing functionality, things become what they are. Thinking is MVC, doing is DCI.

So back to upholding that illusion. It's done by a `MainView`, which is not a part of a Context and therefore we're viewing the data directly. A drag'n'drop library supports the real-time manipulation, but then we're back in functionality again, and if you look at [DragDropMechanics.hx](https://github.com/ciscoheat/haxedci-example/blob/master/src/contexts/DragDropMechanics.hx), you can see that the focus is now on `DragDropItem` and surfaces, not books and Blu-Rays.

The other view is `ScreenView`, which was distinct and intricate enough, containing events for keypad and finish buttons, and nine display states, to be separated into its own View. That kind of reasoning should be the basis for decoupling, not seeing it as a rule or standard. And when the screen takes part in the `LibraryBorrowMachine` Context, you can see that `ScannedItem` is used, an interface, not exactly what object was scanned.

The javascript framework [Mithril](http://mithril.js.org/) is used to display the app, and I'm giving it my highest recommendation since it keeps itself in the background, so the focus can be on the architecture, not the structure imposed by frameworks in general. Using it with Haxe is very simple with [mithril-hx](https://github.com/ciscoheat/mithril-hx).

### Nested Contexts

In [LibraryBorrowMachine.hx](https://github.com/ciscoheat/haxedci-example/blob/master/src/contexts/LibraryBorrowMachine.hx), `scanner.rfidScanned`, there is a call to a [BorrowLoanItem.hx](https://github.com/ciscoheat/haxedci-example/blob/master/src/contexts/BorrowLoanItem.hx) Context, which contains the functionality for borrowing a single `LoanItem`.

A Context inside another is called a Nested Context, an important concept since it's finally about slicing behaviour in the right layers; where it makes sense to the user, instead of the current state of affairs, behaviour being sliced and spread out in classes and behind abstractions, decided by, again, engineers who prefers structure and patterns rather than a user-focused archictecture.

### Event handling

Events are quite disruptive to the interaction in a Context. They are similar to a GOTO, you can end up anywhere in the program when an event is triggered, even outside the Context, which goes against the readability goal of DCI.

Therefore it's preferred to keep as few active event handlers as possible, ideally only registering an event handler when it's supposed to be used in the Context, and removing it directly afterwards, so they become a part of the message flow, moving the mindset from "set and forget" (which can become "plug and pray"), to a more explicit event management.

The `lib` folder contains a `SingleEventHandler` class that manages this for you. It's not as powerful as a Promise, but for simple events with little error handling, it works quite well. [ScreenView.hx](https://github.com/ciscoheat/haxedci-example/blob/master/src/views/ScreenView.hx) is using it, if you want to see how it's done.

## Final notes

I've taken a small liberty putting `DragDropFunctionality` in the `contexts` folder even though it's not a real DCI Context. It does a good job encapsulating functionality however, so I'm trying to show that being a bit flexible can help the architecture of a system.

I have plans for a more interactive debugging experience, but for now I hope you will explore the rest of the code and moving on to building it yourself!

# Building the example

After installing [Haxe](https://haxe.org) and cloning this repo (or [downloading the ZIP](https://github.com/ciscoheat/haxedci-example/archive/master.zip)), the build process is very simple:

`haxe haxedci-example.hxml`

This compiles the example to the `bin` folder, ready to run in the browser with the `bin/index.html` file.

For the best possible dev experience however, [Node.js](https://nodejs.org/) together with either [Visual Studio Code](https://code.visualstudio.com/), [Haxedevelop](http://haxedevelop.org/) or [Sublime](https://www.sublimetext.com/) is highly recommended. Project files are available for all of those editors.

Node is used only as a build tool, so as a first step, run `npm run dependencies` to install some npm packages. Then simply run `npm start`, to start a web server that live reloads as soon as you change a file or recompile the source. The server is available at [localhost:8080](http://localhost:8080/).

Thanks for reading! If you have ideas, thoughts, anything, just open up an issue. Finishing with some useful resources, since this is just a little dip into DCI.

# Resources

## Videos 

['A Glimpse of Trygve: From Class-oriented Programming to Real OO' - Jim Coplien [ ACCU 2016 ]](https://www.youtube.com/watch?v=lQQ_CahFVzw)

[DCI – How to get ahead in system architecture](http://www.silexlabs.org/wwx2014-speech-andreas-soderlund-dci-how-to-get-ahead-in-system-architecture/)

## Links

Website - [fulloo.info](http://fulloo.info) <br>
FAQ - [DCI FAQ](http://fulloo.info/doku.php?id=faq) <br>
Support - [stackoverflow](http://stackoverflow.com/questions/tagged/dci), tagging the question with **dci** <br>
Discussions - [Object-composition](https://groups.google.com/forum/?fromgroups#!forum/object-composition) <br>
Wikipedia - [DCI entry](http://en.wikipedia.org/wiki/Data,_Context,_and_Interaction)

Good luck with DCI, and have fun!
