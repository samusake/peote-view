package peote.view;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.ExprTools;

@:remove @:autoBuild(peote.view.ElementImpl.build())
interface Element {}

class ElementImpl
{
#if macro

	static function hasMeta(f:Field, s:String):Bool {for (m in f.meta) { if (m.name == s || m.name == ':$s') return true; } return false; }
	static var allowForBuffer = [{ name:":allow", params:[macro peote.view], pos:Context.currentPos()}];
	
	public static function build()
	{
		var hasNoNew:Bool = true;
		
		
		var classname = Context.getLocalClass().get().name;
		var classpackage = Context.getLocalClass().get().pack;
		
		trace("--------------- " + classname + " -------------------");
		
		// trace(Context.getLocalClass().get().superClass); 
		trace("TODO: autogenerate shaders and buffering");

		// TODO: childclasses!
		
// { module => elements.ElementSimpleChild, init => null, kind => KNormal,
// meta => { ??? => #function:1, add => #function:3, get => #function:0, has => #function:1, remove => #function:1 }, 
// name => ElementSimpleChild, pack => [elements], interfaces => [], params => [], __t => #abstract, doc => null,
// fields => class fields, isPrivate => false, constructor => null, isInterface => false, isExtern => false,
// superClass => { params => [], t => elements.ElementSimple }, exclude => #function:0, statics => class fields, overrides => [] }

		// TODO
		var conf = {
			isES3:false,
			IN:"attribute",
			isUBO:false,
			isINSTANCED:false,
			isPICK:false,
		};
		#if peoteview_es3
		conf.isES3 = true;
		conf.IN = "in";
			#if peoteview_uniformbuffers
			conf.isUBO = true;
			#end
			#if peoteview_instancedrawing
			conf.isINSTANCED = true;
			#end
		#end

		var fields = Context.getBuildFields();
		for (f in fields)
		{
			
			if (f.name == "new") {
				hasNoNew = false;
			}
			else
			switch (f.kind)
			{
				case FVar(t): //trace("attribute:",f.name ); // t: TPath({ name => Int, pack => [], params => [] })
					if ( hasMeta(f, "positionX") ) {
						trace(f.name);
					}
					else if ( hasMeta(f, "positionY") ) {
						trace(f.name);
					}
					else if ( hasMeta(f, "positionZ") ) {
						trace(f.name);
					}
					
					// TODO
					// TODO
					// TODO
					
				default: //throw Context.error('Error: attribute has to be an variable.', f.pos);
			}

		}
		// -----------------------------------------------------------------------------------
		
		var vertex_count = 6;
		var buff_size = (conf.isINSTANCED) ? 8 : vertex_count * 4;
		
		
		// ---------------------- vertex count and bufsize -----------------------------------
		fields.push({
			name:  "VERTEX_COUNT",
			meta:  allowForBuffer,
			access:  [Access.APrivate, Access.AStatic, Access.AInline],
			kind: FieldType.FVar(macro:Int, macro $v{vertex_count}), 
			pos: Context.currentPos(),
		});
		fields.push({
			name:  "BUFF_SIZE",
			meta:  allowForBuffer,
			access:  [Access.APrivate, Access.AStatic, Access.AInline],
			kind: FieldType.FVar(macro:Int, macro $v{buff_size}), 
			pos: Context.currentPos(),
		});
		// ---------------------- vertex attribute bindings ----------------------------------
		fields.push({
			name:  "aPOSITION",
			access:  [Access.APrivate, Access.AStatic, Access.AInline],
			kind: FieldType.FVar(macro:Int, macro $v{0}), 
			pos: Context.currentPos(),
		});
		if (conf.isINSTANCED)
			fields.push({
				name:  "aPOSSIZE",
				access:  [Access.APrivate, Access.AStatic, Access.AInline],
				kind: FieldType.FVar(macro:Int, macro $v{1}), 
				pos: Context.currentPos(),
			});
			
		// TODO: COLOR...
		
		// ---------------------- bytePos and  dataPointer ----------------------------------
		fields.push({
			name:  "bytePos",
			meta:  allowForBuffer,
			access:  [Access.APrivate],
			kind: FieldType.FVar(macro:Int, macro $v{-1}), 
			pos: Context.currentPos(),
		});
		fields.push({
			name:  "dataPointer",
			meta:  allowForBuffer,
			access:  [Access.APrivate],
			kind: FieldType.FVar(macro:peote.view.PeoteGL.DataPointer, null), 
			pos: Context.currentPos(),
		});

		// -------------------------- instancedrawing --------------------------------------
		if (conf.isINSTANCED)
			fields.push({
				name:  "instanceBytes",
				access:  [Access.APrivate, Access.AStatic],
				kind: FieldType.FVar(macro:haxe.io.Bytes, macro null), 
				pos: Context.currentPos(),
			});
		fields.push({
			name: "createInstanceBytes",
			meta:  allowForBuffer,
			access: [Access.APrivate, Access.AStatic, Access.AInline],
			pos: Context.currentPos(),
			kind: FFun({
				args: [],
				expr: (!conf.isINSTANCED) ? macro {} :
				macro {
					if (instanceBytes == null) {
						trace("create bytes for instance GLbuffer");
						instanceBytes = haxe.io.Bytes.alloc(VERTEX_COUNT * 4);
						instanceBytes.setUInt16(0 , 1); instanceBytes.setUInt16(2,  1);
						instanceBytes.setUInt16(4 , 1); instanceBytes.setUInt16(6,  1);
						instanceBytes.setUInt16(8 , 0); instanceBytes.setUInt16(10, 1);
						instanceBytes.setUInt16(12, 1); instanceBytes.setUInt16(14, 0);
						instanceBytes.setUInt16(16, 0); instanceBytes.setUInt16(18, 0);
						instanceBytes.setUInt16(20, 0); instanceBytes.setUInt16(22, 0);
					}
				},
				ret: null
			})
		});
		fields.push({
			name: "updateInstanceGLBuffer",
			meta: allowForBuffer,
			access: [Access.APrivate, Access.AStatic, Access.AInline],
			pos: Context.currentPos(),
			kind: FFun({
				args:[ {name:"gl", type:macro:peote.view.PeoteGL}, {name:"glInstanceBuffer", type:macro:peote.view.PeoteGL.GLBuffer} ],
				expr: (!conf.isINSTANCED) ? macro {} :
				macro {
					trace("fill full instance GLbuffer");
					gl.bindBuffer (gl.ARRAY_BUFFER, glInstanceBuffer);
					gl.bufferData (gl.ARRAY_BUFFER, instanceBytes.length, instanceBytes, gl.STATIC_DRAW);
					gl.bindBuffer (gl.ARRAY_BUFFER, null);
				},
				ret: null
			})
		});
		
		// ----------------------------- writeBytes -----------------------------------------
		fields.push({
			name: "writeBytes",
			meta: allowForBuffer,
			access: [Access.APrivate, Access.AInline],
			pos: Context.currentPos(),
			kind: FFun({
				args:[ {name:"bytes", type:macro:haxe.io.Bytes} ],
				expr: (conf.isINSTANCED) ? 
				macro {
					bytes.setUInt16(bytePos + 0 , x); bytes.setUInt16(bytePos + 2,  y);
					bytes.setUInt16(bytePos + 4 , w); bytes.setUInt16(bytePos + 6,  h);
				} :
				macro {
					var xw = x + w;
					var yh = y + h;
					bytes.setUInt16(bytePos + 0 , xw); bytes.setUInt16(bytePos + 2,  yh);
					bytes.setUInt16(bytePos + 4 , xw); bytes.setUInt16(bytePos + 6,  yh);
					bytes.setUInt16(bytePos + 8 , x ); bytes.setUInt16(bytePos + 10, yh);
					bytes.setUInt16(bytePos + 12, xw); bytes.setUInt16(bytePos + 14, y );
					bytes.setUInt16(bytePos + 16, x ); bytes.setUInt16(bytePos + 18, y );
					bytes.setUInt16(bytePos + 20, x ); bytes.setUInt16(bytePos + 22, y );
				},
				ret: null
			})
		});
				
		// ----------------------------- updateGLBuffer -------------------------------------
		fields.push({
			name: "updateGLBuffer",
			meta: allowForBuffer,
			access: [Access.APrivate, Access.AInline],
			pos: Context.currentPos(),
			kind: FFun({
				args:[ {name:"gl", type:macro:peote.view.PeoteGL}, {name:"glBuffer", type:macro:peote.view.PeoteGL.GLBuffer} ],
				expr: macro {
					gl.bindBuffer (gl.ARRAY_BUFFER, glBuffer);
					gl.bufferSubData(gl.ARRAY_BUFFER, bytePos, BUFF_SIZE, dataPointer );
					gl.bindBuffer (gl.ARRAY_BUFFER, null);
				},
				ret: null
			})
		});
		
		// ----------------------------- writeBytes -----------------------------------------
		fields.push({
			name: "bindAttribLocations",
			meta: allowForBuffer,
			access: [Access.APrivate, Access.AStatic, Access.AInline],
			pos: Context.currentPos(),
			kind: FFun({
				args:[ {name:"gl", type:macro:peote.view.PeoteGL}, {name:"glProgram", type:macro:peote.view.PeoteGL.GLProgram} ],
				expr: (conf.isINSTANCED) ? 
				macro {
					gl.bindAttribLocation(glProgram, aPOSITION, "aPosition");
					gl.bindAttribLocation(glProgram, aPOSSIZE, "aPossize");
				} :
				macro {
					gl.bindAttribLocation(glProgram, aPOSITION, "aPosition");
				},
				ret: null
			})
		});
				
		// ----------------------------- render --------------------------------------------
		fields.push({
			name: "render",
			meta: allowForBuffer,
			access: [Access.APrivate, Access.AStatic, Access.AInline],
			pos: Context.currentPos(),
			kind: FFun({
				args:[ {name:"maxElements", type:macro:Int}, {name:"gl", type:macro:peote.view.PeoteGL}, {name:"glBuffer", type:macro:peote.view.PeoteGL.GLBuffer}, {name:"glInstanceBuffer", type:macro:peote.view.PeoteGL.GLBuffer} ],
				expr: (conf.isINSTANCED) ? 
				macro {
					gl.bindBuffer(gl.ARRAY_BUFFER, glInstanceBuffer);
					gl.enableVertexAttribArray (aPOSITION);
					gl.vertexAttribPointer(aPOSITION, 2, gl.SHORT, false, 4, 0 ); // vertexstride 0 should calc automatically
					
					gl.bindBuffer(gl.ARRAY_BUFFER, glBuffer);
					gl.enableVertexAttribArray (aPOSSIZE);
					gl.vertexAttribPointer(aPOSSIZE, 4, gl.SHORT, false, 8, 0 ); // vertexstride 0 should calc automatically
					gl.vertexAttribDivisor(aPOSSIZE, 1); // one per instance
					
					gl.drawArraysInstanced (gl.TRIANGLE_STRIP,  0, VERTEX_COUNT, maxElements);
					
					gl.disableVertexAttribArray (aPOSITION);
					gl.disableVertexAttribArray (aPOSSIZE);
					gl.bindBuffer (gl.ARRAY_BUFFER, null);
				} :
				macro {
					gl.bindBuffer(gl.ARRAY_BUFFER, glBuffer);
					
					gl.enableVertexAttribArray (aPOSITION);
					gl.vertexAttribPointer(aPOSITION, 2, gl.SHORT, false, 4, 0 ); // vertexstride 0 should calc automatically
					
					gl.drawArrays (gl.TRIANGLE_STRIP,  0,  maxElements*VERTEX_COUNT);
					
					gl.disableVertexAttribArray (aPOSITION);
					gl.bindBuffer (gl.ARRAY_BUFFER, null);
				},
				ret: null
			})
		});
				
		// ----------------------- shader generation ------------------------
		fields.push({
			name:  "vertexShader",
			meta:  allowForBuffer,
			access:  [Access.APrivate, Access.AStatic, Access.AInline],
			kind: FieldType.FVar(macro:String, macro $v{parseShader(conf, Shader.vertexShader)}), 
			pos: Context.currentPos(),
		});
		
		fields.push({
			name:  "fragmentShader",
			meta:  allowForBuffer,
			access:  [Access.APrivate, Access.AStatic, Access.AInline],
			kind: FieldType.FVar(macro:String, macro $v{parseShader(conf, Shader.fragmentShader)}),
			pos: Context.currentPos(),
		});
		
		
		return fields; // <------ classgeneration complete !
	}
	
	// ----------------------------------------------------------------------------------
	// ---------------------------- shaderparsing ---------------------------------------
	// ----------------------------------------------------------------------------------
	
	public static var rComments:EReg = new EReg("//.*?$","gm");
	public static var rEmptylines:EReg = new EReg("([ \t]*\r?\n)+", "g");
	public static var rStartspaces:EReg = new EReg("^([ \t]*\r?\n)+", "g");

	static inline function parseShader(conf:Dynamic, shader:String):String
	{		
		var template = new haxe.Template(shader);			
		return rStartspaces.replace(rEmptylines.replace(rComments.replace(template.execute(conf), ""), "\n"), "");
	}
	

#end
}