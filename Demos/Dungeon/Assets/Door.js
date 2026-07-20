// Door.js
//

var game = org.game.Game.getInstance();
var IO = org.game.IO;
var Log = org.game.Log;

function create(me) {
}

function init(me) {
	me.properties._y = me.node().position.y;
}

function start(me) {
}

function update(me) {
	if(me.scene().isInDesign()) {
		return;
	}
	var e = me.scene().eye;
	var p = me.node().position;
	var d = e.distance(p.x, e.y, p.z);
	var a = 1 - Math.min(d / 150, 1);
	
	p.y = me.properties._y - a * 200;
}

function renderSprites(me, renderer) {
}

function receiveMessage(me, component, type) {
}

function loadSceneName(me) {
    return null;
}