import haxecontracts.*;
import haxe.Constraints;
import haxe.PosInfos;

/**
 *  Highly constrained event delegate.
 *  
 *  - Can only set one event handler at a time
 *  - The same event handler can be set multiple times without having to remove it
 *  - Before setting another event handler, the current event handler must be removed using itself
 *  - Deregisters automatically after referencing the event handler, so it must be set 
 *    again after being triggered
 */
class SingleEventHandler<T : Function> implements HaxeContracts
{
    public var trigger(get, never) : T;
    var _trigger : T;

    var setPos : Null<PosInfos>;
    var removePos : Null<PosInfos>;

    public function new() {}

    function get_trigger() : T {
        Contract.requires(_trigger != null, 
            if(removePos != null) 'Event removed before triggered, at ' + posStr(removePos)
            else if(setPos != null) 'Event already triggered. Set at ' + posStr(setPos)
            else "Event not set."
        );
        var t = _trigger;
        _trigger = null;
        return t;
    }

    public function set(event : T, ?pos : PosInfos) {
        Contract.requires(event != null);
        Contract.requires(
            this._trigger == null || this._trigger == event, 
            'Event already set at ${posStr(setPos)} (Attempted to set at ${posStr(pos)})'
        );
        this._trigger = event;
        this.setPos = pos;
        this.removePos = null;
    }

    public function remove(event : T, ?pos : PosInfos) {
        Contract.requires(event != null);
        Contract.requires(
            this._trigger == event, 
            if(setPos == null) "Event not set before removal. Removed at " + posStr(pos)
            else 'Event not same as the one registered at ${posStr(setPos)} (Attempted to remove at ${posStr(pos)})'
        );
        this._trigger = null;
        this.setPos = null;
        this.removePos = pos;
    }

    public function hasEvent() 
        return this._trigger != null;

    function posStr(p : PosInfos)
        return p.fileName + ":" + p.lineNumber;        
}