// Player.js
//

var game = org.game.Game.getInstance();
var IO = org.game.IO;
var Log = org.game.Log;
var Controller = org.game.Controller;
var Resource = org.game.Resource;

function create(me) {
	me.properties.gravity = -2000;
	me.properties.radius = 16;
	me.properties.speed = 100;
	me.properties.controller = new Controller();
	
	me.propertyNames.add("speed");
	me.propertyNames.add("gravity");
	me.propertyNames.add("radius");
}

function init(me) {
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
}

function update(me) {
	if(me.scene().isInDesign()) {
		return;
	}
	me.properties.controller.update(me.scene());
}

function renderSprites(me, renderer) {
	var sprites = game.getAssets().load(IO.file("sprites.png"));
	var sceneRenderer = game.getSceneRenderer();
	
	renderer.beginSprite(sprites);
	renderer.push(
		"FPS = " + game.frameRate() + "\n" +
		"RES = " + Resource.getInstances() + "\n" +
		"TRI = " + sceneRenderer.getTrianglesRendered() + "\n" +
		"TST = " + me.properties.controller.collider.getTested(),
		16, 16, 8, 5, 10, 10, 1, 1, 1, 1
	);
	renderer.endSprite();
}

function receiveMessage(me, component, type) {
}

function loadSceneName(me) {
    return null;
}