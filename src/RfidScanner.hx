import haxe.ds.Option;
import haxe.Timer;

/**
 *  An emulation of a RFID scanner.
 */
class RfidScanner implements HaxeContracts
{
	var detectRfid : Void -> Option<String>;
	var _onRfidChange : Option<String> -> Void;

	/**
	 *  Instantiates a RfidScanner object.
	 *  @param detectRfid - Scanning function, should return Option<String>.
	 *  @param interval - Interval in ms between scans.
	 */
	public function new(detectRfid, interval) {
		Contract.requires(interval > 0);

		this.detectRfid = detectRfid;
		setupTimer(interval);
	}

	/**
	 *  Registers a callback for a single rfid change event.
	 *  @param event - callback for the event. Pass null to disable last registration.
	 */
	public function registerSingleRfidChange(event : Option<String> -> Void) : Void {
		Contract.requires(event == null || _onRfidChange == null, "RFID change event already registered.");
		_onRfidChange = event;
	}

	function setupTimer(interval : Int) {
		var event = new Timer(interval);
		event.run = function() {
			if(_onRfidChange == null) return;
			switch detectRfid() {
				case Some(rfid):
					var event = _onRfidChange;
					_onRfidChange = null;
					event(Some(rfid));
				case None:
					var event = _onRfidChange;
					_onRfidChange = null;
					event(None);
			}
		}
	}

	@invariants function inv() {
		Contract.invariant(detectRfid != null);
	}
}