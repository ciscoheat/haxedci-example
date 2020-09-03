package gadgets;

import mithril.M;

/**
 *  Simulates a receipt printer.
 *  
 *  This is a good example of an object playing all M, V and C roles,
 *  because they are all tightly coupled in this example.
 */
class ReceiptPrinter implements HaxeContracts implements Mithril
{
	var paperIsCut : Bool = false;
	var buffer : Array<String> = [];

	public var receipt(get, null) : Iterable<String>;
	function get_receipt() return buffer;

	public function new() {}

	public function print(line : String) {
		if(paperIsCut) {
			buffer = [];
			paperIsCut = false;
		}
		buffer.unshift(line);
		M.redraw();
	}

	public function cutPaper()
		paperIsCut = true;

	public function view()
		m('.box', 
			m('.slot',
				m('.paper', {
					onclick: () -> if(paperIsCut) buffer.splice(0, buffer.length)
				}, [for(s in receipt)
					m('p', if(s == "") M.trust("&nbsp;") else s)
				])
			)
		);

	@invariants function inv() {
		Contract.invariant(buffer != null);
	}
}