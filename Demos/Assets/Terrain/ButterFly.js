// butter fly script
//

if(init()) {
	setKFMesh("ButterFly.kfm");
	setKFMeshTexture("ButterFly.png");
	setScale(0.5, 0.5, 0.5);
	setSequence(0, frameCount() - 1, 6, true);
	setReceivesLight(false);
}

