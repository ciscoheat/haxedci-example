import haxe.ds.Option;
import haxe.Timer;

/**
 *  An emulation of a RFID scanner.
 */
class RfidScanner implements HaxeContracts
{
	var detectRfid : Void -> Option<String>;
	var _onRfidChange : Option<String> -> Void;

	var currentValue : Null<String> = null;

	public function new(detectRfid, interval) {
		Contract.requires(interval > 0);

		this.detectRfid = detectRfid;
		setupTimer(interval);
	}

	public function registerSingleRfidChange(event : Option<String> -> Void) : Void {
		Contract.requires(event == null || _onRfidChange == null, "onRfidChange event already registered.");
		_onRfidChange = event;
	}

	function setupTimer(interval : Int) {
		var event = new Timer(interval);
		event.run = function() {
			if(_onRfidChange == null) return;
			switch detectRfid() {
				case Some(rfid):
					if(currentValue != rfid) {
						currentValue = rfid;
						var event = _onRfidChange;
						_onRfidChange = null;
						event(Some(rfid));
					}
				case None:
					if(currentValue != null) {
						currentValue = null;
						var event = _onRfidChange;
						_onRfidChange = null;
						event(None);
					}
			}
		}
	}

	@invariants function inv() {
		Contract.invariant(detectRfid != null);
	}
}