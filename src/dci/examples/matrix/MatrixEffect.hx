package dci.examples.matrix;

import haxe.Timer;
import haxedci.Context;
import jQuery.Deferred;
import jQuery.JQuery;
import jQuery.Promise;
using Lambda;

/**
 * Displaying the Matrix character effect in a jQuery object.
 * Roles:
 *   columns:   A list of the character columns
 *   screen:    The Console screen
 *   fontSize:  Character size in pixels
 *   positions: Available positions for the columns
 */
class MatrixEffect implements Context
{
	public function new(console, fontSize = 12)
	{
		bindRoles(console.getScreen(), fontSize);
	}

	private function bindRoles(screen, fontSize)
	{
		this.screen = screen;
		this.columns = new List<JQuery>();
		this.fontSize = fontSize;
		this.positions = new Array<Int>();

		// Create the list of positions for the columns.
		// (25 is offset from left of screen)
		var max = Math.floor((screen.width() - 25) / fontSize);

		while (positions.length < max)
			positions.push(positions.length * fontSize + 25);
	}

	///// System Operations /////

	public function start()
	{
		columns.addColumn();
		return this;
	}

	public function clear()
	{
		for (f in columns)
			f.fadeOut(1500, f.remove.bind());

		// Rebind roles to reset the effect.
		bindRoles(screen, fontSize);

		return this;
	}

	///// Roles /////

	@role var screen : JQuery;
	@role var fontSize : Int;
	@role var positions : Array<Int>;

	@role var columns : List<JQuery> =
	{
		function addColumn() : Void
		{
			if (positions.length > 0)
			{
				var pos = positions[Std.random(positions.length)];
				var el = new JQuery("<div />").css({
					"font-size": fontSize + "px",
					position: "absolute",
					width: fontSize + "px",
					margin: "2px",
					"word-wrap": "break-word",
					overflow: "hidden",
					height: screen.height() + 78 + "px",
					top: 0,
					left: pos + "px"
				}).appendTo(screen);

				positions.remove(pos);
				self.add(el);
			}

			self.moveDown();
		}

		function moveDown()
		{
			for (column in self)
			{
				var chars = column.find("span");
				var colors = ['#178f17', '#2e2', '#0f6b0f', '#2e2', '#91ff91'];

				var randomChar = function() return "&#" + (Std.random(5103 - 192) + 192) + ";";
				var randomColor = function() return colors[Std.random(colors.length)];

				// Because of Unicode some chars may not be displayed. Add 1.5 to ensure
				// the column reaches the bottom of the screen.
				if (chars.length < column.height() * 1.5 / fontSize)
				{
					// Remove the white color from the last char
					chars.filter(':last').css('color', randomColor());

					// Add a new white char at the end
					new JQuery("<span>" + randomChar() + "</span>")
					.css('height', fontSize + "px")
					.css('width', fontSize + "px")
					.css('color', 'white').appendTo(column);
				}

				// Randomize a char in the column sometimes
				if (Math.random() > 0.94)
				{
					chars.eq(Std.random(chars.length - 1))
					.html(randomChar())
					.css('color', randomColor());
				}
			}

			// Test if self is still bound to the context, then call start() again
			// to continue the effect.
			Timer.delay(function() if(self == this.columns) this.start(), 100);
		}
	}
}