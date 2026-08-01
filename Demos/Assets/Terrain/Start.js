// start script
//

if(init()) {
	setBackgroundColor(1, 1, 1, 1);
	if(!inDesign()) {
		setContinuousMouseEnabled(true);
	}
} else {
	if(!inDesign()) {
		pushText(
			"Click to start",
			8, 16, 16, 5, width() / 2 - 7 * 16, height() / 2 - 8, 0, 0, 0, 1
		);
		if(isButtonDown(0)) {
			loadScene("scene2.scene");
		}
	}
}

