// Sky.js
//

var game = org.game.Game.getInstance();
var IO = org.game.IO;
var Log = org.game.Log;
var DepthState = org.game.DepthState;

function create(me) {
}

function init(me) {
	if(!me.scene().isInDesign()) {
		me.node().position.set(me.scene().eye);
		me.node().zOrder = -1000;
		me.node().depthState = DepthState.NONE;
	}
}

function start(me) {
}

function update(me) {
	if(!me.scene().isInDesign()) {
		me.node().position.set(me.scene().eye);
	}
}

function renderSprites(me, renderer) {
}

function receiveMessage(me, component, type) {
}

function loadSceneName(me) {
    return null;
}

