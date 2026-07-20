// Spell.js
//

var game = org.game.Game.getInstance();
var IO = org.game.IO;
var Log = org.game.Log;
var ParticleSystem = org.game.ParticleSystem;
var Particle = org.game.Particle;
var Random = java.util.Random;

function create(me) {
	me.properties.particle = new Particle();
	me.properties.random = new Random(100);
}

function init(me) {
	me.node().renderable = new ParticleSystem(500); 
	me.node().renderable.texture = game.getAssets().load(IO.file("particle.png"));
}

function start(me) {
}

function update(me) {
	me.node().renderable.emitPosition.y = Math.sin(game.totalTime() * 2) * 50;
	
	var p = me.properties.particle;
	var r = me.properties.random;
	
	for(var i = 0; i != 2; i++) {
		var ss = 20 + r.nextFloat() * 20;
		var es = 1 + r.nextFloat() * 5;
		var sc = 0.5 + r.nextFloat() * 0.5;
		var ec = 0.1 + r.nextFloat() * 0.1;
		
		p.velocityX = -10 + r.nextFloat() * 20;
		p.velocityY = -10 + r.nextFloat() * 20;
		p.velocityZ = -10 + r.nextFloat() * 20;
		p.positionX = 0;
		p.positionY = 0;
		p.positionZ = 0;
		p.lifeSpan = 0.5 + r.nextFloat() * 0.5;
		p.startA = 1;
		p.startR = sc;
		p.startG = sc;
		p.startB = sc;
		p.endA = 1;
		p.endR = ec;
		p.endG = ec;
		p.endB = ec;
		p.startX = ss;
		p.startY = ss;
		p.endX = es;
		p.endY = es;
		
		me.node().renderable.emit(p);
	}
}

function renderSprites(me, renderer) {
}

function receiveMessage(me, component, type) {
}

function loadSceneName(me) {
    return null;
}