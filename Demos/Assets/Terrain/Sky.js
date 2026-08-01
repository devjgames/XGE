// sky script
//

if(init()) {
	if(!inDesign()) {
		setMesh("sky.obj");
		setDepthTestEnabled(false);
		setDepthWriteEnabled(false);
		getEye();
		setPosition(getX(), getY(), getZ());
		setZOrder(-1);
		setReceivesLight(false);
	}
} else {
	if(!inDesign()) {
		getEye();
		setPosition(getX(), getY(), getZ());
	}
}

