package dci.examples.matrix;
import jQuery.Promise;
import jQuery.JQuery;
import jQuery.Deferred;
import haxe.Timer;

// RoleInterfaces

typedef IScreen = JQuery;
typedef IInput = JQuery;

typedef IProcess = {
	function start() : Deferred;
	function input(msg : String) : Promise;
}

typedef IProcesses = List<IProcess>;

class Console implements Context
{
	// Roles in a Context are annotated with the @role metadata.
	@role var screen : Screen;
	@role var input : Input;
	@role var processes : Processes;
	
	public function new(screen : IScreen, input : IInput)
	{
		this.screen = new Screen(screen);
		this.input = new Input(input);
		this.processes = new Processes(new List<IProcess>());
		
		this.input.sendInputToActiveProcess();		
		this.screen.on('click', function() { input.focus(); } );
	}
	
	// Interactions
	
	public function start(process : IProcess) : Deferred
	{
		return processes.start(process);
	}
	
	public function output(msg : String, delay = 0) : Promise
	{
		return screen.type(msg, delay);
	}
	
	public function newline(delay = 0) : Promise
	{
		return screen.newline(delay);
	}
	
	public function turnOff() : Promise
	{
		var def = new Deferred();
		screen.fadeTo(3500, 0);
		input.fadeTo(3500, 0, function() { def.resolve(); });
		return def;
	}
}

// A Role is using the @:build macro for Dci.role() with the Context type as argument.
// It should be a private abstract class that uses its RoleInterface.

@:build(Dci.role(Console))
@:arrayAccess private abstract Processes(IProcesses) from IProcesses to IProcesses
{
	// Implementing the RoleInterface, the form required for an object to play this Role.
	public function current() { return this.first(); }
	public function push(process : IProcess) { this.push(process); }	
	public function pop() { this.pop(); }
	
	// RoleMethods, implementing the functionality.
	public function start(process : IProcess) : Deferred
	{
		// Current Context is accessed with the 'context' identifier.
		var c : Console = context;
		
		c.input.isBusy(true);
		push(process);
		
		return process.start()
		.progress(function() {
			c.input.isBusy(false);
			c.input.focus();
		})
		.done(function() {
			this.pop();
			c.input.isBusy(true);
		});
	}
	
	public function input(i : String)
	{
		var c : Console = context;		
		var currentProcess = self.current();
		
		c.input.isBusy(true);
		
		this.first().input(i).done(function() {
			// Check if still in same process
			if(self.current() == currentProcess)
				c.input.isBusy(false);
		});
	}
}

@:build(Dci.role(Console))
private abstract Input(IInput)
{
	// RoleInterface (form)
	public function focus() { return this.focus(); }
	public function fadeTo(duration : Dynamic, opacity : Int, ?complete : Void -> Void) { return this.fadeTo(duration, opacity, complete); }

	// RoleMethods (function)
	
	public function isBusy(?state : Bool)
	{
		if (state == null) 
		{
			var busy = this.data("busy");
			return busy == null ? true : busy;
		}
		else
		{
			this.data("busy", state);
			return state;
		}	
	}
	
	public function sendInputToActiveProcess()
	{
		var c : Console = context;
		
		this.keydown(function(e) {
			if (c.input.isBusy())
				e.preventDefault();
		});
		
		this.keyup(function(e) 
		{
			if (e.which != 13 || c.input.isBusy()) return;

			var msg = this.val();
			this.val("");
			
			c.processes.input(msg);
		});		
	}	
}

@:build(Dci.role(Console))
private abstract Screen(IScreen) from IScreen to IScreen
{
	// RoleInterface	
	public function on(events, ?selector, ?data) { return this.on(events, selector, data); }
	public function find(selector) { return this.find(selector); }
	public function fadeTo(duration : Dynamic, opacity : Int, ?complete : Void -> Void) { return this.fadeTo(duration, opacity, complete); }
	
	// RoleMethods
	
	public function type(txt : String, delay = 0) : Promise
	{
		var p = new Deferred();
		typeString(txt).then(function() { Timer.delay(function() { p.resolve(); }, delay); } );
		return p.promise();
	}
	
	public function newline(delay = 0) : Promise
	{
		return type("", delay);
	}
	
	function typeString(txt : String) : Promise
	{
		var lines = this.find('div').length;
		
		if (lines > 22)
			this.find('div:first').remove();
		
		var timeOut;
		var txtLen = txt.length;
		var char = 0;
		var typeIt = null;
		
		var def : Deferred = new Deferred();		
		var el = new JQuery("<div />").appendTo(this);
		
		if (txt.length == 0) 
		{
			el.html("&nbsp;");
			return def.resolve().promise();
		}
		
		(typeIt = function() 
		{
			var humanize = Math.round(Math.random() * (50 - 30)) + 30;
			timeOut = Timer.delay(function() 
			{
				var type = txt.substr(char++, 1);
				var currentText = el.text().substr(0, el.text().length - 1);
				
				el.text(currentText + type + '|');

				if (char == txtLen) 
				{
					el.text(currentText + type);
					def.resolve();
				}
				else
				{
					typeIt();
				}

			}, humanize);
		})();
		
		return def.promise();
	}	
}