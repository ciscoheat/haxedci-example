# DCI in Haxe

[Haxe](http://haxe.org) is a nice multiplatform language which enables a full compile-time DCI implementation. This repository is a supplement to the [haxedci](https://github.com/ciscoheat/haxedci) library. For an introduction to DCI, as well as for understanding the library usage, take a look at it first, then this larger example will make much more sense.

# Short introduction

DCI stands for Data, Context, Interaction. The key aspects of the DCI architecture are:

- Separating what the system *is* (data) from what it *does* (function). Data and function have different rates of change so they should be separated, not as it currently is, put in classes together.
- Create a direct mapping from the user's mental model to code. The computer should think as the user, not the other way around, and the code should reflect that.
- Make system behavior a first class entity.
- Great code readability with no surprises at runtime.

# The example: A Library borrowing machine

This repo contains an example of how to use DCI together with MVC to model an automatic library borrowing machine. I'm sure you're eager to see what it looks like, so here's a demo:

**Demo:** https://ciscoheat.github.io/haxedci

Notable about this example is that it is based on [this use case](https://docs.google.com/spreadsheets/d/1TSpjKUhjvP9pMRukt_mInHVbdQWsXHzFjSymQ3VyGmE/edit#gid=2), which then maps as close as possible to code using a DCI Context.

The Context is called `LibraryBorrowingMachine`, and it's recommended to have [the source code]() in a window next to this document from now on.

The first thing we see in the Context is some state. In larger Contexts, and especially in more interactive ones like this library machine, some state could be required to support the functionality, by containing details the use case doesn't concern itself about. It is recommended to keep it minimal and private.

Then we have the constructor, doing the simplest possible role binding. Note that Haxe allows Role assignment to the `Data` class, enabling static fields to take part in Contexts. Pretty nice for this example, creating easy access to the database.

The last public part of the Context is the System Interactions, consisting of methods that kicks off the interaction between the Roles. There is one, simply called `start`. There is another, private one called `restart`, used at the end of the use case.

## Reading the code

Again, a primary goal of DCI is readable code, so take your time to read the code in `start`. The RoleMethods, being modelled after the use case that anyone involved should understand, lets you understand what will happen, so you can either skim past obvious things, like `screen.displayWelcome`, or dive into that specific part of the Context.

At the end of the method you'll have to dive in anyway, because the interaction is distributed between the Roles. This is closely connected to how human beings reason about objects. The `cardReader` *does* things, to further the goal of the Context: Enabling the user to borrow library items.

In this case it should wait for a card change. So lets scroll down to the `cardReader` role and its RoleMethod.

As you see, the `cardReader` calls itself, using its contract method, asking it to scan for an RFID, and call `self.rfidScanned`, another RoleMethod, when it's done.

Using the convenient [Option](http://api.haxe.org/haxe/ds/Option.html) type, we can switch on the result without messing with null references. So if nothing is found, we keep waiting. Otherwise, well, hopefully the code is simple enough to follow and understand. Note how local it is. The `scanRfid` is similar to an interface (though duck-typed), but you can see it directly in the code, no need to look up its definition in another file.

## Role explanation

- `cardReader` interacts with `keypad` and `screen` to authorize the PIN for a library card. Then passes control to
- `scanner` that scans RFID on library items, adding them to 
- `scannedItems` which is a list of what the user has borrowed so far.
- `screen` is a MVC View, used by the other Roles to display what's happening.
- `finishButtons` is technically not a part of the Context as a Role, but since there is a close mapping of the *"Borrower indicates that ..."* part in the use case, they are included as a Role.
- `keypad` is just managing an event, but notable since it's played by the same object as `screen`, because the screen is a touch screen that displays a keypad. This shows the flexibility of a Context. If we would switch to a physical keypad for example, is not much work.
- `printer` prints the receipt of borrowed items, as a final action.
- `library` is for database access, so the RFID can be verified. Note that even though the Role-object-contract specifies an `Array`, we have a quite convenient API to it, using the `item` and `card` RoleMethods. Writing those useful RoleMethods is a pleasure, because they are usually already specified in the use case, in user-understandable terms, and the code becomes so much more readable.

## Other parts of the program



# DCI Resources

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
