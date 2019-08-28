package;
#if sampleTextRendering
import haxe.Timer;

import lime.ui.Window;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.MouseButton;

import peote.view.PeoteView;
import peote.view.Display;
import peote.view.Color;

import peote.text.Font;

import peote.text.FontProgram;
import peote.text.Glyph;
import peote.text.Range;

//import peote.text.GlyphStyle;
//import peote.text.Gl3GlyphStyle;

import peote.text.Line;
//import peote.text.Page;

@gl3Font
@multiRange 
@multiTexture
class GlyphStyle {
	//@global public var color:Color = Color.GREEN;
	public var color:Color = Color.GREEN;
	
	public var width:Float = 30.0;
	public var height:Float = 30.0;
	
	public function new() {}
}

class TextRendering
{
	var peoteView:PeoteView;
	var display:Display;
	var timer:Timer;
	
	public function new(window:Window)
	{
		try {	
			peoteView = new PeoteView(window.context, window.width, window.height);
			display   = new Display(10,10, window.width-20, window.height-20, Color.GREY1);
			peoteView.addDisplay(display);
			
			//var font = new Font<GlyphStyle>("assets/gl3fonts/hack/");
			//var font = new Font<GlyphStyle>("assets/gl3fonts/unifont/", [new Range(0x0000,0x0fff)]);
			var font = new Font<GlyphStyle>("assets/gl3fonts/unifont/");
			
			font.load( function() {
			
				var fontStyle = new GlyphStyle();
				fontStyle.color = Color.RED;
				//fontStyle.width = 30.0;
				//fontStyle.height = 30.0;
				
				var fontProgram = new FontProgram<GlyphStyle>(font, fontStyle); // manage the Programs to render glyphes in different size/colors/fonts
				display.addProgram(fontProgram);
				
				
				var glyphStyle1 = new GlyphStyle();
				glyphStyle1.color = Color.YELLOW;
				//glyphStyle1.width = 50.0;
								
				var glyphStyle2 = new GlyphStyle();
				
				// -----------

				var glyph1 = new Glyph<GlyphStyle>();
				fontProgram.addGlyph(glyph1, 65, 0, 0);
				
				fontProgram.setCharcode(glyph1, 66);
				//glyph1.setStyle(glyphStyle2);
				//glyph1.color = Color.BLUE;
				//glyph1.height = 30;
				fontProgram.updateGlyph(glyph1);
				
				// -----------
				fontProgram.setFontStyle(glyphStyle2);
				var glyph2 = new Glyph<GlyphStyle>();
				//if (!fontProgram.addGlyph( glyph2, 0x0fdb, 20, 0, glyphStyle2) )
					//trace(" ----> Charcode not inside Font");
					
				fontProgram.addGlyph( glyph2, 0x2e25, 20, 0, glyphStyle2);
				//fontProgram.removeGlyph( glyph2 );
				
				
				// -------- Lines  ---------
				
				var line = new Line<GlyphStyle>();
				fontProgram.addLine(line, "TA - Hello World...", 0, 100);
				
				//line.setStyle(glyphStyle2, 0, 4);
				//line.x = 30; // all gylphes inside will change
				//line.y = 40; // all gylphes inside will change
				//fontProgram.updateLine(line);
				/*
				fontProgram.addGlyphToLine(line, 68 , 0, true); // true -> from end
				fontProgram.addGlyphesToLine(line,  Glyphes.fromString("brave new "), 6);
				
				fontProgram.clearLine(line);
				fontProgram.removeGlyphFromLine(line, 6);
				fontProgram.removeGlyphesFromLine(line, 0, 4, true); // true -> from end

				fontProgram.changeLine(line, 77, 0);
				fontProgram.changeInLine(line, "test", 6);

				fontProgram.removeLine(line);
				
				// -------- Pages ??? (namespace!!!) <--------
				
				var page = new Page( 0, 200,
					  "Um einen Feuerball rast eine Kotkugel, auf der Damenseidenstrümpfe verkauft und Gauguins geschätzt werden."
					+ "\n"
					+ "Ein fürwahr überaus betrüblicher Aspekt, der aber immerhin ein wenig unterschiedlich ist: Seidenstrümpfe können begriffen werden, Gauguins nicht."
				);
				//page.add( new Line("(Bernheim als prestigieuser Biologe zu imaginieren.)") );

				fontProgram.addPage(page 0, 200);
				fontProgram.removePage(line);
				*/
			});

			
			
			
			timer = new Timer(40); zoomIn();
			
		} catch (e:Dynamic) trace("ERROR:", e);
		// ---------------------------------------------------------------
	}

	var isZooming:Bool = false;
	public function zoomIn() {
		var fz:Float = 1.0;		
		timer.run = function() {
			if (isZooming) {
				if (fz < 10.0) fz *= 1.01; else zoomOut();
				display.zoom = fz;
			}
		}
	}
	
	public function zoomOut() {
		var fz:Float = 10.0;
		timer.run = function() {
			if (isZooming) {
				if (fz > 1.0) fz /= 1.01; else zoomIn();
				display.zoom = fz;
			}
		}
	}
	
	public function onPreloadComplete ():Void {
		// sync loading did not work with html5!
		// texture.setImage(Assets.getImage("assets/images/wabbit_alpha.png"));
	}
	
	public function onMouseDown (x:Float, y:Float, button:MouseButton):Void
	{
		isZooming = ! isZooming;
	}
	
	public function onMouseMove (x:Float, y:Float):Void {}
	public function onWindowLeave ():Void {}

	public function onKeyDown (keyCode:KeyCode, modifier:KeyModifier):Void
	{	
		switch (keyCode) {
			case KeyCode.NUMPAD_PLUS:
					if (modifier.shiftKey) peoteView.zoom+=0.01;
					else display.zoom+=0.1;
			case KeyCode.NUMPAD_MINUS:
					if (modifier.shiftKey) peoteView.zoom-=0.01;
					else display.zoom -= 0.1;
			
			case KeyCode.UP: display.yOffset -= (modifier.shiftKey) ? 8 : 1;
			case KeyCode.DOWN: display.yOffset += (modifier.shiftKey) ? 8 : 1;
			case KeyCode.RIGHT: display.xOffset += (modifier.shiftKey) ? 8 : 1;
			case KeyCode.LEFT: display.xOffset -= (modifier.shiftKey) ? 8 : 1;
			default:
		}
	}

	public function render()
	{
		peoteView.render();
	}
	public function update(deltaTime:Int):Void {}
	public function onMouseUp (x:Float, y:Float, button:MouseButton):Void {}

	public function resize(width:Int, height:Int)
	{
		peoteView.resize(width, height);
		display.width  = width - 20;
		display.height = height - 20;
	}

}
#end