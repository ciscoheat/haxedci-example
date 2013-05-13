package ;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

using haxe.macro.ExprTools;

class Dci
{
	@macro public static function context() : Array<Field>
	{
		trace("Creating context... " + Context.getLocalType());
		
        var fields = Context.getBuildFields();
		
		for (field in fields)
		{
			if (field.name == "new" || !Lambda.exists(field.access, function(a) { return a == Access.APublic; } ))
				continue;
			
			switch(field.kind)
			{
				case FFun(f):
					if (f.expr == null) continue;

					trace("Inject Context setter after method calls in Interaction " + field.name);
					//trace(f.expr.expr);
					
					f.expr.iter(injectSetter);
					
					switch(f.expr.expr)
					{
						case EBlock(exprs):
							exprs.unshift(macro dci.Context.Current = this);
							
						default:
					}
					
				default:
			}
		}
		
		return fields;
	}
	
	@macro static function injectSetter(e : Expr)
	{
		switch(e.expr)
		{
			case EReturn(e):
			case ECall(e2, params):
				var array = new Array<Expr>();
				array.push({expr: e.expr, pos: e.pos});
				array.push(macro dci.Context.Current = this);
				
				e.expr = EBlock(array);
				
			case _: e.iter(injectSetter);
		}
	}
	
	@:macro public static function role(typeExpr) : Array<Field>
	{
		var pos = Context.currentPos();
        var fields = Context.getBuildFields();
		
		var typeName = getTypeName(typeExpr);
		var contextType = Context.getType(typeName);
		
		var getField = function(fieldName) { macro return Reflect.field(dci.Context.Current, fieldName); };
		
		for (field in getRoleFields(Context.getType(typeName)))
		{
			trace("Adding " + field.name + " to role for " + typeName);
		}
		
        var tint = TPath({ pack : [], name : typeName, params : [], sub : null });
        fields.push({ name : "context", doc : null, meta : [], access : [APrivate], kind : FVar(tint,null), pos : pos });
        
		return fields;
	}
	
	@macro static function getRoleFields(typeName : Type) : Array<ClassField>
	{
		var output = new Array<ClassField>();
		
		switch(typeName)
		{
			case TInst(t, params):
				for(field in t.get().fields.get())
				{
					if (field.meta.has("role"))
					{
						output.push(field);
					}
				}
				
			default:
				Context.error("Expected class name: " + typeName, null);
		}		
		
		return output;
	}
	
	@macro static function getTypeName(type) : String
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
		
		Context.error("Class type expected.", type.pos);
		return null;
	}
}