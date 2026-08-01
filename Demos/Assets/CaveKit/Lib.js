// lib script
//

function createFromText(txtFileName) {
	var lines = loadText(txtFileName).split(/\n+/);
	
	for(var i in lines) {
		var tLine = lines[i].trim();
		
		if(tLine != "") {
			var tokens = tLine.split(/\s+/);
			var i = childCount();
			
			addChild();
			toChild(i);
			setMesh(tokens[0]);
			setPosition(
				parseFloat(tokens[1]), 
				parseFloat(tokens[2]), 
				parseFloat(tokens[3])
			);
			setR(
				parseFloat(tokens[4]),
				parseFloat(tokens[5]),
				parseFloat(tokens[6])
			);
			setF(
				parseFloat(tokens[10]),
				parseFloat(tokens[11]),
				parseFloat(tokens[12])
			);
			toParent();
		}
	}
	join();
	setReceivesLight(false);
	setCollidable(true);
}

