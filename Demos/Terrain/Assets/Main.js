// main script
//

if(init()) {
	var start = true;
	
	setBackgroundColor(1, 1, 1, 1);
	setContinuousMouseEnabled(true);
} else {
	if(start) {
		pushText(
			"click to start", 8, 16, 16, 5, viewWidth() / 2 - 7 * 16, viewHeight() / 2 - 8, 0, 0, 0, 1		
		)
		if(isButtonDown(0)) {
			start = false;
			
			loadScene("scene1.scx");
			for(var i = 0; i != childCount(); i++) {
				toChild(i);
				if(name() == "ButterFly.kfm") {
					setSequence(0, frameCount() - 1, 5, true);
				} else if(name() == "player") {
					getR();
					var rx = getX();
					var ry = getY();
					var rz = getZ();
					getU();
					var ux = getX();
					var uy = getY();
					var uz = getZ();
					getPosition();
					var x = getX();
					var y = getY();
					var z = getZ();
					setCamera(x, y, z, x + rx, y + ry, z + rz, ux, uy, uz);
				} else if(name() == "sky.obj") {
					getEye();
					setPosition(getX(), getY(), getZ());
					setZOrder(-1000);
					setDepthWriteEnabled(false);
					setDepthTestEnabled(false);
					setReceivesLight(false);
				}
				toParent();
			}
		}
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
		toNamed("sky.obj");
		setPosition(ex, ey, ez);
	}
}

