// Player.js
//

var game = org.game.Game.getInstance();
var IO = org.game.IO;
var Log = org.game.Log;
var Controller = org.game.Controller;
var Resource = org.game.Resource;
var Keys = org.game.Keys;
var State = org.game.State;
var AssetManager = org.game.AssetManager;
var Random = java.util.Random;
var Particle = org.game.Particle;
var ParticleSystem = org.game.ParticleSystem;
var Sound = org.game.Sound;
var Vec3 = org.game.Vec3;
var FloatArray = Java.type("float[]");
var Triangle = org.game.Triangle;

function create(me) {
	me.properties.gravity = -2000;
	me.properties.radius = 16;
	me.properties.speed = 100;
	me.properties.controller = new Controller();
	me.properties._loadName = "";
	me.properties._random = new Random(100);
	me.properties._p = new Particle();
	me.properties._o = new Vec3();
	me.properties._d = new Vec3();
	me.properties._t = new FloatArray(1);
	me.properties._triangle = new Triangle();
	me.properties._r = new Vec3();
	me.properties._f = new Vec3();
	me.properties._position = new Vec3();
	me.properties._c1 = 0.0;
	me.properties._c2 = -1.0;
	
	me.propertyNames.add("speed");
	me.propertyNames.add("gravity");
	me.propertyNames.add("radius");
}

function init(me) {
	if(State.properties.get("down") == null) {
		State.properties.put("down", false);
	}
}

function start(me) {
	if(me.scene().isInDesign()) {
		return;
	}
	
	game.setMouseGrabbed(true);
	
	me.properties.controller.gravity = me.properties.gravity;
	me.properties.controller.speed = me.properties.speed;
	me.properties.controller.collider.radius = me.properties.radius;
	
	me.properties.controller.init(me.scene(), me.node());
	
	var node = me.scene().root.find(function(n) {
		if(n.name == "smoke") {
			return true;
		}
		return false;
	});
		
	node.renderable = new ParticleSystem(500);
	node.renderable.texture = game.getAssets().load(IO.file("smoke.png"));
}

function update(me) {
	if(me.scene().isInDesign()) {
		return;
	}
	me.properties.controller.update(me.scene());
	
	var node = me.scene().root.find(function(n) {
		if(n.name == "smoke") {
			return true;
		}
		return false;
	});
	
	var position = me.properties._position;
	
	if(game.keyDown(Keys.KEY_F) && me.properties._c1 > 0.5) {
		var o = me.properties._o;
		var d = me.properties._d;
		var t = me.properties._t;
		var r = me.properties._r;
		var f = me.properties._f;
		var triangle = me.properties._triangle;
		var collider = me.properties.controller.collider;

		o.set(me.scene().eye);
		d.set(me.scene().target).sub(o).normalize();
		t[0] = 999999;
		
		if(collider.intersect(
			me.scene(),
			me.scene().root,
			o,
			d,
			0.1,
			1,
			t,
			false,
			triangle
		)) {
			var sound = game.getAssets().load(IO.file("fire.wav"));
			
			sound.play(false);
			
			triangle.p2.sub(triangle.p1, r).normalize();
			r.cross(triangle.n, f).normalize();
			
			position.set(d).scale(t[0]).add(o);
			
			me.properties._c1 = 0.0;
			me.properties._c2 = 1.0;
		}
	}
	
	me.properties._c1 += game.elapsedTime();
	
	if(me.properties._c2 > 0.0) {
		var r = me.properties._r;
		var u = me.properties._triangle.n;
		var f = me.properties._f;
		var random = me.properties._random;
		var p = me.properties._p;
		var sa = 0.2 + random.nextFloat() * 0.5;
		var ss = 10 + random.nextFloat() * 20;
		var vr = -20 + random.nextFloat() * 40;
		var vu = +10 + random.nextFloat() * 20;
		var vf = -20 + random.nextFloat() * 40;
		
		p.velocityX = r.x * vr + u.x * vu + f.x * vf;
		p.velocityY = r.y * vr + u.y * vu + f.y * vf;
		p.velocityZ = r.z * vr + u.z * vu + f.z * vf;
		p.startX = ss;
		p.startY = ss;
		p.endX = 0.1;
		p.endY = 0.1;
		p.startR = 1;
		p.startG = 1;
		p.startB = 1;
		p.startA = sa;
		p.endR = 1;
		p.endG = 1;
		p.endB = 1;
		p.endA = 0;
		p.positionX = position.x + u.x * ss * 0.5;
		p.positionY = position.y + u.y * ss * 0.5;
		p.positionZ = position.z + u.z * ss * 0.5;
		p.lifeSpan = 0.5 + random.nextFloat() * 1.5;
		
		node.renderable.emit(p);
		
		me.properties._c2 -= game.elapsedTime();
	}
	
	if(game.keyDown(Keys.KEY_SPACE)) {
		if(!State.properties.get("down")) {
			State.properties.put("down", true);
			
			var name = me.scene().getSceneName();
			var i = 1;
			
			while(true) {
				var n = "scene" + i;
				
				if(n == name) {
					n = "scene" + (i + 1);
					
					var f = IO.file(AssetManager.getRoot(), n + ".scx");
					
					if(!f.exists()) {
						n = "scene1";
					}
					me.properties._loadName = n;
					
					break;
				}
				i += 1
			}
		}
	} else {
		State.properties.put("down", false);
	}
}

function renderSprites(me, renderer) {
	var sprites = game.getAssets().load(IO.file("sprites.png"));
	var sceneRenderer = game.getSceneRenderer();
	
	renderer.beginSprite(sprites);
	renderer.push(
		"FPS = " + game.frameRate() + "\n" +
		"RES = " + Resource.getInstances() + "\n" +
		"TRI = " + sceneRenderer.getTrianglesRendered() + "\n" +
		"TST = " + me.properties.controller.collider.getTested() + "\n" +
		"SF  = Next, Fire",
		16, 16, 8, 5, 10, 10, 1, 1, 1, 1
	);
	if(!me.scene().isInDesign()) {
		renderer.push(21, 2, 1, 1, game.w() / 2 - 8, game.h() / 2 - 1, 16, 2, 1, 1, 1, 1, false);
		renderer.push(21, 2, 1, 1, game.w() / 2 - 1, game.h() / 2 - 8, 2, 16, 1, 1, 1, 1, false);
	}
	renderer.endSprite();
}

function receiveMessage(me, component, type) {
}

function loadSceneName(me) {
	if(me.properties._loadName != "") {
    	return me.properties._loadName;
    }
    return null;
}