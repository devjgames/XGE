// player script
//

if(init()) {
	if(!inDesign()) {
		getR();
		var fx = getX();
		var fy = getY();
		var fz = getZ();
		getU();
		var ux = getX();
		var uy = getY();
		var uz = getZ();
		getPosition();
		var x = getX();
		var y = getY();
		var z = getZ();
		setCamera(x, y, z, x + fx, y + fy, z + fz, ux, uy, uz);
		setBackgroundColor(0, 0, 0, 1);
		var s1 = 0.0;
		var s2 = -1.0;
		
		toRoot();
		var i = childCount();
		addChild();
		toChild(i);
		setParticles(500, "smoke.png");
		setAmbientColor(0.2, 0.2, 0.2, 1);
		setDiffuseColor(0.2, 0.2, 0.2, 1);
		setDepthWriteEnabled(false);
		setBlendEnabled(true);
		setAlphaBlend(true);
		setZOrder(200);
		srand(100);
		
		var irx = 0;
		var iry = 0;
		var irz = 0;
		var iux = 0;
		var iuy = 0;
		var iuz = 0;
		var ipx = 0;
		var ipy = 0;
		var ipz = 0;
	}
} else {
	if(!inDesign()) {
		pushText(
			"FPS = " + fps() + "\n" +
			"TRI = " + trianglesRendered() + "\n" +
			"TST = " + tested() + "\n" +
			"SF  = Next, Fire",
  			8, 16, 16, 5, 10, 10, 1, 1, 1, 1
			)
		pushSprite(
			22, 2, 1, 1, 
			viewWidth() / 2 - 8, viewHeight() / 2 - 1, 16, 2, 1, 1, 1, 1
		);
		pushSprite(
			22, 2, 1, 1, 
			viewWidth() / 2 - 1, viewHeight() / 2 - 8, 2, 16, 1, 1, 1, 1
		);
		rotateAroundEye(-deltaX(), -deltaY());
		toState();
		if(isKeyDown(49)) {
			if(!get("down")) {
				put("down", true);
				if(sceneName() == "scene2.scene") {
					loadScene("scene3.scene");
				} else {
					loadScene("scene2.scene");
				}
			}
		} else {
			put("down", false);
		}
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
		fx = getX() - ex;
		fy = getY() - ey;
		fz = getZ() - ez;
		getUp();
		ux = getX();
		uy = getY();
		uz = getZ();
		toRoot();
		resolve(ex, ey, ez);
		ex = getX();
		ey = getY();
		ez = getZ();
		setCamera(ex, ey, ez, ex + fx, ey + fy, ez + fz, ux, uy, uz);
		
		var ox = ex;
		var oy = ey;
		var oz = ez;
		var dx = fx;
		var dy = fy;
		var dz = fz;
		
		if(isKeyDown(3) && s1 > 0.5) {
			toRoot();
			setTime(999999);
			if(isect(ox, oy, oz, dx, dy, dz, 0.1, true)) {
				irx = get("_rx");
				iry = get("_ry");
				irz = get("_rz");
				iux = get("_ux");
				iuy = get("_uy");
				iuz = get("_uz");
				ifx = get("_fx");
				ify = get("_fy");
				ifz = get("_fz");
				ipx = ox + time() * dx;
				ipy = oy + time() * dy;
				ipz = oz + time() * dz;
				setVolume("fire.wav", 0.1);
				play("fire.wav", false);
				s1 = 0;
				s2 = 1;
			}
		}
		s1 += elapsedTime();
		toRoot();
		toChild(i);
		if(s2 > 0.0) {
			var sa = 0.2 + rand() * 0.5;
			var ss = 10 + rand() * 20;
			var ri = -10 + rand() * 20;
			var ui = rand() * 10;
			var fi = -10 + rand() * 20;
			var vx = ri * irx + ui * iux + fi * ifx;
			var vy = ri * iry + ui * iuy + fi * ify;
			var vz = ri * irz + ui * iuz + fi * ifz;
			
			emitParticle(
				vx, vy, vz,
				ipx + iux * ss * 0.5,
				ipy + iuy * ss * 0.5,
				ipz + iuz * ss * 0.5,
				ss,
				ss,
				0.1,
				0.1,
				1, 1, 1, sa, 
				1, 1, 1, 0,
				0.5 + rand() * 1.5
			);
			s2 -= elapsedTime();
		}
	} else {
			pushText(
				"FPS = " + fps() + "\n" +
				"TRI = " + trianglesRendered() + "\n",
				8, 16, 16, 5, 10, 10, 1, 1, 1, 1
				)
	}
}

