package;

import haxe.CallStack;

import lime.app.Application;
import lime.ui.Window;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.MouseButton;
import lime.ui.MouseWheelMode;
import lime.graphics.Image;

import peote.view.PeoteView;
import peote.view.Display;
import peote.view.Buffer;
import peote.view.Program;
import peote.view.Color;
import peote.view.Texture;

import peote.view.Element;
import utils.Loader;
import utils.Vec2;


class Boid implements Element
{
	@sizeX @const public var w:Int=13;
	@sizeY @const public var h:Int=32;
	
	@posX public var x:Float; // using 32 bit Float for glBuffer
	@posY public var y:Float;
	
	@rotation public var rot:Float;

	// TODO: public var speed:Vec2;
	public var speedX:Float;
	public var speedY:Float;

	public var pos(get, set):Vec2;
	inline function get_pos():Vec2 return {x:x, y:y};
	inline function set_pos(v:Vec2) { x = v.x; y = v.y; return v; }

	public var speed:Vec2;
	
	public function new(pos:Vec2, ?speed:Vec2) {
		set_pos(pos);
		if (speed != null)
			this.speed = speed;
		else
			this.speed = new Vec2(0, 0); // default speed
	}
}


class Boids extends Application
{
	var peoteView:PeoteView;
	var display:Display;
	var buffer:Buffer<Boid>;
	var program:Program;
	
	var fps:FPS;

	var isStart = false;
	var addingBoids = false;


	// boid simulation parameters:
	var boids = new Array<Boid>();
	var boidCount:Int = 50;
	
	var minX:Int = 0;
	var minY:Int = 0;
	var maxX:Int;
	var maxY:Int;

	var attraction:Float = 0.01; // strength of pull towards centre of mass
	var privateSpace:Float = 100; // amount of space the boids try to get in between them
	var velocityMatching:Float = 0.125;//0.04; // pull in flight direction of other boids
	var speedLimitation:Float = 1000; // limit the speed of the boids
	var pullToCentre:Float = 0.00005; // pull towards centre
	var repulsion:Float = 1; // strength at which boids try to not collide
	
	var scaling:Float = 0.0005; // scale everything down


	override function onWindowCreate():Void
	{
		switch (window.context.type)
		{
			case WEBGL, OPENGL, OPENGLES:
				try startSample(window)
				catch (_) trace(CallStack.toString(CallStack.exceptionStack()), _);
			default: throw("Sorry, only works with OpenGL.");
		}
	}

	public function startSample(window:Window)
	{
		// Vec2.test(); // test the Vec2 helper
		
		fps = new FPS ();

		maxX = window.width;
		maxY = window.height;
		
		peoteView = new PeoteView(window); // at now this should stay first ( to initialize PeoteGL from gl-context! )
        display = new Display(0, 0, maxX, maxY, Color.GREEN);

		Loader.image ("assets/images/boid.png", true, onImageLoad);
	}

    private function onImageLoad(image:Image)
	{
        var texture = new Texture(image.width, image.height);
        texture.setImage(image);

        buffer = new Buffer<Boid>(boidCount, 4096); // automatic grow buffersize about 4096
		program = new Program(buffer); //Sprite buffer
        program.addTexture(texture, "custom"); //Sets image for the sprites
        //program.setVertexFloatPrecision("low");
        //program.setFragmentFloatPrecision("low");

        display.addProgram(program);    // program to display
        peoteView.addDisplay(display);  // display to peoteView

		
		// init Boids
		
 		// scale everything
		attraction = attraction * scaling;
		velocityMatching = velocityMatching * scaling;
		repulsion = repulsion * scaling;

		for (i in 0...boidCount) addBoid ();
        
        isStart = true;
    }
		
	private function addBoid():Void
	{
		var boid = new Boid({
				x: Math.random() * maxX / 4, //Math.random()  * maxX/2
				y: Math.random()*maxY/4      //Math.random()  * maxY/2
		});
		
		// TODO:
		boid.speedX = 0.0;
		boid.speedY = 0.0;
		
		boids.push(boid);
		buffer.addElement(boid);
	}
	

	// ----------- Lime events ------------------

