package dci.examples.restaurant.data;

class Employee
{
	public function new() 
	{}
	
	public var name(default, default) : String;
	public var birth(default, default) : Date;
	
	/**
	 * Between 0-99
	 */
	public var cookingSkill(default, default) : Int;
}