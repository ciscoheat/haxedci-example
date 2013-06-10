package dci.examples.contexts;
import jQuery.Promise;
import jQuery.JQuery;
import jQuery.Deferred;
import haxe.Timer;

typedef IScreen = JQuery;
typedef IInput = JQuery;
typedef IProcess = {
	function start() : Deferred;
	function input(msg : String) : Promise;
}
typedef IProcesses = List<IProcess>;

class Console implements Context
{
	@role var screen : Screen;
	@role var inputDev : Input;
	@role var processes : Processes;
	
	public function new(screen : IScreen, input : IInput)
	{
		this.screen = new Screen(screen);
		this.inputDev = new Input(input);
		this.processes = new Processes(new List<IProcess>());
		
		this.inputDev.sendInputToActiveProcess();		
		this.screen.on('click', function() { input.focus(); } );
	}
	
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
}

@:build(Dci.role(Console))
@:arrayAccess private abstract Processes(IProcesses) from IProcesses to IProcesses
{
	// Required for iteration of an abstract type:
	public var length(get, never) : Int;
	function get_length() return this.length;
	
	public function current() { return this.first(); }
	public function push(process : IProcess) { this.push(process); }	
	public function pop() { this.pop(); }
	
	public function start(process : IProcess) : Deferred
	{
		var c : Console = context;
		
		c.inputDev.isBusy(true);
		push(process);
		
		return process.start()
		.progress(function() {
			c.inputDev.isBusy(false);
			c.inputDev.focus();
		})
		.done(function() {
			this.pop();
			c.inputDev.isBusy(true);
		});
	}
	
	public function input(i : String)
	{
		var c : Console = context;
		var self = c.processes;
		var currentProcess = self.current();
		
		c.inputDev.isBusy(true);
		
		this.first().input(i).done(function() {
			// Check if still in same process
			if(self.current() == currentProcess)
				c.inputDev.isBusy(false);
		});
	}
}

@:build(Dci.role(Console))
private abstract Input(IInput)
{
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
			if (c.inputDev.isBusy())
				e.preventDefault();
		});
		
		this.keyup(function(e) 
		{
			if (e.which != 13 || c.inputDev.isBusy()) return;

			var msg = this.val();
			this.val("");
			
			c.processes.input(msg);
		});		
	}
	
	public function focus()
	{
		return this.focus();
	}
}

@:build(Dci.role(Console))
private abstract Screen(IScreen) from IScreen to IScreen
{
	public function on(events, ?selector, ?data)
	{
		return this.on(events, selector, data);
	}
	
	public function find(selector)
	{
		return this.find(selector);
	}
	
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