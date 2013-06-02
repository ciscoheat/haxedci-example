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
		var isPublic = function(a) { return a == Access.APublic; };
		var isStatic = function(a) { return a == Access.AStatic; };
		
		for (field in fields)
		{
			// Skip constructors
			if (field.name == "new") continue;

			// Add @:allow(currentPackage) to fields annotated with @role
			if (Lambda.exists(field.meta, function(m) { return m.name == "role"; }))
			{
				if (Lambda.exists(field.access, isPublic))
					Context.error("A Context Role cannot be public.", field.pos);
				
				var c = Context.getLocalClass().get();
				var pack = macro $p{c.pack};
				
				field.meta.push({name: ":allow", params: [pack], pos: Context.currentPos()});
			}
			
			// Only interactions (public instance methods) need a context setter.
			if (!Lambda.exists(field.access, isPublic) || Lambda.exists(field.access, isStatic))
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
		var returnType = getUnderlyingTypeForAbstractClass(fields);

		/*
		if (returnType == null)
			trace("No typedef for abstract type " + Context.getLocalClass());

		if (returnType != null)
		{			
			switch(cast(returnType, ComplexType))
			{
				// If a typepath, get its fields.
				case TPath(p):
					trace("Implementing typedef " + p.name + " on abstract type " + Context.getLocalClass());
					
					var typeDefFields = getTypedefFields(p);
					if (typeDefFields != null)
					{
						for (field in typeDefFields)
						{
							switch(field.kind)
							{
								// Convert each typedef method to a method in the abstract type, 
								// implementing its interface.
								case FMethod(k):
									if (k != MethNormal) throw "Unsupported method type: " + k;

									var args1;
									var ret1 : Type; 
									var methodBody : Expr;
									
									switch(field.type)
									{
										case TFun(args, ret):
											args1 = args;
											ret1 = ret;
											
										case _:
											throw "Unsupported method construct.";
									}
									
									trace("Injecting field " + field.name);
									
									var allArgs = Lambda.array(Lambda.map(args1, function(a) { return a.name; } )).join(",");									
									var fieldName = field.name;
									
									if (returnsVoid(ret1))
									{
										methodBody = macro this.$fieldName(allArgs);
									}
									else
									{
										methodBody = macro return this.$fieldName(allArgs);
									}
									
									fields.push({
										name : field.name,
										doc : null,
										meta : null,
										access : [APublic],
										kind : FFun({
											ret: Context.toComplexType(ret1),
											expr: methodBody,
											args: toFunctionArgs(args1),
											params: []
										}),
										pos: Context.currentPos()
									});
									
								case _: throw "Unsupported typedef field.";
							}
						}
					}
					
				case _: throw "Unsupported typedef path.";
			}
		}
		*/
				
		// Add the abstract type constructor to the class.
		var funcArg = { value : null, type : null, opt : false, name : "rolePlayer" };
		var kind = FFun( { ret : returnType, expr : macro return rolePlayer, params : [], args : [funcArg] } );
		
        fields.push( { name : "_new", doc : null, meta : [], access : [AStatic, AInline, APublic], kind : kind, pos : Context.currentPos() } );

		return fields;
	}
	
	static function returnsVoid(type : Type)
	{
		return switch(type)
		{
			case TAbstract(t, _):
				return t.get().name == "Void";
				
			case _: throw "Unsupported method argument type";
		}
		
	}
	
	static function toFunctionArgs(args : Array<{ t : Type, opt : Bool, name : String }> ) : Array<FunctionArg>
	{
		var output = new Array<FunctionArg>();
		
		for(a in args)
		{
			var t = {
				value: macro null,
				type: Context.toComplexType(a.t),
				opt: a.opt,
				name: a.name
			};
			
			output.push(t);
		}
		
		return output;
	}
	
	static function getTypedefFields(path : TypePath) : Array<ClassField>
	{
		var t : Type = Context.getType(path.name);
		return switch(t)
		{
			case TType(def, _):
				switch(def.get().type)
				{
					case TAnonymous(a):	a.get().fields;
					case _: null;
				}
				
			case _: null;
		}
		
	}
	
	static function getUnderlyingTypeForAbstractClass(fields : Array<Field>) : Null<ComplexType>
	{
		if (fields.length == 0)
			return null;
		
		// Test first field of class
		return switch(fields[0].kind)
		{
			// If a function, it's expressed as the type of the first argument.
			case FFun(f): 
				return f.args[0].type;
			case _: 
				// If not a function, it has a "from T to T" definition and the second
				// argument should contain the type.
				switch(fields[1].kind)
				{
					case FFun(f): f.args[0].type;
					case _:	throw "Class body for abstract type expected, instead: " + Context.getLocalType();
				}
		}
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