// Rotate.js
//

var game = org.game.Game.getInstance();
var IO = org.game.IO;
var Log = org.game.Log;

function create(me) {
	me.properties.velocity = 45;
}

function init(me) {
}

function start(me) {
}

function update(me) {
	if(me.scene().isInDesign()) {
		return;
	}
	me.node().rotate(1, me.properties.velocity * game.elapsedTime());
}

function renderSprites(me, renderer) {
}

function receiveMessage(me, component, type) {
}

function loadSceneName(me) {
    return null;
}