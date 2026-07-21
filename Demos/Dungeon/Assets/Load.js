// load script
//

function load(sceneName) {
	loadScene(sceneName);
	for(var i = 0; i != childCount(); i++) {
		toChild(i);
		if(name() == "Monster.kfm") {
			setSequence(0, frameCount() - 1, 9, true);
		} else if(name() == "player") {
			getR();
			var rx = getX();
			var ry = getY();
			var rz = getZ();
			getU();
			var ux = getX();
			var uy = getY();
			var uz = getZ();
			getPosition();
			var x = getX();
			var y = getY();
			var z = getZ();
			setCamera(x, y, z, x + rx, y + ry, z + rz, ux, uy, uz);
		} else if(name() == "door.obj") {
			getPosition();
			put("y", getY());
		}
		toParent();
	}
	if(sceneName == "scene1.scx") {
		return "scene2.scx";
	}
	return "scene1.scx";
}