	override function update(deltaTime:Int):Void 
	{
		if (!isStart) return;		

		for (boid in boids) 
		{
			boid.x += boid.speedX;
			boid.y += boid.speedY;
						
			var vChangeX:Float = 0;
			var vChangeY:Float = 0;

			//boid update algorithm
			//1. move to perceived centre of mass
			var cx:Float=0;
			var cy:Float=0;
			var nVic:Float=0;
			
			for (boid2 in boids)
			{
				if (boid != boid2)
				{
						cx=cx+boid2.x;
						cy=cy+boid2.y;
						nVic++;
				}
			}
			
			vChangeX += (cx/nVic-boid.x)*attraction;
			vChangeY += (cy/nVic-boid.y)*attraction;
		
			
			//2. keep distance to other boids
			var rx:Float = 0;
			var ry:Float = 0;

			for (boid2 in boids)
			{
				if (boid != boid2)
				{
					if (Math.sqrt(Math.pow(boid2.x - boid.x,2) + Math.pow(boid2.y - boid.y,2)) < privateSpace)
					{ 
						//trace(boid.x);
						//trace(boid2.x);
						rx=rx-(boid2.x - boid.x);///Math.pow(boid2.x - boid.x,2);
						ry=ry-(boid2.y - boid.y);//Math.pow(boid2.y - boid.y, 2);
					}
				}
			}
			
			vChangeX += rx*repulsion;
			vChangeY += ry*repulsion;
			
			
			//3. match velocity of other adjacent boids
			var vx:Float = 0;
			var vy:Float = 0;
			
			for (boid2 in boids)
			{
				if (boid != boid2)
				{
						vx += boid2.speedX;
						vy += boid2.speedY;
				}
			}
			
			vChangeX += (vx/(boidCount-1) - boid.speedX)*velocityMatching;
			vChangeY += (vy/(boidCount-1) - boid.speedY)*velocityMatching;
			
			
			//accellerate boids to middle of screen // Todo: only if out of borders
			vChangeX += -(boid.x - maxX/2)*pullToCentre;
			vChangeY += -(boid.y - maxY/2)*pullToCentre;
		
			//update velocity
			boid.speedX += vChangeX;
			boid.speedY += vChangeY;
			
			var speed:Float = Math.sqrt(Math.pow(boid.speedX, 2) + Math.pow(boid.speedY, 2));
			
			if (speed > speedLimitation)
			{
				boid.speedX = boid.speedX / speed * speedLimitation;
				boid.speedY = boid.speedY / speed * speedLimitation;
			}
			
			//update orientation
			boid.rot = Math.atan2(boid.speedY, boid.speedX)*180/Math.PI + 90;

		}
		
		if (addingBoids)
		{
			for (i in 0...1) addBoid();	
		}
		
		fps.update (deltaTime);
		
		buffer.update();	
	}

	override function onMouseDown (x:Float, y:Float, button:MouseButton):Void
	{
		addingBoids = true;
	}

	override function onMouseUp (x:Float, y:Float, button:MouseButton):Void
	{
		addingBoids = false;
		trace ('${boids.length} boids @ ${fps.current} FPS');
	}
	
	override function onMouseWheel (dx:Float, dy:Float, mode:MouseWheelMode):Void
	{
		if (dy > 0) display.zoom *= 1.1;
		else if (dy < 0) display.zoom *= 0.9;
	}
	
	override function onKeyDown (keyCode:KeyCode, modifier:KeyModifier):Void
	{
		switch (keyCode) {
			case KeyCode.SPACE: isStart = !isStart;
			case KeyCode.LEFT:  display.xOffset += 30 * display.zoom;
			case KeyCode.RIGHT: display.xOffset -= 30 * display.zoom;
			case KeyCode.UP:    display.yOffset += 30 * display.zoom;
			case KeyCode.DOWN:  display.yOffset -= 30 * display.zoom;
			default:
		}
	}
	
	override function onWindowResize (width:Int, height:Int):Void
	{
		display.width = width;
		display.height = height;
		
		// TODO: update min and max also ?
	}
	

}


// --------------------------------------------

class FPS
{
	public var current (get, null):Int;
	
	private var totalTime:Int;
	private var times:Array<Float>;
		
	public function new () 
	{
		totalTime = 0;
		times = new Array ();
	}
		
	public function update (deltaTime:Int):Void
	{
		totalTime += deltaTime;
		times.push (totalTime);		
	}
	
	private function get_current ():Int
	{
		while (times[0] < totalTime - 1000)
		{			
			times.shift ();		
		}		
		return times.length;
	}	
}
