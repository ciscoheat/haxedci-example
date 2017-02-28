import haxe.ds.Option;
import haxe.Timer;

/**
 *  An emulation of a RFID scanner.
 */
class RfidScanner implements HaxeContracts
{
	var detectRfid : Void -> Option<String>;
	var onRfidChange : Option<String> -> Void;

	var currentEvent : Option<Timer> = None;
	var currentValue : Null<String> = null;

	/**
	 *  @param detectRfid - RFID detection method.
	 *  @param onRfidChange - Triggered when the RFID changes.
	 */
	public function new(detectRfid, onRfidChange) {
		this.detectRfid = detectRfid;
		this.onRfidChange = onRfidChange;
	}

	public function startDetection(interval : Int) {
		Contract.requires(interval > 0);
		Contract.ensures(Contract.old(currentEvent) != currentEvent);

		stopDetection();

		var event = new Timer(interval);

		currentEvent = Some(event);
		currentValue = null;

		event.run = function() switch detectRfid() {
			case Some(rfid):
				if(currentValue != rfid) {
					currentValue = rfid;
					onRfidChange(Some(rfid));
				}
			case None:
				if(currentValue != null) {
					currentValue = null;
					onRfidChange(None);
				}
		}			
	}

	public function stopDetection() {		
		switch currentEvent {
			case Some(event): 
				event.stop();
			case None:
		}
	}

	@invariants function inv() {
		Contract.invariant(detectRfid != null);
		Contract.invariant(onRfidChange != null);
		Contract.invariant(currentEvent != null);
	}
}