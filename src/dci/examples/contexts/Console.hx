package dci.examples.contexts;
import dci.Context;
import haxe.Timer;
import jQuery.Deferred;
import jQuery.JQuery;
import jQuery.Promise;
import js.html.Element;
import js.html.InputElement;
import js.Lib;

typedef IScreen = JQuery;
typedef IInput = JQuery;

class Console implements Context
{
	@role var screen : Screen;
	@role var inputDev : Input;
	
	var _inputMessage : Deferred;
	
	public function new(screen : IScreen, input : IInput, ?inputCallback : String -> Void)
	{
		this.screen = new Screen(screen);
		this.inputDev = new Input(input);
		this._inputMessage = new Deferred();
		
		this.inputDev.focus().keyup(function(e) 
		{
			if (e.which == 13) 
			{
				var def = this._inputMessage;
				var msg = this.inputDev.getVal();
				
				this.inputDev.setVal("");
				this._inputMessage = new Deferred();
				
				if (inputCallback != null)
					def = def.done(inputCallback);
				
				def.resolve(msg);
			}
		});		

		this.screen.on('click', function() { input.focus(); } );
	}
	
	public function output(msg : String, delay = 0) : Promise
	{
		return screen.type(msg, delay);
	}
	
	public function newline(delay = 0) : Promise
	{
		return screen.newline(delay);
	}
	
	public function input() : Promise
	{
		return this._inputMessage;
	}
}

@:build(Dci.role(Console))
private abstract Input(IInput) from IInput to IInput
{
	public function focus()
	{
		return this.focus();
	}

	public function setVal(v : String)
	{
		return this.val(v);
	}
	
	public function getVal()
	{
		return this.val();
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