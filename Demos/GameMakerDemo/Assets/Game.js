// # API
// toMe() # moves to this node
// to(value) # moves to the node with the given value prefix
// value() # return the string value on the node as set in the scene editor
// x() # x position
// y() # y position
// z() # z position
// ax() # x absolute position
// ay() # y absolute position
// az() # z absolute position
// position(x, y, z) # set position
// rotate(axis, degrees) # rotate the node about it's 0,1,2 x,y,z axis by the given degrees scaled by the elapsed time
// resetRotation() # sets the rotation to the identity rotation
// lookAt(x, y, z, upX, upY, upZ) # points the node at a location with an up orientation
// hide() # makes a node in visible and hidden
// touched() # returns true if a the player has collided with a node and false otherwise
// playSound(name, volume) # plays a wav at a given volume
// startSequence(start, end, speed, looping) # starts a given kfm sequence, if end is < 0 then the end will be set to the last frame
// resetSequence() # resets a kfm sequence
// isDone() # determines if a kfm sequene is node
// pause(paused) # set kfm paused state
// elapsed() # elapsed time of game since last frame
// total() # the total time since the game is running
// print(string) # prints the given string to the console
// createParticles(texture, maxCount, alphaBlend) # create a particle system
// emit(vx, vy, vz, x, y, z, sr, sg, sb, sa, er, eg, eb, ea, sx, sy, ex, ey, ls) # emit a particle
// emitPosition(x, y, z) # set emit position of particles
// rand() # return a random number betweewn 0 and 1
// put(name, value) # put a value
// get(name) # get a value
// setTexture(texture) # set the texture of a key frame mesh or the first part of a mesh
// setDecal(decal) # set the decal of a key frame mesh or the first part of a mesh
// isect() # isect a ray originating at the eye through its forward vector, returns true if a intersetion occured, sets the current node to that intersection
//           # and sets the get values on that node, "_rx", "_ry", "_rz", "_ux", "_uy", "_uz", "_fx", "_fy", "_fz", "_ix", "_iy", "_iz"
//           # to the orientation vectors of the hit triangle and the intersection point
// pushText(text, cols, charW, charH, lineSpacing, x, y, r1, g1, b1, a1, r2, b2, g2, a2)
//           # pushes text sprites to the screen
// pushSprite(sx, sy, sw, sh, dx, dy, dw, dh, r1, g1, b1, a1, r2, g2, b2, a2) # push a sprite to the screen
// hideStats() # hide stats
// width() # pixel width
// height() # pixel height
// viewWidth() # view width
// viewHeight() # view height
// isButtonDown(button) # is a touch or mouse button down
// isKeyDown(key) # is a key down
// mouseX() # location of touch or mouse
// mouseY() # location of touch or mouse
// loadScene(name) # load a scene
// move(dir) # move 0,1,2,3 none,up,down,left,right for top down games
// iOS() # running on iOS
// emitLight(r, g, b, a, radius) # emit light source
// load() # return the text in _data.txt or null if the file does not exist
// save(text) # save the given text to _data.txt
// setBlendState(state) # 0,1,2 opaque,alpha,add
// setZOrder(zOrder) # set z order
// setTintColor(r, g, b, a) # set tint color

if(value() == "spin") {
    rotate(1, 90);
} else if(value().startsWith("player")) {    
    move(0);
    
    var down;
    
    if(down === undefined) {
        down = false;
    }
    
    var key = load();
    
    if(key == null) {
        save("123456");
    } else {
        var p;
        
        if(p === undefined) {
            p = 1;
            print(load());
        }
    }
    
    if(iOS()) {
        var mx = mouseX() - viewWidth() / 2
        var my = mouseY() - viewHeight() / 2
        
        if(isButtonDown(0)) {
            if(Math.abs(my) > Math.abs(mx)) {
                if(my > 0) {
                    move(1);
                } else if(my < 0) {
                    move(2);
                }
            } else {
                if(mx < 0) {
                    move(3);
                } else if(mx > 0) {
                    move(4);
                }
            }
        }
    } else {
        if(isKeyDown(126)) {
            move(1);
        } else if(isKeyDown(125)) {
            move(2);
        } else if(isKeyDown(123)) {
            move(3);
        } else if(isKeyDown(124)) {
            move(4);
        }
    }
    
    if(isKeyDown(49)) {
        if(!down) {
            down = true;
            
            var tokens = value().split('_');
            
            if(tokens[1] == "1") {
                loadScene("scene2.scene");
            } else {
                loadScene("scene1.scene");
            }
        }
    } else {
        down = false;
    }
}
