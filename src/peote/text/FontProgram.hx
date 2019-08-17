package peote.text;

#if !macro
@:genericBuild(peote.text.FontProgram.FontProgramMacro.build())
class FontProgram<T> {}
#else

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.TypeTools;

class FontProgramMacro
{
	public static var cache = new Map<String, Bool>();
	
	static public function build()
	{	
		switch (Context.getLocalType()) {
			case TInst(_, [t]):
				switch (t) {
					case TInst(n, []):
						var style = n.get();
						var styleSuperName:String = null;
						var styleSuperModule:String = null;
						var s = style;
						while (s.superClass != null) {
							s = s.superClass.t.get(); trace("->" + s.name);
							styleSuperName = s.name;
							styleSuperModule = s.module;
						}
						return buildClass(
							"FontProgram", style.pack, style.module, style.name, styleSuperModule, styleSuperName, TypeTools.toComplexType(t)
						);	
					default: Context.error("Type for GlyphStyle expected", Context.currentPos());
				}
			default: Context.error("Type for GlyphStyle expected", Context.currentPos());
		}
		return null;
	}
	
	static public function buildClass(className:String, stylePack:Array<String>, styleModule:String, styleName:String, styleSuperModule:String, styleSuperName:String, styleType:ComplexType):ComplexType
	{		
		var styleMod = styleModule.split(".").join("_");
		
		className += "__" + styleMod;
		if (styleModule.split(".").pop() != styleName) className += ((styleMod != "") ? "_" : "") + styleName;
		
		var classPackage = Context.getLocalClass().get().pack;
		
		if (!cache.exists(className))
		{
			cache[className] = true;
			
			var styleField:Array<String>;
			//if (styleSuperName == null) styleField = styleModule.split(".").concat([styleName]);
			//else styleField = styleSuperModule.split(".").concat([styleSuperName]);
			styleField = styleModule.split(".").concat([styleName]);
			
			var glyphType = Glyph.GlyphMacro.buildClass("Glyph", stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType);
			
			#if peoteview_debug_macro
			trace('generating Class: '+classPackage.concat([className]).join('.'));	
			
			trace("ClassName:"+className);           // FontProgram__peote_text_GlypStyle
			trace("classPackage:" + classPackage);   // [peote,text]	
			
			trace("StylePackage:" + stylePack);  // [peote.text]
			trace("StyleModule:" + styleModule); // peote.text.GlyphStyle
			trace("StyleName:" + styleName);     // GlyphStyle			
			trace("StyleType:" + styleType);     // TPath(...)
			trace("StyleField:" + styleField);   // [peote,text,GlyphStyle,GlyphStyle]
			#end
			
			var glyphStyleHasMeta = Glyph.GlyphMacro.parseGlyphStyleMetas(styleModule+"."+styleName); // trace("FontProgram: glyphStyleHasMeta", glyphStyleHasMeta);
			var glyphStyleHasField = Glyph.GlyphMacro.parseGlyphStyleFields(styleModule+"."+styleName); // trace("FontProgram: glyphStyleHasField", glyphStyleHasField);
			
			// -------------------------------------------------------------------------------------------
			var c = macro		

			class $className extends peote.view.Program
			{
				public var font:peote.text.Font<$styleType>; // TODO peote.text.Font<$styleType>
				public var fontStyle:$styleType;
				
				var _buffer:peote.view.Buffer<$glyphType>;
					
				//public function new(font:$fontType, fontStyle:peote.text.Gl3FontStyle)
				public function new(font:peote.text.Font<$styleType>, fontStyle:$styleType)
				{
					this.font = font;
					_buffer = new peote.view.Buffer<$glyphType>(100);
					super(_buffer);	
					
					this.fontStyle = fontStyle;
					setFontStyle(fontStyle); // inject global fontsize and color into shader -> GENERATED
				}
				
				public inline function add(glyph:$glyphType, charcode:Int, x:Int, y:Int, glyphStyle:$styleType = null):Void {
					glyph.x = x;
					glyph.y = y;
					glyph.setStyle((glyphStyle != null) ? glyphStyle : fontStyle);
					setCharcode(glyph, charcode);  // -> GENERATED					
					_buffer.addElement(glyph);
				}
								
				public inline function remove(glyph:$glyphType):Void {
					_buffer.removeElement(glyph);
				}
								
				public inline function update(glyph:$glyphType):Void {
					_buffer.updateElement(glyph);
				}
				
				
				public function setCharcode(glyph:$glyphType, charcode:Int):Void
				{
					${switch (glyphStyleHasMeta.gl3Font)
					{
						case true: macro // ------- Gl3Font -------
						{
							var range = font.getRange(charcode);
							var metric:peote.text.Gl3FontData.Metric;
							
							${switch (glyphStyleHasMeta.multiRange) {
								case true: macro {
									if (range == null) return;
									
									${switch (glyphStyleHasMeta.multiTexture) {
										case true: macro glyph.unit = range.unit;
										default: macro {}
									}}
									
									glyph.slot = range.slot;								
									metric = range.fontData.getMetric(charcode);
								}
								default: macro {
									metric = range.getMetric(charcode);
								}
							}}
							
							if (metric != null) {
								//trace("glyph"+charcode, range.unit, range.slot, metric);								
								glyph.tx = metric.u;
								glyph.ty = metric.v;
								glyph.tw = metric.w;
								glyph.th = metric.h;							
								${switch (glyphStyleHasField.local_width) {
									case true: macro glyph.w = metric.width * glyph.width;
									default: switch (glyphStyleHasField.width) {
										case true: macro glyph.w = metric.width * fontStyle.width;
										default: macro glyph.w = metric.width * font.width;
								}}}
								${switch (glyphStyleHasField.local_height) {
									case true: macro glyph.h = metric.height * glyph.height;
									default: switch (glyphStyleHasField.height) {
										case true: macro glyph.h = metric.height * fontStyle.height;
										default: macro glyph.h = metric.height * font.height;
								}}}
							}
							
						
						}
						default: macro // ------- simple font -------
						{
							glyph.unit = range.unit;
							glyph.slot = range.slot;								
							glyph.tile = charcode;
							${switch (glyphStyleHasField.local_width) {
								case true: macro glyph.w = glyph.width;
								default: switch (glyphStyleHasField.width) {
									case true: macro glyph.w = fontStyle.width;
									default: macro glyph.w = font.width;
							}}}
							${switch (glyphStyleHasField.local_height) {
								case true: macro glyph.h = glyph.height;
								default: switch (glyphStyleHasField.height) {
									case true: macro glyph.h =fontStyle.height;
									default: macro glyph.h = font.height;
							}}}
						}
					}}
				
				}

				
				public function setFontStyle(fontStyle:$styleType):Void
				{
					${switch (glyphStyleHasMeta.gl3Font)
					{
						case true: macro // ------- Gl3Font -------
						{
							this.fontStyle = fontStyle;
											
							var bold = peote.view.utils.Util.toFloatString(0.5);
							var sharp = peote.view.utils.Util.toFloatString(0.5);
								
							${switch (glyphStyleHasMeta.multiTexture) {
								case true: macro {
									super.setMultiTexture(font.textureCache.textures, "TEX");
								}
								default: macro {
									super.setTexture(font.textureCache, "TEX");
								}
							}}
								
							${switch (glyphStyleHasField.local_color) {
								case true:
									macro super.setColorFormula("color * smoothstep( "+bold+" - "+sharp+" * fwidth(TEX.r), "+bold+" + "+sharp+" * fwidth(TEX.r), TEX.r)");
								default: switch (glyphStyleHasField.color) {
									case true:
										macro super.setColorFormula(Std.string(fontStyle.color.toGLSL()) + " * smoothstep( "+bold+" - "+sharp+" * fwidth(TEX.r), "+bold+" + "+sharp+" * fwidth(TEX.r), TEX.r)");
									default:
										macro super.setColorFormula(Std.string(font.color.toGLSL()) + " * smoothstep( "+bold+" - "+sharp+" * fwidth(TEX.r), "+bold+" + "+sharp+" * fwidth(TEX.r), TEX.r)");
							}}}		
						}
						default: macro // ------- simple font -------
						{
							// TODO
						}
						
					}}
				}
				
			}

			// -------------------------------------------------------------------------------------------
			// -------------------------------------------------------------------------------------------
			
			Context.defineModule(classPackage.concat([className]).join('.'),[c]);
		}
		return TPath({ pack:classPackage, name:className, params:[] });
	}
}
#end
