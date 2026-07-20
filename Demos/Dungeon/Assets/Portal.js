// Portal.js
//

var game = org.game.Game.getInstance();
var IO = org.game.IO;
var Log = org.game.Log;

function create(me) {
}

function init(me) {
}

function start(me) {
}

function update(me) {
	if(!me.scene().isInDesign()) {
		me.node().rotate(1, 45 * game.elapsedTime());
	}
}

function renderSprites(me, renderer) {
}

function receiveMessage(me, component, type) {
}

function loadSceneName(me) {
    return null;
}

