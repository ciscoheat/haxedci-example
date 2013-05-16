package ;

/* 
 TODO: 
 - Figure out where autocompletion breaks down (use other project)
 - Use ACL for Dci.currentContext? Only contexts can use it.
 */

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
			if (!Lambda.exists(field.access, function(a) { return a == Access.APublic; } ))
				continue;
			
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
						
		for (field in fields)
		{	
			if (field.name == "new" || field.name == "_new")
				continue;
								
			switch(field.kind)
			{
				case FFun(f):
					if (f.expr == null) continue;

					// Inject context var in RoleMethods.
					switch(f.expr.expr)
					{					
						case EBlock(exprs):
							var typePath : Null<ComplexType> = Context.toComplexType(contextType);
							exprs.unshift(macro var context : $typePath = Dci.currentContext);
							
						default:
					}
					
				default:
			}
		}
		
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