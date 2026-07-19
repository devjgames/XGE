// Animation.js
//

var game = org.game.Game.getInstance();
var IO = org.game.IO;
var Log = org.game.Log;
var UIButton = org.game.UIButton;

function create(me) {
	me.properties.speed = 10;
	me.properties.update = new UIButton("Update", function() {
		set(me);
	});
}

function init(me) {
	set(me)
}

function start(me) {
}

function update(me) {
}

function renderSprites(me, renderer) {
}

function receiveMessage(me, component, type) {
}

function loadSceneName(me) {
    return null;
}

function set(me) {	
	me.node().renderable.setSequence(0, me.node().renderable.getFrameCount() - 1, me.properties.speed, true);
}