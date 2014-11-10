package dci.examples.matrix;
import haxedci.Context;
import jQuery.Promise;
import jQuery.JQuery;
import jQuery.Deferred;
import haxe.Timer;

/**
 * A process has a start method, which should return a Deferred that
 * sends a "notify" message when input should be accepted.
 * Then it should resolve when the process finishes.
 */
typedef IProcess = {
	function start() : Deferred;
	function input(msg : String) : Promise;
}

typedef IProcesses = List<IProcess>;

/**
 * The Console is a terminal emulator. It has a screen, an input device
 * and a list (stack) of processes that it will run.
 */
class Console implements Context
{
	public function new(screen, input)
	{
		// Bind Roles
		this.screen = screen;
		this.input = input;
		this.processes = new List<IProcess>();

		// Setup input
		input.passToActiveProcess();
		screen.on('click', input.focus);
	}

	///// System Operations /////

	public function start(process : IProcess) : Deferred
	{
		return processes.start(process);
	}

	public function output(msg : String, ?delay : Int) : Promise
	{
		return screen.type(msg, delay);
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

	@role var screen : JQuery =
	{
		function type(txt : String, ?delay : Int) : Promise
		{
			var p = new Deferred();
			self.typeString(txt).then(Timer.delay.bind(function() p.resolve(), delay));
			return p.promise();
		}

		function newline(?delay : Int) : Promise
		{
			return self.type("", delay);
		}

		function typeString(txt : String) : Promise
		{
			var lines = self.find('div').length;

			if (lines > 22)
				self.find('div:first').remove();

			var timeOut;
			var txtLen = txt.length;
			var char = 0;
			var typeIt = null;

			var def : Deferred = new Deferred();
			var el = new JQuery("<div />").appendTo(self);

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

	@role var input : JQuery =
	{
		function isBusy(?state : Bool) : Bool
		{
			if (state == null)
			{
				var busy = self.data("busy");
				return busy == null ? true : busy;
			}
			else
			{
				self.data("busy", state);
				return state;
			}
		}

		function passToActiveProcess() : Void
		{
			self.keydown(function(e) {
				if (input.isBusy()) e.preventDefault();
			});

			self.keyup(function(e) {
				if (e.which != 13 || input.isBusy()) return;

				var msg = self.val();
				self.val("");

				processes.input(msg);
			});
		}
	}

	@role var processes : List<IProcess> =
	{
		function start(process : IProcess) : Deferred
		{
			input.isBusy(true);
			self.push(process);

			return process.start()
			.progress(function() {
				input.isBusy(false);
				input.focus();
			})
			.done(function() {
				self.pop();
				input.isBusy(true);
			});
		}

		function current() return self.first();

		function input(i : String) : Void
		{
			var currentProcess = self.current();

			input.isBusy(true);

			self.current().input(i).done(function() {
				// Release input if still in same process
				// if not, wait for new process to release it.
				if(self.current() == currentProcess)
					input.isBusy(false);
			});
		}
	}
}
