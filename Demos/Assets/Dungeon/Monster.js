// monster script
//

if(init()) {
	setKFMesh("Monster.kfm");
	setKFMeshTexture("Monster.png");
	setCollidable(true);
	setDynamic(true);
	setSequence(0, frameCount() - 1, 9, true);
	put("energy", 6);
}

