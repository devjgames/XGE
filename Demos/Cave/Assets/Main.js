// main script
//

var oy = 200
var oz = 100

if(init()) {
	loadScene("scene1.scx");
	toNamed("canvas");
	calcBoundsAndTransform();
	join();
	setReceivesLight(false);
	setCollidable(true);
	toRoot();
	toNamed("player");
	var x = getX();
	var y = getY();
	var z = getZ();
	setCamera(x, y + oy, z + oz, x, y, z, 0, 1, 0);
} else {
	pushText(
		"FPS = " + fps() + "\n" +
		"TST = " + tested() + "\n" +
		"CNT = " + 
			trianglesRendered() + ":" +
			depthStateBinds() + ":" +
			renderStateBinds() + ":" +
			cullStateBinds(),
		8, 16, 16, 5, 10, 10, 1, 1, 1, 1
	);
	getVelocity();
	setVelocity(0, getY(), 0);
	var vx = 0;
	var vz = 0;
	if(isKeyDown(126)) { // up
		vz = -100;
	} else if(isKeyDown(125)) { // down
		vz = 100;
	}
	if(isKeyDown(123)) { // left
		vx = -100;
	} else if(isKeyDown(124)) { // right
		vx = 100;
	}
	setVelocity(vx, getY() - 2000 * elapsedTime(), vz);
	toNamed("player");	
	getPosition();
	var x = getX();
	var y = getY();
	var z = getZ();
	toChild(2);
	rotate(1, 90 * elapsedTime());
	toRoot();
	resolve(x, y, z);
	x = getX();
	y = getY();
	z = getZ();
	toNamed("player");
	setPosition(x, y, z);
	toRoot();
	getMin();
	var x1 = getX();
	getMax();
	var x2 = getX();
	x = Math.max(x1 + 256 + 64, x);
	x = Math.min(x2 - 256 - 64, x);
	setCamera(x, y + oy, z + oz, x, y, z, 0, 1, 0);
}

