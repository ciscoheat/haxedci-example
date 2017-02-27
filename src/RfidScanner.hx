import haxe.ds.Option;
import haxe.Timer;

/**
 *  An emulation of a RFID scanner.
 */
class RfidScanner implements HaxeContracts
{
	var detectRfid : Void -> Option<String>;
	var onRfidDetected : String -> Void;

	var currentEvent : Option<Timer> = None;

	public function new(detection, onDetected) {
		this.detectRfid = detection;
		this.onRfidDetected = onDetected;
	}

	public function startDetection(interval : Int) {
		Contract.requires(interval > 0);
		Contract.ensures(Contract.old(currentEvent) != currentEvent);

		stopDetection();

		var event = new Timer(interval);
		currentEvent = Some(event);

		event.run = function() switch detectRfid() {
			case Some(rfid): onRfidDetected(rfid);
			case None:
		}			
	}

	public function stopDetection() {
		switch currentEvent {
			case Some(event): 
				currentEvent = None;
				event.stop();
			case None:
		}
	}

	@invariants function inv() {
		Contract.invariant(detectRfid != null);
		Contract.invariant(onRfidDetected != null);
		Contract.invariant(currentEvent != null);
	}
}