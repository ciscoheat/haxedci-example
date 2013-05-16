package ;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

using haxe.macro.ExprTools;

class Dci
{	
	#if macro
	@macro public static function context() : Array<Field>
	{
        var fields : Array<Field> = Context.getBuildFields();		
		
		for (field in fields)
		{
			// Skip constructors
			if (field.name == "new") continue;

			// Add @:allow(currentPackage) to fields annotated with @role
			if (Lambda.exists(field.meta, function(m) { return m.name == "role"; }))
			{
				if (Lambda.exists(field.access, function(a) { return a == Access.APublic; } ))
					Context.error("A Context Role cannot be public.", field.pos);
				
				var c = Context.getLocalClass().get();
				var pack = macro $p{c.pack};
				
				field.meta.push({name: ":allow", params: [pack], pos: Context.currentPos()});
			}
			
			// Only interactions need context setter.
			if (!Lambda.exists(field.access, function(a) { return a == Access.APublic; } ) || 
				Lambda.exists(field.access, function(a) { return a == Access.AStatic; } ))
			{
				continue;
			}
			
			switch(field.kind)
			{
				case FFun(f):
					if (f.expr == null) continue;

					// Set Context to current object after all method calls.
					injectSetter(f.expr);
					
					switch(f.expr.expr)
					{
						case EBlock(exprs):
							exprs.unshift(setCurrentContext());
							
						default:
					}
					
				default:
			}
		}
		
		return fields;
	}
		
	@macro public static function role(typeExpr : Expr) : Array<Field>
	{
        var fields : Array<Field> = Context.getBuildFields();
		var contextName = getTypeName(typeExpr);
		var contextType : Type = Context.getType(contextName);
		
		// Inject context local variable in RoleMethods.
		for (field in fields)
		{				
			switch(field.kind)
			{
				case FFun(f):
					if (f.expr == null) continue;

					switch(f.expr.expr)
					{					
						case EBlock(exprs):
							var typePath : Null<ComplexType> = Context.toComplexType(contextType);
							exprs.unshift(macro var context : $typePath = Dci.currentContext);
							
						case _:
					}
					
				case _:
			}
		}
		
		// Determine underlying type of abstract type
		var returnType = switch(fields.length)
		{
			case 0: null;
			case _:
				// Test first field of class
				switch(fields[0].kind)
				{
					// If a function, it's expressed as the type of the first argument.
					case FFun(f): f.args[0].type;
					case _: 
						// If not a function, it has a "from T to T" definition and the second
						// argument should contain the type.
						switch(fields[1].kind)
						{
							case FFun(f): f.args[0].type;
							case _:
								throw "Class body for abstract type expected, instead: " + Context.getLocalType();
						}
				}
		}
		
		// Add the abstract type constructor to the class.
		var funcArg = { value : null, type : null, opt : false, name : "rolePlayer" };
		var kind = FFun( { ret : returnType, expr : macro return rolePlayer, params : [], args : [funcArg] } );
		
        fields.push( { name : "_new", doc : null, meta : [], access : [AStatic, AInline, APublic], kind : kind, pos : Context.currentPos() } );

		return fields;
	}
	
	static function setCurrentContext()
	{
		return macro Dci.currentContext = this;
	}

	static function injectSetter(e : Expr)
	{
		switch(e.expr)
		{
			case EReturn(e):
				// No need to set the context after returning
			case ECall(e2, params):
				// Set context after calling another method.
				var array = new Array<Expr>();
				array.push({expr: e.expr, pos: e.pos});
				array.push(setCurrentContext());
				
				e.expr = EBlock(array);
				
			case _: e.iter(injectSetter);
		}
	}

	static function getTypeName(type) : String
	{
		switch(type.expr)
		{
			case EConst(c):
				switch(c)
				{
					case CIdent(s):
						return s;
						
					default:
				}
				
			default:
		}
		
		Context.error("Type identifier expected.", type.pos);
		return null;
	}
	#else
	public static var currentContext(default, default) : Dynamic;
	#end
}