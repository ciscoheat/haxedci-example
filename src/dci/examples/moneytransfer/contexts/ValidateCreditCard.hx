package dci.examples.moneytransfer.contexts;
import haxedci.Context;

/**
 * Credit card validation using the Luhn algorithm:
 * https://en.wikipedia.org/wiki/Luhn_algorithm#Description
 *
 * Using two Roles, "digits" and "check digit", described in
 * the wikipedia page.
 */
class ValidateCreditCard implements Context
{
	public function new(number : Dynamic)
	{
		// Parse a string or a big integer to an array of ints
		var parsedNumber = [for (d in Std.string(number).split("")) Std.int(Std.parseInt(d))];

		// Assign Roles
		checkDigit = parsedNumber.pop();
		digits = parsedNumber;
	}

	public function isValid() : Bool
	{
		return digits.doubleEverySecondFromRight();
	}

	@role var checkDigit : Int =
	{
		function isValid() : Bool
		{
			var test = digits.sum() * 9;
			return Std.parseInt(Std.string(test).substr(-1)) == self;
		}
	}

	@role var digits : Array<Int> =
	{
		function doubleEverySecondFromRight() : Bool
		{
			var i = digits.length - 1;
			while (i >= 0)
			{
				digits[i] *= 2;

				if (digits[i] > 9)
					digits[i] = digits.sumDigitProduct(digits[i]);

				i -= 2;
			}
			
			
			// Mod 10 and check digit test
			return (digits.sum() + checkDigit) % 10 == 0 && checkDigit.isValid();
		}

		function sum() : Int return Lambda.fold(self, function(a, b) { return a + b; }, 0);
		function sumDigitProduct(i : Int) : Int return (i % 10) + 1;
	}
}