// portal script
//

if(init()) {
	setMesh("energy.obj");
	setReceivesLight(false);
	setZOrder(100);
	setDepthWriteEnabled(false);
	setBlendEnabled(true);
	setAlphaBlend(true);
	setScale(2, 1, 2);
} else {
	if(!inDesign()) {
		rotate(1, 45 * elapsedTime());
	}
}

