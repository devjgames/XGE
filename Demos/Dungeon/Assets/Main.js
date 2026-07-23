// main script
//

if(init()) {
	var start = true;
	var sceneName = "scene1.scx";
	var down = false;
	var s1 = 0.0;
	var s2 = -1.0;
	
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
			} else if(name() == "spell") {
				var ss = 20 + rand() * 40;
				var sc = 0.25 + rand() * 0.5
				var vx = -10 + rand() * 20;
				var vy = -10 + rand() * 20;
				var vz = -10 + rand() * 20;
				
				setEmitPosition(0, Math.sin(totalTime() * 2) * 30, 0);
				emitParticle(
					vx, vy, vz,
					0, 0, 0,
					ss, ss,
					0.1, 0.1,
					sc, sc, sc, 1,
					0, 0, 0, 1,
					0.5 + rand() * 1.5
				);
			} else if(name() == "smoke") {
				if(isKeyDown(3) && s1 > 0.75) { // F
					toRoot();
					setTime(999999);
					if(isect(ex, ey, ez, fx, fy, fz, 0.1, true)) {
						setVolume("fire.wav", 0.1);
						play("fire.wav", false);
						
						var hrx = get("_rx");
						var hry = get("_ry");
						var hrz = get("_rz");
						var hux = get("_ux");
						var huy = get("_uy");
						var huz = get("_uz");
						var hfx = get("_fx");
						var hfy = get("_fy");
						var hfz = get("_fz");
						var hix = ex + time() * fx;
						var hiy = ey + time() * fy;
						var hiz = ez + time() * fz;
						
						s1 = 0.0;
						s2 = 1.0;
						toRoot();
					}	
					toChild(i);		
				}
				s1 += elapsedTime();
				
				if(s2 > 0) {
					var sa = 0.25 + rand() * 0.5;
					var ss = 10 + rand() * 30;
					var vx = 
						(-20 + rand() * 40) * hrx +
						(+10 + rand() * 40) * hux +
						(-20 + rand() * 40) * hfx;
					var vy = 
						(-20 + rand() * 40) * hry +
						(+10 + rand() * 40) * huy +
						(-20 + rand() * 40) * hfy;
					var vz = 
						(-20 + rand() * 40) * hrz +
						(+10 + rand() * 40) * huz +
						(-20 + rand() * 40) * hfz;
						
					emitParticle(
						vx, vy, vz,
						hix + hux * 10, hiy + huy * 10, hiz + huz * 10,
						ss, ss, 
						0.1, 0.1,
						1, 1, 1, sa,
						1, 1, 1, 0,
						0.5 + rand() * 1.5
					);
					s2 -= elapsedTime();
				}
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

