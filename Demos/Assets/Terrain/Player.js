// player script
//

if(init()) {
	if(!inDesign()) {
		getPosition();
		var ex = getX();
		var ey = getY();
		var ez = getZ();
		getR();
		var fx = getX();
		var fy = getY();
		var fz = getZ();
		getU();
		var ux = getX();
		var uy = getY();
		var uz = getZ();
		setCamera(ex, ey, ez, ex + fx, ey + fy, ez + fz, ux, uy, uz);
	}
	setBackgroundColor(0, 0, 0, 1);
} else {
	pushText(
		"FPS = " + fps() + "\n" +
		"TRI = " + trianglesRendered() + "\n" +
		"TST = " + tested(),
		8, 16, 16, 5, 10, 10, 1, 1, 1, 1
	);
	if(!inDesign()) {
		rotateAroundEye(-deltaX(), -deltaY());
		if(isButtonDown(0)) {
			setForwardVelocity(100);
		} else if(isButtonDown(1)) {
			setForwardVelocity(-100);
		} else {
			setForwardVelocity(0);
		}
		getVelocity();
		setVelocity(getX(), getY() - 2000 * elapsedTime(), getZ());
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
		toRoot();
		resolve(ex, ey, ez);
		ex = getX();
		ey = getY();
		ez = getZ();
		setCamera(ex, ey, ez, ex + fx, ey + fy, ez + fz, ux, uy, uz);
	}
}

