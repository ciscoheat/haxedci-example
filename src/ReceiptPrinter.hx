import mithril.M;

class ReceiptPrinter implements HaxeContracts implements Mithril
{
	var paperIsCut : Bool = false;

	public var receipt(get, null) : Iterable<String>;
	function get_receipt() return _buffer;
	var _buffer : Array<String> = [];

	public function new() {}

	public function print(line : String) {
		if(paperIsCut) {
			_buffer = [];
			paperIsCut = false;
		}
		_buffer.unshift(line);
		M.redraw();
	}

	public function cutPaper() {
		paperIsCut = true;
	}

	public function view()
		m('.box', 
			m('.slot',
				m('.paper', [for(s in receipt)
					m('p', s == "" ? M.trust("&nbsp;") : s)
				])
			)
		);

	@invariants function inv() {
		Contract.invariant(_buffer != null);
	}
}