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
				// No need to set the context after returning
			case ECall(e2, params):
				// Set context after calling another method.
				var array = new Array<Expr>();
				array.push({expr: e.expr, pos: e.pos});
				array.push(macro dci.Context.Current = this);
				
				e.expr = EBlock(array);
				
			case _: e.iter(injectSetter);
		}
	}
	
	@:macro public static function role(typeExpr : Expr) : Array<Field>
	{
		var pos = Context.currentPos();
        var fields = Context.getBuildFields();

		var typeName = getTypeName(typeExpr);
		var contextType = Context.getType(typeName);
		
		//var setContext = function(type : Null<ComplexType>) { return macro var context : $type = dci.Context.Current; };		
		//trace(macro var b = cast(a, Float));
		
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

					trace("Inject Context field on RoleMethods" + field.name);
					
					switch(f.expr.expr)
					{					
						case EBlock(exprs):
							//var typePath = TPath({ pack : ["contexts"], name : typeName + "Roles", params : [], sub : null });
							var typePath = Context.toComplexType(Context.getType(typeName + "Roles"));
							//var typePath = EConst(CIdent(typeName + "Roles"));
							exprs.unshift(macro var context : $typePath = dci.Context.Current);
							//exprs.unshift(referenceContext(contextType));
							
						default:
					}
					
				default:
			}
		}
		
        //var tint = TPath({ pack : [], name : typeName + "Roles", params : [], sub : null });
        //fields.push({ name : "context", doc : null, meta : [], access : [APrivate], kind : FVar(tint,null), pos : pos });
        
		return fields;
	}
	
	/*
	static function referenceContext(contextType : Type)
	{
		var context : ComplexType = Context.toComplexType(contextType);
		return macro var context : contexts.MoneyTransferRoles = dci.Context.Current;
	}
	*/
	
	// Future usage: Auto-generate a TypeDef based on the roles.
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