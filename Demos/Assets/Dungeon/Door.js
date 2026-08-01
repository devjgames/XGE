// door script
//

if(init()) {
	setMesh("door.obj")
	setCollidable(true);
	setDynamic(true);
	getPosition();
	var py = getY();
} else {
	if(!inDesign()) {
		getEye();
		var ex = getX();
		var ez = getZ();
		getPosition();
		var px = getX();
		var pz = getZ();
		var dx = ex - px;
		var dz = ez - pz;
		var ln = Math.sqrt(dx * dx + dz * dz);
		var at = 1 - Math.min(ln / 150, 1);
		
		setPosition(px, py - at * 300, pz);
	}
}

