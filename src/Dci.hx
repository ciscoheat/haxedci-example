package ;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

using haxe.macro.ExprTools;

class Dci
{
	static function setCurrentContext()
	{
		return macro dci.ContextStorage.current = this;
	}
	
	@macro public static function context() : Array<Field>
	{
		//trace("Creating context... " + Context.getLocalType());
		
        var fields = Context.getBuildFields();
		
		var name = typeNameFromType(Context.getLocalType());		
		var contextVarName = name.substr(name.lastIndexOf(".")+1);
		
		for (field in fields)
		{
			if (field.name == "new" || !Lambda.exists(field.access, function(a) { return a == Access.APublic; } ))
				continue;
			
			switch(field.kind)
			{
				case FFun(f):
					if (f.expr == null) continue;

					//trace("Inject Context setter after method calls in Interaction " + field.name);
					//trace(f.expr.expr);
					
					injectSetter(f.expr);
					
					switch(f.expr.expr)
					{
						case EBlock(exprs):
							exprs.unshift(Dci.setCurrentContext());
							
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
				// No need to set the context after returning
			case ECall(e2, params):
				// Set context after calling another method.
				var array = new Array<Expr>();
				array.push({expr: e.expr, pos: e.pos});
				array.push(Dci.setCurrentContext());
				
				e.expr = EBlock(array);
				
			case _: e.iter(injectSetter);
		}
	}
	
	@macro public static function role(typeExpr : Expr) : Array<Field>
	{
		var pos = Context.currentPos();
        var fields = Context.getBuildFields();

		var typeName = getTypeName(typeExpr);
		var contextType = Context.getType(typeName);
		
		/*
		{ expr => EVars([ 
			{ expr => 
				{ expr => EField( 
					{ expr => EField( 
						{ expr => EConst(CIdent(dci)), pos => #pos }
						, Context)
					, pos => #pos }, Current)
				, pos => #pos }
			, name => b
			, type => TPath( { name => Adler32, pack => [haxe, crypto], params => [] } ) 
			} ])
		, pos => #pos }
		
		trace(macro var b : haxe.crypto.Adler32 = dci.Context.Current);
		
		var setContextVar = EVars([{ 
			name: "context", 
			type: Context.toComplexType(Context.getType(typeName + "Roles")),
			expr: macro dci.Context.Current
		}]);
		*/
		
		for (field in fields)
		{	
			if (field.name == "new" || field.name == "_new")
				continue;

			switch(field.kind)
			{
				case FFun(f):
					if (f.expr == null) continue;

					//trace("Inject Context field on RoleMethods" + field.name);
					
					switch(f.expr.expr)
					{					
						case EBlock(exprs):
							//var typePath = TPath({ pack : ["contexts"], name : typeName, params : [], sub : null });
							//var typePath = macro $i("contexts." + typeName);
							//var typePath = EConst(CIdent(typeName + "Roles"));
							var typePath = Context.toComplexType(Context.getType(typeName));
							exprs.unshift(macro var context : $typePath = dci.ContextStorage.current);
							//var contextType : ComplexType = macro : $typePath
							
						default:
					}
					
				default:
			}
		}
		
        //var tint = TPath({ pack : [], name : typeName + "Roles", params : [], sub : null });
        //fields.push({ name : "context", doc : null, meta : [], access : [APrivate], kind : FVar(tint,null), pos : pos });
        
		return fields;
	}
	
	// Future usage: Auto-generate a TypeDef based on the roles.
	macro static function getRoleFields(typeName : Type) : Array<ClassField>
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
	
	static function typeNameFromType(type : Type) : String
	{
		switch(type)
		{
			case TInst(cls, _):
				return cls.get().module;
				
			default:
				Context.error("No Type found.", Context.currentPos());
				return null;
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
		
		Context.error("Class type expected.", type.pos);
		return null;
	}
}