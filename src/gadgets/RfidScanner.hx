package gadgets;

import haxe.ds.Option;
import haxe.Timer;

/**
 *  An emulation of a RFID scanner.
 *  Uses a callback to test if an RFID string should be returned.
 *  
 *  Note that it uses the Option type, which is very useful to
 *  avoid null values.
 */
class RfidScanner implements HaxeContracts
{
	var returnRfid : Void -> Option<String>;
	var lastScanned : Option<String>;

	/**
	 *  Instantiates a RfidScanner object.
	 *  @param returnRfid - Scanning emulation function.
	 */
	public function new(returnRfid) {
		this.returnRfid = returnRfid;
		this.lastScanned = None;
	}

	/**
	 *  Registers a callback for a single rfid change event.
	 *  @param event - callback for the event.
	 */
	public function scanRfid(callback : Option<String> -> Void) : Void {
		Timer.delay(function() {
			var scanned = returnRfid();
			callback(scanned);
			lastScanned = scanned;
		}, 0);
	}

	/**
	 *  A convenience method, to avoid putting state elsewhere.
	 *  @return Option<String>
	 */
	public function lastScannedRfid() : Option<String> {
		return lastScanned;
	}

	@invariants function inv() {
		Contract.invariant(returnRfid != null);
		Contract.invariant(lastScanned != null);
	}
}