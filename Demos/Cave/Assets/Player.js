// Player.js
//

var game = org.game.Game.getInstance();
var IO = org.game.IO;
var Log = org.game.Log;
var Resource = org.game.Resource;
var Collider = org.game.Collider;
var Keys = org.game.Keys;

function create(me) {
	me.properties._collider = new Collider();
	me.properties._collider.radius = 8;
}

function init(me) {
	if(!me.scene().isInDesign()) {
		me.scene().target.set(me.node().position.x, 0, me.node().position.z);
		me.scene().target.add(0, 200, 100, me.scene().eye);
		me.scene().up.set(0, 1, 0);
	}
}

function start(me) {
}

function update(me) {
	if(!me.scene().isInDesign()) {
		me.properties._collider.velocity.scale(0, 1, 0);
		if(game.keyDown(Keys.KEY_UP)) {
			me.properties._collider.velocity.z = -100;
		} else if(game.keyDown(Keys.KEY_DOWN)) {
			me.properties._collider.velocity.z = 100;
		}
		if(game.keyDown(Keys.KEY_LEFT)) {
			me.properties._collider.velocity.x = -100;
		} else if(game.keyDown(Keys.KEY_RIGHT)) {
			me.properties._collider.velocity.x = 100;
		}
		me.properties._collider.velocity.y -= 2000 * game.elapsedTime();
		me.properties._collider.resolve(me.scene(), me.scene().root, me.node().position);
		var x = me.node().position.x;
		var z = me.node().position.z;
		x = Math.max(me.scene().root.bounds.min.x + 256, x);
		x = Math.min(me.scene().root.bounds.max.x - 256, x);
		me.scene().target.set(x, 0, z);
		me.scene().target.add(0, 200, 100, me.scene().eye);
		me.node().getChild(2).rotate(1, 90 * game.elapsedTime());
	}
}

function renderSprites(me, renderer) {
	var sceneRenderer = game.getSceneRenderer();
	var font = game.getAssets().load(IO.file("sprites.png"));
	
	renderer.beginSprite(font);
	renderer.push(
		"FPS = " + game.frameRate() + "\n" +
		"TRI = " + sceneRenderer.getTrianglesRendered() + "\n" +
		"RES = " + Resource.getInstances() + "\n" + 
		"TST = " + me.properties._collider.getTested(),
		16, 16, 8, 5, 10, 10, 1, 1, 1, 1
	);
	renderer.endSprite();
}

function receiveMessage(me, component, type) {
}

function loadSceneName(me) {
    return null;
}

