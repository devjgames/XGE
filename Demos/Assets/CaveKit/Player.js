// player script
//

if(init()) {
	addChild();
	toChild(0);
	setMesh("cube.obj");
	setReceivesLight(false);
	setScale(0.5, 0.5, 0.5);
	toParent();
	addChild();
	toChild(1);
	setMesh("shadowPlane.obj");
	setReceivesLight(false);
	setDepthWriteEnabled(false);
	setBlendEnabled(true);
	setAlphaBlend(true);
	setPosition(0, -8, 0);
	setZOrder(10);
	toParent();
	addChild();
	toChild(2);
	setMesh("energy.obj");
	setReceivesLight(false);
	setDepthWriteEnabled(false);
	setBlendEnabled(true);
	setAlphaBlend(true);
	setZOrder(20);
	toParent();
	getPosition();
	var x = getX();
	var y = getY();
	var z = getZ();
	setCamera(x, y + 200, z + 100, x, y, z, 0, 1, 0);
} else {
	pushText(
		"FPS = " + fps() + "\n" +
		"TRI = " + trianglesRendered() + "\n" +
		"CNT = " + cullStateBinds() + ":" + depthStateBinds() + ":" + renderStateBinds() + ":" + rendered() + "\n" +
		"TST = " + tested(),
		8, 16, 16, 5, 10, 10, 1, 1, 1, 1
	);
	if(!inDesign()) {
		getPosition();
		var x = getX();
		var y = getY();
		var z = getZ();
		getVelocity();
		var vx = 0;
		var vy = getY();
		var vz = 0;
		if(isKeyDown(126)) { // up
			vz = -100
		} else if(isKeyDown(125)) { // down
			vz = 100
		}
		if(isKeyDown(123)) { // left
			vx = -100
		} else if(isKeyDown(124)) { // right
			vx = 100;
		}
		vy -= 2000 * elapsedTime();
		setVelocity(vx, vy, vz);
		toRoot();
		getMin();
		x1 = getX();
		getMax();
		x2 = getX();
		resolve(x, y, z);
		x = getX();
		y = getY();
		z = getZ();
		toMe();
		setPosition(x, y, z);
		x = Math.max(x1 + 300, x);
		x = Math.min(x2 - 300, x);
		setCamera(x, y + 200, z + 100, x, y, z, 0, 1, 0);
		
		toChild(2);
		rotate(1, 90 * elapsedTime());
	}
}

