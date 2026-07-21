// main script
//

if(init()) {
	var start = true;
	var sceneName = "scene1.scx"
	var down = false
	
	srand(100);
	
	setBackgroundColor(0, 0, 0, 1);
	setContinuousMouseEnabled(true);
} else {
	if(start) {
		pushText(
			"click to start", 8, 16, 16, 5, viewWidth() / 2 - 7 * 16, viewHeight() / 2 - 8, 1, 1, 1, 1		
		)
		if(isButtonDown(0)) {
			start = false;
			sceneName = load(sceneName);
		}
	} else {
		pushText(
			"FPS = " + fps() + "\n" +
			"TST = " + tested() + "\n" +
			"CNT = " +
				trianglesRendered() + ":" +
				depthStateBinds() + ":" +
				renderStateBinds() + ":" +
				cullStateBinds() + "\n" +
			"SF  = Next, Fire",
			8, 16, 16, 5, 10, 10, 1, 1, 1, 1
		);
		pushSprite(
			22, 2, 1, 1,
			viewWidth() / 2 - 8, viewHeight() / 2 - 1, 16, 2, 1, 1, 1, 1		
		);
		pushSprite(
			22, 2, 1, 1,
			viewWidth() / 2 - 1, viewHeight() / 2 - 8, 2, 16, 1, 1, 1, 1		
		);
		rotateAroundEye(-deltaX(), -deltaY());
		getEye();
		var ex = getX();
		var ey = getY();
		var ez = getZ();
		getTarget();
		var fx = getX() - ex;
		var fy = getY() - ey;
		var fz = getZ() - ez;
		getUp();
		var ux = getX();
		var uy = getY();
		var uz = getZ();
		if(isButtonDown(0)) {
			setForwardVelocity(100);
		} else if(isButtonDown(1)) {
			setForwardVelocity(-100);
		} else {
			setForwardVelocity(0);
		}
		getVelocity();
		setVelocity(getX(), getY() - 2000 * elapsedTime(), getZ());
		resolve(ex, ey, ez);
		ex = getX();
		ey = getY();
		ez = getZ();
		setCamera(ex, ey, ez, ex + fx, ey + fy, ez + fz, ux, uy, uz);

		for(var i = 0; i != childCount(); i++) {
			toChild(i);
			if(name() == "gem.obj" || name() == "energy.obj") {
				rotate(1, 45 * elapsedTime());
			} else if(name() == "door.obj") {
				getEye();
				var ex = getX();
				var ez = getZ();
				getAbsolutePosition();
				var px = getX();
				var pz = getZ();
				var dx = ex - px;
				var dz = ez - pz;
				var d = Math.sqrt(dx * dx + dz * dz);
				var a = 1 - Math.min(d / 100, 1);
				
				getPosition();
				setPosition(getX(), get("y") - a * 300, getZ());
			}
			toParent();
		}
		
		if(isKeyDown(49)) {
			if(!down) {
				down = true;
				sceneName = load(sceneName);
			}
		} else {
			down = false;
		}
	}
}

