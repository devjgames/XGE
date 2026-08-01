// gem script
//

if(init()) {
	setMesh("gem.obj");
	setAmbientColor(1, 1, 1, 1);
	setCollidable(true);
	addChild();
	toChild(0);
	setMesh("energy.obj");
	setReceivesLight(false);
	setPosition(0, -29, 0);
	setScale(2, 1, 2);
	setDepthWriteEnabled(false);
	setBlendEnabled(true);
	setAlphaBlend(true);
	setZOrder(50);
} else {
	if(!inDesign()) {
		rotate(1, 45 * elapsedTime());
	}
}

