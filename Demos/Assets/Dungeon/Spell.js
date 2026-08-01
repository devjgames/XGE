// spell script
//

if(init()) {
	setParticles(500, "particle.png");
	setZOrder(100);
	setDepthWriteEnabled(false);
	setBlendEnabled(true);
	setAlphaBlend(false);
	srand(100);
} else {
	var vx = -10 + rand() * 20;
	var vy = -10 + rand() * 20;
	var vz = -10 + rand() * 20;
	var sx = 20 + rand() * 20;
	var sy = 20 + rand() * 20;
	var ex = 1 + rand();
	var ey = 1 + rand();
	var sc = 0.5 + rand() * 0.5;
	var ec = 0.1 + rand() * 0.1;
	var ls = 0.5 + rand() * 1.5;
	var py = Math.sin(totalTime() * 2) * 50;
	
	setEmitPosition(0, py, 0);
	emitParticle(vx, vy, vz, 0, 0, 0, sx, sy, ex, ey, sc, sc, sc, 1, ec, ec, ec, 1, ls);
}

