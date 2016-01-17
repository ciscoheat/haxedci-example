package dci.examples.matrix;
import dci.examples.matrix.Console.Process;
import dci.examples.matrix.Console.ProcessState;
import haxedci.Context;
import jQuery.Event;
import jQuery.Promise;
import jQuery.JQuery;
import jQuery.Deferred;
import haxe.Timer;

/**
 * A crude computer emulator, created to show how different mental models can
 * be mixed together with DCI.
 */

/**
 * RoleObjectInterface for a process. It has a start method, which should return
 * a Deferred that sends a progress message when the process is Running and input
 * should be accepted. Resolve the Deferred to terminate the process.
 *
 * Input should return a Promise that should be resolved when input has finished.
 */
typedef Process = {
	function start() : Deferred;
	function input(msg : String) : Promise;
}

enum ProcessState {
	Running;
	Blocked;
}

private class ProcessList extends List<Process>
{
	public var state : Map<Process, ProcessState>;

	public function new()
	{
		super();
		state = new Map<Process, ProcessState>();
	}
}

/**
 * The Console is a terminal emulator. It has a screen, an input device
 * and a list (stack) of processes that it will run. Sorry, no multi-tasking. ;)
 */
class Console implements Context
{
	public function new(screen, input)
	{
		this.screen = screen;
		this.input = input;
		this.processes = new ProcessList();
	}

	///// System Operations /////

	/**
	 * Initialize screen and input handlers.
	 */
	public function start() : Console
	{
		// Turn on screen
		screen.fadeTo(0, 0.25).fadeTo(6000, 1);

		// Initialize input
		input.keyup(input.sendMessage);
		input.focus();

		// Initialize screen
		screen.on('click', function(_) input.focus());

		return this;
	}

	public function clear() : Void
	{
		screen.clear();
	}

	public function getScreen() : Dynamic
	{
		return this.screen;
	}

	public function getInput() : Dynamic
	{
		return this.input;
	}

	public function load(process : Process) : Deferred
	{
		return processes.load(process);
	}

	public function output(msg : String, ?delay : Int, padding = 0) : Promise
	{
		return screen.type(msg, delay, padding);
	}

	public function newline(?delay : Int) : Promise
	{
		return screen.newline(delay);
	}

	public function turnOff() : Promise
	{
		var def = new Deferred();
		screen.fadeTo(3500, 0);
		input.fadeTo(3500, 0, function() def.resolve());
		return def;
	}

	///// Roles /////

	@role var processes : {
		var state : Map<Process, ProcessState>;
		function first() : Process;
		function push(process : Process) : Void;
		function pop() : Null<Process>;
	} =	{
		function current() : Process 
		{
			return self.first();
		}

		function read(s : String) : Void
		{
			if (!self.acceptsRead()) return;
			self.state[self.current()] = ProcessState.Blocked;
			self.current().input(s).done(function() self.state[self.current()] = ProcessState.Running);
		}

		function acceptsRead() : Bool {
			return self.current() != null && self.state[self.current()] == ProcessState.Running;
		}

		function load(process : Process) : Deferred
		{
			self.push(process);
			self.state[process] = ProcessState.Blocked;
			
			// Start the process and wait for the progress message.
			return process.start()
			.progress(function() {
				self.state[process] = ProcessState.Running;
				input.focus();
			})
			.done(function() {
				if (self.current() != process) throw "Error: Terminating process not executing!";
				self.state.remove(self.pop());
			});
		}
	}

	@role var input : {
		function keyup(cb : Event -> Void) : JQuery;
		function focus() : JQuery;
		function val(?value : String) : String;		
		function fadeTo(time : Int, ?opacity : Float, ?cb : Void -> Void) : JQuery;
	} =
	{
		function initialize() : Void {
			self.keyup(input.sendMessage);
			self.focus();
		}
		
		function setFocus(e : Event) : Void {
			self.focus();
		}
		
		function sendMessage(e : Event) : Void
		{
			if (e.which != 13) return;
			if (self.val() == "" || !processes.acceptsRead())
			{
				screen.flash();
				return;
			}

			var msg = self.val();
			self.val("");

			processes.read(msg);
		}
	}

	@role var screen : {
		function on(events : Dynamic, ?selector : String,  ?data : Dynamic) : JQuery;
		function fadeTo(time : Int, opacity : Float) : JQuery;
		function css(properties : Dynamic) : JQuery;
		function find(selector : String) : JQuery;
	} =
	{
		function turnOn() : Void {
			// Turn on screen
			self.fadeTo(0, 0.25).fadeTo(6000, 1);
			self.on('click', input.setFocus);
			
			input.initialize();
		}
		
		// Possible compiler bug with padding = 0
		function type(txt : String, ?delay : Int, ?padding : Int) : Promise
		{
			if(padding == null) padding = 0;
			var p = new Deferred();
			screen.typeString(txt, padding).then(Timer.delay.bind(p.resolve.bind(), delay));
			return p.promise();
		}

		function newline(?delay : Int) : Promise
		{
			return screen.type("", delay);
		}

		function flash() : Void
		{
			self.css({'background-color': '#ddd'});
			Timer.delay(function() self.css({'background-color': 'black'}), 50);
		}

		function clear() : Void
		{
			self.find('div.text').remove();
		}

		/**
		 * A bit more complicated RoleMethod, for simulating a human-like text output.
		 */
		function typeString(txt : String, padding : Int) : Promise
		{
			var lines = self.find('div.text').length;

			if (lines > 22)
				self.find('div.text:first').remove();

			var timeOut;
			var txtLen = txt.length;
			var char = 0;
			var typeIt = null;

			var def : Deferred = new Deferred();
			var el = new JQuery("<div class='text' />").css({'margin-left': padding + "px"}).appendTo(cast self);

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

					el.html(currentText + type + '|');

					if (char == txtLen)
					{
						el.html(currentText + type);
						def.resolve();
					}
					else
						typeIt();

				}, humanize);
			})();

			return def.promise();
		}
	}
}
