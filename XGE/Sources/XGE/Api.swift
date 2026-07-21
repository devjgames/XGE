//
//  Api.swift
//  XGE
//
//  This source is protected by a custom EULA see CodingEULA.rtf for details
//

import AVFoundation
import Metal
import MetalKit
import simd
import Foundation
import JavaScriptCore


@MainActor
public class Api {
    
    private var _current:Node?
    private var _buffer = Vec4(0, 0, 0, 0)
    private var _collider = Collider()
    private var _time:Float = 0
    private var _graphic:Encodable?
    private var _context:JSContext?
    private var _main:String?
    private var _init = false
    
    public init() {
    }
    
    private func raiseError(_ message: String) {
        if let context = JSContext.current() {
            let error = JSValue(newErrorFromMessage: message, in: context)
            
            context.exception = error
        }
        Log.instance.put("ERROR without context - \(message)")
    }
    
    public func compile() {
        do {
            _context = nil
            
            let items = try FileManager.default.contentsOfDirectory(atPath: AssetManager.rootURL!.path)
            
            _context = JSContext()
            
            if let context = _context {
                
                setApi()
                
                context.exceptionHandler = { context, exception in
                    if let exception = exception {
                        Log.instance.put("ERROR ->")
                        Log.instance.put(exception.toString()!)
                    }
                }
                
                for item in items {
                    if (item as NSString).pathExtension == "js" {
                        if (item as NSString).lastPathComponent == "Main.js" {
                            Log.instance.put("loading Main.js")
                            _main = try String(contentsOf: AssetManager.rootURL!.appending(path: item), encoding: .utf8)
                        } else {
                            Log.instance.put("evalulating - \((item as NSString).lastPathComponent)")
                            context.evaluateScript(try String(contentsOf: AssetManager.rootURL!.appending(path: item), encoding: .utf8))
                        }
                    }
                }
            }
        } catch {
            Log.instance.put(error.localizedDescription)
        }
    }
    
    func setRoot() {
        _current = GameView.instance!.scene.root
    }
    
    public func eval(isInit:Bool) {
        _init = isInit
        
        if _init {
            _collider = Collider()
        }
        
        if let context = _context {
            if let main = _main {
                _current = GameView.instance!.scene.root
                _time = 0
                _buffer = Vec4(0, 0, 0, 0)
                _graphic = nil
                
                context.evaluateScript(main)
            }
        }
    }

    
    private func setApi() -> Void {
        
        if let context = _context {
            
            // print(string)
            // print the given string to the console
            let print: @convention(block) (String) -> Void = { arg in Log.instance.put(arg) }
            context.setObject(print, forKeyedSubscript: "print" as NSString)
            
            // init()
            // return true if the script object should be initialized or false for an update frame
            let isInit: @convention(block) () -> Bool = { [weak self] in self!._init }
            context.setObject(isInit, forKeyedSubscript: "init" as NSString)
            
            // srand(seed)
            // seed the random number generator
            let srand: @convention(block) (Int) -> Void = { seed in srand48(seed) }
            context.setObject(srand, forKeyedSubscript: "srand" as NSString)
            
            // rand()
            // return a random number between 0 and 1
            let rand: @convention(block) () -> Float = {
                Float(drand48())
            }
            context.setObject(rand, forKeyedSubscript: "rand" as NSString)
            
            // viewWidth()
            // return the width of the game view
            let viewWidth: @convention(block) () -> Int = { Int(GameView.instance!.frame.size.width) }
            context.setObject(viewWidth, forKeyedSubscript: "viewWidth" as NSString)
            
            // viewHeight()
            // return the height of the game view
            let viewHeight: @convention(block) () -> Int = { Int(GameView.instance!.frame.size.height) }
            context.setObject(viewHeight, forKeyedSubscript: "viewHeight" as NSString)
            
            // width()
            // return the width of the game view's drawable
            let width: @convention(block) () -> Int = { Int(GameView.instance!.drawableSize.width) }
            context.setObject(width, forKeyedSubscript: "width" as NSString)
            
            // height()
            // return the height of the game view's drawable
            let height: @convention(block) () -> Int = { Int(GameView.instance!.drawableSize.height) }
            context.setObject(height, forKeyedSubscript: "height" as NSString)
            
            // mouseX()
            // return the x location of the game view's mouse in view coordinates
            let mouseX: @convention(block) () -> Float = { GameView.instance!.mouseX }
            context.setObject(mouseX, forKeyedSubscript: "mouseX" as NSString)
            
            // mouseY()
            // return the y location of the game view's mouse in view coordinates
            let mouseY: @convention(block) () -> Float = { GameView.instance!.mouseY }
            context.setObject(mouseY, forKeyedSubscript: "mouseY" as NSString)
            
            // deltaX()
            // return the game view's mouse x delta
            let deltaX: @convention(block) () -> Float = { GameView.instance!.deltaX }
            context.setObject(deltaX, forKeyedSubscript: "deltaX" as NSString)
            
            // deltaY()
            // return the game view's mouse y delta
            let deltaY: @convention(block) () -> Float = { GameView.instance!.deltaY }
            context.setObject(deltaY, forKeyedSubscript: "deltaY" as NSString)
            
            // isButtonDown(button)
            // determine if the given button is currently down
            let isButtonDown: @convention(block) (Int) -> Bool = { button in GameView.instance!.isButtonDown(button: button) }
            context.setObject(isButtonDown, forKeyedSubscript: "isButtonDown" as NSString)
            
            // isKeyDown(key)
            // determine if the given key is currently down
            let isKeyDown: @convention(block) (Int) -> Bool = { key in GameView.instance!.isKeyDown(key: key) }
            context.setObject(isKeyDown, forKeyedSubscript: "isKeyDown" as NSString)
            
            // elapsedTime()
            // return the elapsed time in seconds since the last update
            let elapsedTime: @convention(block) () -> Float = { GameView.instance!.elapsedTime }
            context.setObject(elapsedTime, forKeyedSubscript: "elapsedTime" as NSString)
            
            // totalTime()
            // return the total time in seconds since the last scene load or last resetTimer
            let totalTime: @convention(block) () -> Float = { GameView.instance!.totalTime }
            context.setObject(totalTime, forKeyedSubscript: "totalTime" as NSString)
            
            // resetTimer()
            // reset the game timer
            let resetTimer: @convention(block) () -> Void = { GameView.instance!.resetTimer() }
            context.setObject(resetTimer, forKeyedSubscript: "resetTimer" as NSString)
            
            // fps()
            // return the frames per second the game is running at
            let fps: @convention(block) () -> Int = { GameView.instance!.fps }
            context.setObject(fps, forKeyedSubscript: "fps" as NSString)
            
            // setContinuousMouseEnabled(enabled)
            // set the continuous mouse enabled state
            let setContinuousMouseEnabled: @convention(block) (Bool) -> Void = { enabled in GameView.instance!.continuousMouseEnabled = enabled }
            context.setObject(setContinuousMouseEnabled, forKeyedSubscript: "setContinuousMouseEnabled" as NSString)
            
            // getX()
            // return the x component of the vector buffer
            let getX: @convention(block) () -> Float = { [weak self] in self!._buffer.x }
            context.setObject(getX, forKeyedSubscript: "getX" as NSString)
            
            // getY()
            // return the y component of the vector buffer
            let getY: @convention(block) () -> Float = { [weak self] in self!._buffer.y }
            context.setObject(getY, forKeyedSubscript: "getY" as NSString)
            
            // getZ()
            // return the z component of the vector buffer
            let getZ: @convention(block) () -> Float = { [weak self] in self!._buffer.z }
            context.setObject(getZ, forKeyedSubscript: "getZ" as NSString)
            
            // getW()
            // return the w component of the vector buffer
            let getW: @convention(block) () -> Float = { [weak self] in self!._buffer.w }
            context.setObject(getW, forKeyedSubscript: "getW" as NSString)
            
            // newScene()
            // create a new scene
            let newScene: @convention(block) () -> Void = { [weak self] in GameView.instance!.newScene(api:self!) }
            context.setObject(newScene, forKeyedSubscript: "newScene" as NSString)
            
            // loadScene(name)
            // load and scx scene file
            let loadScene: @convention(block) (String) -> Void = { [weak self] name in
                do {
                    GameView.instance!.newScene(api: self!)
                    loadSCX(name: name)
                } catch {
                    self!.raiseError(error.localizedDescription)
                }
            }
            context.setObject(loadScene, forKeyedSubscript: "loadScene" as NSString)
            
            // setBackgroundColor(r, g, b, a)
            // set the rgba background color of the scene
            let setBackgroundColor: @convention(block) (Float, Float, Float, Float) -> Void = { r, g, b, a in
                GameView.instance!.scene.backgroundColor = Vec4(r, g, b, a)
            }
            context.setObject(setBackgroundColor, forKeyedSubscript: "setBackgroundColor" as NSString)
            
            // setCamera(ex, ey, ez, tx, ty, tz, ux, uy, uz)
            // set the look at camera's eye, target and up vectors
            let setCamera: @convention(block) (Float, Float, Float, Float, Float, Float, Float, Float, Float) -> Void = { ex, ey, ez, tx, ty, tz, ux, uy, uz in
                GameView.instance!.scene.eye = Vec3(ex, ey, ez)
                GameView.instance!.scene.target = Vec3(tx, ty, tz)
                GameView.instance!.scene.up = Vec3(ux, uy, uz)
            }
            context.setObject(setCamera, forKeyedSubscript: "setCamera" as NSString)
            
            // getEye()
            // set the vector buffer's xyz components to the xyz of the look at camera's eye
            let getEye: @convention(block) () -> Void = { [weak self] in self!._buffer = Vec4(GameView.instance!.scene.eye, 0) }
            context.setObject(getEye, forKeyedSubscript: "getEye" as NSString)
            
            // getTarget()
            // set the vector buffer's xyz components to the xyz of the look at camera's target
            let getTarget: @convention(block) () -> Void = { [weak self] in self!._buffer = Vec4(GameView.instance!.scene.target, 0) }
            context.setObject(getTarget, forKeyedSubscript: "getTarget" as NSString)
            
            // getUp()
            // set the vector buffer's xyz components to the xyz of the look at camera's up
            let getUp: @convention(block) () -> Void = { [weak self] in self!._buffer = Vec4(GameView.instance!.scene.up, 0) }
            context.setObject(getUp, forKeyedSubscript: "getUp" as NSString)
            
            // setProjection(fieldOfViewDegrees, zNear, zFar)
            // set the scene camera's projection
            let setProjection: @convention(block) (Float, Float, Float) -> Void = { fieldOfViewDegrees, zNear, zFar in
                GameView.instance!.scene.fieldOfView = fieldOfViewDegrees
                GameView.instance!.scene.zNear = zNear
                GameView.instance!.scene.zFar = zFar
            }
            context.setObject(setProjection, forKeyedSubscript: "setProjection" as NSString)
            
            // rotateAroundEye(dx, dy)
            // rotate the look at camera around the eye, by the given y axis dx amount and right axis dy amount
            let rotateAroundEye: @convention(block) (Float, Float) -> Void = { dX, dY in GameView.instance!.scene.rotateAroundEye(dx: dX, dy: dY) }
            context.setObject(rotateAroundEye, forKeyedSubscript: "rotateAroundEye" as NSString)
            
            // trianglesRendered()
            // return the number of triangles rendered by the scene in the last update
            let trianglesRendered: @convention(block) () -> Int = { GameView.instance!.scene.trianglesRendered }
            context.setObject(trianglesRendered, forKeyedSubscript: "trianglesRendered" as NSString)
            
            // cullStateBinds()
            // return the number of cull state binds in the last frame
            let cullStateBinds: @convention(block) () -> Int = { GameView.instance!.scene.cullStateBinds }
            context.setObject(cullStateBinds, forKeyedSubscript: "cullStateBinds" as NSString)
            
            // depthStateBinds()
            // return the number of depth state binds in the last frame
            let depthStateBinds: @convention(block) () -> Int = { GameView.instance!.scene.depthStateBinds }
            context.setObject(depthStateBinds, forKeyedSubscript: "depthStateBinds" as NSString)
            
            // renderStateBinds()
            // return the number of render state binds in the last frame
            let renderStateBinds: @convention(block) () -> Int = { GameView.instance!.scene.renderStateBinds }
            context.setObject(renderStateBinds, forKeyedSubscript: "renderStateBinds" as NSString)
            
            // rendered()
            // return the number of objects rendered in the last frame
            let rendered: @convention(block) () -> Int = { GameView.instance!.scene.rendered }
            context.setObject(rendered, forKeyedSubscript: "rendered" as NSString)
            
            // pushSprite(sx, sy, sw, sh, dx, dy, dw, dh, r, g, b, a)
            // push a sprite, in the asset sprites.png, taken from the given source rectangle, and placed at the given destination rectangle, tinted
            // with the given rgba color
            let pushSprite: @convention(block) (Int, Int, Int, Int, Int, Int, Int, Int, Float, Float, Float, Float) -> Void = {
                sx, sy, sw, sh, dx, dy, dw, dh, r, g, b, a in
                
                if let sprite = GameView.instance!.scene.sprite {
                    sprite.push(sx, sy, sw, sh, dx, dy, dw, dh, Vec4(r, g, b, a))
                }
            }
            context.setObject(pushSprite, forKeyedSubscript: "pushSprite" as NSString)
            
            // pushText(text, cols, charW, charH, lineSpacing, x, y, r, g, b, a)
            // push a text sprite, in the asset sprites.png, with the given text, where the sprite characters are divided up by the given columns, where each
            // sprite character has the given charW and charH, where new lines in the text will be spaced by the given line spacing, and the text will be drawn
            // at the given xy location and tinted with the given rgba color
            let pushText: @convention(block) (String, Int, Int, Int, Int, Int, Int, Float, Float, Float, Float) -> Void = {
                text, cols, charW, charH, lineSpacing, x, y, r, g, b, a in
                
                if let sprite = GameView.instance!.scene.sprite {
                    sprite.push(text, cols, charW, charH, lineSpacing, x, y, Vec4(r, g, b, a))
                }
            }
            context.setObject(pushText, forKeyedSubscript: "pushText" as NSString)
            
            // onGround()
            // return the on ground state of the collider
            let onGround: @convention(block) () -> Bool = { [weak self] in self!._collider.onGround }
            context.setObject(onGround, forKeyedSubscript: "onGround" as NSString)
            
            // hitRoof()
            // return the hit roof state of the collider
            let hitRoof: @convention(block) () -> Bool = { [weak self] in self!._collider.hitRoof }
            context.setObject(hitRoof, forKeyedSubscript: "hitRoof" as NSString)
            
            // tested()
            // return the number of triangles tested in the last collider resolve
            let tested: @convention(block) () -> Int = { [weak self] in self!._collider.tested }
            context.setObject(tested, forKeyedSubscript: "tested" as NSString)
            
            // hitNodeCount()
            // return the number of hit nodes in the last collider resolve
            let hitNodeCount: @convention(block) () -> Int = { [weak self] in self!._collider.hitNodeCount }
            context.setObject(hitNodeCount, forKeyedSubscript: "hitNodeCount" as NSString)
            
            // toHitNode(i)
            // set the current node, to the hit node at the given index, from the last collider resolve
            let toHitNode: @convention(block) (Int) -> Void = { [weak self] i in
                if i >= 0 && i < self!._collider.hitNodeCount {
                    self!._current = self!._collider.hitNodeAt(i)
                } else {
                    self!.raiseError("hit node index out of bounds")
                }
            }
            context.setObject(toHitNode, forKeyedSubscript: "toHitNode" as NSString)
            
            // setForwardVelocity(speedAndDirection)
            // set the forward velocity of the collider to the look at camera's forward direction, with the y component set to zero, and scaled by the given speed
            // and direction
            let setForwardVelocity: @convention(block) (Float) -> Void = { [weak self] speedAndDirection in self!._collider.setForwardVelocity(speedAndDirection: speedAndDirection) }
            context.setObject(setForwardVelocity, forKeyedSubscript: "setForwardVelocity" as NSString)
            
            // setTime(time)
            // set the ray intersection time of the collider to the given time
            let setTime: @convention(block) (Float) -> Void = { [weak self] time in self!._time = time }
            context.setObject(setTime, forKeyedSubscript: "setTime" as NSString)
            
            // time()
            // return the intersection time from the last collider intersection test
            let time: @convention(block) () -> Float = { [weak self] in self!._time }
            context.setObject(time, forKeyedSubscript: "time" as NSString)
            
            // isect(ox, oy, oz, dx, dy, dz, buffer, collidablesOnly)
            // pick the closest node, using a ray with the given origin and direction, buffering triangles by the given buffer amount, including all nodes or only
            // collidable nodes, rooted at the current node, if an intersection occurs then, the current node will be set to the closest intersected node, returns true,
            // and the current node's data variables '_rx', '_ry', '_rz', '_ux', '_uy', '_uz', '_fx', '_fy', '_fz' will be set to the right, up and forward vectors of the hit triangle
            // set and get the intersection time with the time functions
            let isect: @convention(block) (Float, Float, Float, Float, Float, Float, Float, Bool) -> Bool = {
                [weak self] ox, oy, oz, dx, dy, dz, buffer, collidablesOnly in
                
                if let node = self!._collider.isect(root: self!._current!, origin: Vec3(ox, oy, oz), direction: Vec3(dx, dy, dz),
                                                    buffer: buffer, collidablesOnly: collidablesOnly, time: &self!._time) {
                    self!._current = node
                    if let triangle = self!._collider.hitTriangle {
                        let r = simd_normalize(triangle.p2 - triangle.p1)
                        let u = triangle.normal
                        let f = simd_normalize(simd_cross(r, triangle.normal))
                        
                        node.data["_rx"] = r.x
                        node.data["_ry"] = r.y
                        node.data["_rz"] = r.z
                        node.data["_ux"] = u.x
                        node.data["_uy"] = u.y
                        node.data["_uz"] = u.z
                        node.data["_fx"] = f.x
                        node.data["_fy"] = f.y
                        node.data["_fz"] = f.z
                    }
                    return true
                }
                return false
            }
            context.setObject(isect, forKeyedSubscript: "isect" as NSString)
            
            // resolve(x, y, z)
            // resolve a position located at the given xyz location, so that it no longer collides with any node, triangle collidables
            // rooted at the current node, the vector buffer is set to the resolved xyz location
            let resolve: @convention(block) (Float, Float, Float) -> Void = { [weak self] x, y, z in
                let p = self!._collider.resolve(root: self!._current!, position: Vec3(x, y, z))
                
                self!._buffer = Vec4(p, 0)
            }
            context.setObject(resolve, forKeyedSubscript: "resolve" as NSString)
            
            // setRadius(radius)
            // set the collider, resolve radius to the given radius
            let setRadius: @convention(block) (Float) -> Void = { [weak self] radius in self!._collider.radius = radius }
            context.setObject(setRadius, forKeyedSubscript: "setRadius" as NSString)
            
            // radius()
            // return the collider resolve radius
            let radius: @convention(block) () -> Float = { [weak self] in self!._collider.radius }
            context.setObject(radius, forKeyedSubscript: "radius" as NSString)
            
            // setGroundSlope(slope)
            // set the collider, ground slope
            let setGroundSlope: @convention(block) (Float) -> Void = { [weak self] slope in self!._collider.groundSlope = slope }
            context.setObject(setGroundSlope, forKeyedSubscript: "setGroundSlope" as NSString)
            
            // groundSlope()
            // return the collider ground slope
            let groundSlope: @convention(block) () -> Float = { [weak self] in self!._collider.groundSlope }
            context.setObject(groundSlope, forKeyedSubscript: "groundSlope" as NSString)
            
            // setRoofSlope(slope)
            // set the collider, roof slope
            let setRoofSlope: @convention(block) (Float) -> Void = { [weak self] slope in self!._collider.roofSlope = slope }
            context.setObject(setRoofSlope, forKeyedSubscript: "setRoofSlope" as NSString)
            
            // roofSlope()
            // return the collider roof slope
            let roofSlope: @convention(block) () -> Float = { [weak self] in self!._collider.roofSlope }
            context.setObject(roofSlope, forKeyedSubscript: "roofSlope" as NSString)
            
            // setVelocity(x, y, z)
            // set the collider xyz velocity
            let setVelocity: @convention(block) (Float, Float, Float) -> Void = { [weak self] x, y, z in self!._collider.velocity = Vec3(x, y, z) }
            context.setObject(setVelocity, forKeyedSubscript: "setVelocity" as NSString)
            
            // getVelocity()
            // set the xyz components of the vector buffer to the collider's velocity
            let getVelocity: @convention(block) () -> Void = { [weak self] in self!._buffer = Vec4(self!._collider.velocity, 0) }
            context.setObject(getVelocity, forKeyedSubscript: "getVelocity" as NSString)
            
            // calcBoundsAndTransform()
            // calculate the current node's bounds and transform
            let calcBoundsAndTransform: @convention(block) () -> Void = { [weak self] in self!._current!.calcBoundsAndTransform() }
            context.setObject(calcBoundsAndTransform, forKeyedSubscript: "calcBoundsAndTransform" as NSString)
            
            // toNamed(name)
            // set the current node to the descendent node under the current node, with the given name
            // returns true if the descendent node was found and false otherwise
            let toNamed: @convention(block) (String) -> Bool = { [weak self] name in
                if let node = self!._current!.find(name: name) {
                    self!._current = node;
                    return true;
                }
                return false;
            }
            context.setObject(toNamed, forKeyedSubscript: "toNamed" as NSString)
            
            // toRoot()
            // set the current node to the root node of the scene
            let toRoot: @convention(block) () -> Void = { [weak self] in self!._current = GameView.instance!.scene.root }
            context.setObject(toRoot, forKeyedSubscript: "toRoot" as NSString)
            
            // toParent()
            // set the current node to it's parent
            let toParent: @convention(block) () -> Void = { [weak self] in
                if let parent = self!._current!.parent {
                    self!._current = parent
                }
            }
            context.setObject(toParent, forKeyedSubscript: "toParent" as NSString)
            
            // childCount()
            // return the number of children the current node has
            let childCount: @convention(block) () -> Int = { [weak self] in self!._current!.childCount }
            context.setObject(childCount, forKeyedSubscript: "childCount" as NSString)
            
            // toChild(i)
            // set the current node to the it's child node at the given index
            let toChild: @convention(block) (Int) -> Void = { [weak self] i in
                if i >= 0 && i < self!._current!.childCount {
                    self!._current = self!._current![i]
                } else {
                    self!.raiseError("child index out of bounds")
                }
            }
            context.setObject(toChild, forKeyedSubscript: "toChild" as NSString)
            
            // put(name, value)
            // set a variable with the given name, on the current node, to the given value
            let put: @convention(block) (String, Float) -> Void = { [weak self] name, value in
                self!._current!.data[name] = value
            }
            context.setObject(put, forKeyedSubscript: "put" as NSString)
            
            // get(name)
            // return the value of a variable with the given name, on the current node
            // return's null if the variable does not exist yet
            let get: @convention(block) (String) -> Any? = { [weak self] name in
                if let value = self!._current!.data[name] {
                    return value
                }
                return nil
            }
            context.setObject(get, forKeyedSubscript: "get" as NSString)
            
            // addChild()
            // add a child to the current node
            let addChild: @convention(block) () -> Void = { [weak self] in self!._current!.addChild(Node()) }
            context.setObject(addChild, forKeyedSubscript: "addChild" as NSString)
            
            // lookAt(tx, ty, tz, ux, uy, uz)
            // make the current node's oriention, point at the given xyz target using the given xyz up orientation
            let lookAt: @convention(block) (Float, Float, Float, Float, Float, Float) -> Void = { [weak self] tx, ty, tz, ux, uy, uz in
                self!._current!.lookAt(target: Vec3(tx, ty, tz), up: Vec3(ux, uy, uz))
            }
            context.setObject(lookAt, forKeyedSubscript: "lookAt" as NSString)
            
            // rotate(axis, degrees)
            // rotate the current node around the given xyz axis, (0, 1, 2) by the given degrees
            let rotate: @convention(block) (Int, Float) -> Void = { [weak self] axis, degrees in self!._current!.rotate(axis: axis, degrees: degrees) }
            context.setObject(rotate, forKeyedSubscript: "rotate" as NSString)
            
            // name()
            // return the current node's name
            let name: @convention(block) () -> String = { [weak self] in self!._current!.name }
            context.setObject(name, forKeyedSubscript: "name" as NSString)
            
            // setName(name)
            // set the current node's name
            let setName: @convention(block) (String) -> Void = { [weak self] name in self!._current!.name = name }
            context.setObject(setName, forKeyedSubscript: "setName" as NSString)
            
            // visible()
            // return the current node's visible state, the visible state of a node will show or hide all of the node's descendants too
            let visible: @convention(block) () -> Bool = { [weak self] in self!._current!.visible }
            context.setObject(visible, forKeyedSubscript: "visible" as NSString)
            
            // setVisible(visible)
            // set the current node's visible state
            let setVisible: @convention(block) (Bool) -> Void = { [weak self] visible in self!._current!.visible = visible }
            context.setObject(setVisible, forKeyedSubscript: "setVisible" as NSString)
            
            // collidable()
            // return the current node's collidable state
            let collidable: @convention(block) () -> Bool = { [weak self] in self!._current!.collidable }
            context.setObject(collidable, forKeyedSubscript: "collidable" as NSString)
            
            // setCollidable(collidable)
            // set the current node's collidable state
            let setCollidable: @convention(block) (Bool) -> Void = { [weak self] collidable in self!._current!.collidable = collidable }
            context.setObject(setCollidable, forKeyedSubscript: "setCollidable" as NSString)
            
            // dynamic()
            // return the current node's dynamic collidable state
            let dynamic: @convention(block) () -> Bool = { [weak self] in self!._current!.dynamic }
            context.setObject(dynamic, forKeyedSubscript: "dynamic" as NSString)
            
            // setDynamic(dynamic)
            // set the current node's dynamic collidable state
            let setDynamic: @convention(block) (Bool) -> Void = { [weak self] dynamic in self!._current!.dynamic = dynamic }
            context.setObject(setDynamic, forKeyedSubscript: "setDynamic" as NSString)
            
            // emitsLight()
            // return the current node's emit light state
            let emitsLight: @convention(block) () -> Bool = { [weak self] in self!._current!.emitsLight }
            context.setObject(emitsLight, forKeyedSubscript: "emitsLight" as NSString)
            
            // setEmitsLight(emitsLight)
            // set the current node's emit light state
            let setEmitsLight: @convention(block) (Bool) -> Void = { [weak self] emitsLight in self!._current!.emitsLight = emitsLight }
            context.setObject(setEmitsLight, forKeyedSubscript: "setEmitsLight" as NSString)
            
            // receivesLight()
            // return the current node's receive light state
            let receivesLight: @convention(block) () -> Bool = { [weak self] in self!._current!.receivesLight }
            context.setObject(receivesLight, forKeyedSubscript: "receivesLight" as NSString)
            
            // setReceivesLight(receivesLight)
            // set the current node's receive light state
            let setReceivesLight: @convention(block) (Bool) -> Void = { [weak self] receivesLight in self!._current!.receivesLight = receivesLight }
            context.setObject(setReceivesLight, forKeyedSubscript: "setReceivesLight" as NSString)
            
            // blendEnabled()
            // return the current node's blend enabled state
            let blendEnabled: @convention(block) () -> Bool = { [weak self] in self!._current!.blendEnabled }
            context.setObject(blendEnabled, forKeyedSubscript: "blendEnabled" as NSString)
            
            // setBlendEnabled(blendEnabled)
            // set the current node's blend enabled state
            let setBlendEnabled: @convention(block) (Bool) -> Void = { [weak self] blendEnabled in self!._current!.blendEnabled = blendEnabled }
            context.setObject(setBlendEnabled, forKeyedSubscript: "setBlendEnabled" as NSString)
            
            // alphaBlend()
            // return the current node's alpha blend state
            let alphaBlend: @convention(block) () -> Bool = { [weak self] in self!._current!.alphaBlend }
            context.setObject(alphaBlend, forKeyedSubscript: "alphaBlend" as NSString)
            
            // setAlphaBlend(alphaBlend)
            // set the current node's alpha blend state
            let setAlphaBlend: @convention(block) (Bool) -> Void = { [weak self] alphaBlend in self!._current!.alphaBlend = alphaBlend }
            context.setObject(setAlphaBlend, forKeyedSubscript: "setAlphaBlend" as NSString)
            
            // depthWriteEnabled()
            // return the current node's depth write enabled state
            let depthWriteEnabled: @convention(block) () -> Bool = { [weak self] in self!._current!.depthWriteEnabled }
            context.setObject(depthWriteEnabled, forKeyedSubscript: "depthWriteEnabled" as NSString)
            
            // setDepthWriteEnabled(depthWriteEnabled)
            // set the current node's depth write enabled state
            let setDepthWriteEnabled: @convention(block) (Bool) -> Void = { [weak self] depthWriteEnabled in self!._current!.depthWriteEnabled = depthWriteEnabled }
            context.setObject(setDepthWriteEnabled, forKeyedSubscript: "setDepthWriteEnabled" as NSString)
            
            // depthTestEnabled()
            // return the current node's depth test enabled state
            let depthTestEnabled: @convention(block) () -> Bool = { [weak self] in self!._current!.depthTestEnabled }
            context.setObject(depthTestEnabled, forKeyedSubscript: "depthTestEnabled" as NSString)
            
            // setDepthTestEnabled(depthTestEnabled)
            // set the current node's depth test enabled state
            let setDepthTestEnabled: @convention(block) (Bool) -> Void = { [weak self] depthTestEnabled in self!._current!.depthTestEnabled = depthTestEnabled }
            context.setObject(setDepthTestEnabled, forKeyedSubscript: "setDepthTestEnabled" as NSString)
            
            // cullEnabled()
            // return the current node's cull enabled state
            let cullEnabled: @convention(block) () -> Bool = { [weak self] in self!._current!.cullEnabled }
            context.setObject(cullEnabled, forKeyedSubscript: "cullEnabled" as NSString)
            
            // setCullEnabled(cullEnabled)
            // set the current node's cull enabled state
            let setCullEnabled: @convention(block) (Bool) -> Void = { [weak self] cullEnabled in self!._current!.cullEnabled = cullEnabled }
            context.setObject(setCullEnabled, forKeyedSubscript: "setCullEnabled" as NSString)
            
            // warpEnabled()
            // return the current node's warp enabled state
            let warpEnabled: @convention(block) () -> Bool = { [weak self] in self!._current!.warpEnabled }
            context.setObject(warpEnabled, forKeyedSubscript: "warpEnabled" as NSString)
            
            // setWarpEnabled(warpEnabled)
            // set the current node's warp enabled state
            let setWarpEnabled: @convention(block) (Bool) -> Void = { [weak self] warpEnabled in self!._current!.warpEnabled = warpEnabled }
            context.setObject(setWarpEnabled, forKeyedSubscript: "setWarpEnabled" as NSString)
            
            // getPosition()
            // set the vector buffer to the current node's xyz position
            let getPosition: @convention(block) () -> Void = { [weak self] in self!._buffer = Vec4(self!._current!.position, 0) }
            context.setObject(getPosition, forKeyedSubscript: "getPosition" as NSString)
            
            // setPosition(x, y, z)
            // set the current node's position to the given xyz arguments
            let setPosition: @convention(block) (Float, Float, Float) -> Void = { [weak self] x, y, z in self!._current!.position = Vec3(x, y, z) }
            context.setObject(setPosition, forKeyedSubscript: "setPosition" as NSString)
            
            // getAbsolutePosition()
            // set the vector buffer to the current node's xyz absolute position
            let getAbsolutePosition: @convention(block) () -> Void = { [weak self] in self!._buffer = Vec4(self!._current!.absolutePosition, 0) }
            context.setObject(getAbsolutePosition, forKeyedSubscript: "getAbsolutePosition" as NSString)
            
            // getR()
            // set the vector buffer to the current node's xyz right orientation
            let getR: @convention(block) () -> Void = { [weak self] in self!._buffer = Vec4(self!._current!.r, 0) }
            context.setObject(getR, forKeyedSubscript: "getR" as NSString)
            
            // setR(x, y, z)
            // set the current node's xyz right orientation
            let setR: @convention(block) (Float, Float, Float) -> Void = { [weak self] x, y, z in self!._current!.r = simd_normalize(Vec3(x, y, z)) }
            context.setObject(setR, forKeyedSubscript: "setR" as NSString)
            
            // getU()
            // set the vector buffer to the current node's xyz up orientation
            let getU: @convention(block) () -> Void = { [weak self] in self!._buffer = Vec4(self!._current!.u, 0) }
            context.setObject(getU, forKeyedSubscript: "getU" as NSString)
            
            // setU(x, y, z)
            // set the current node's xyz up orientation
            let setU: @convention(block) (Float, Float, Float) -> Void = { [weak self] x, y, z in self!._current!.u = simd_normalize(Vec3(x, y, z)) }
            context.setObject(setU, forKeyedSubscript: "setU" as NSString)
            
            // getF()
            // set the vector buffer to the current node's xyz forward orientation
            let getF: @convention(block) () -> Void = { [weak self] in self!._buffer = Vec4(self!._current!.f, 0) }
            context.setObject(getF, forKeyedSubscript: "getF" as NSString)
            
            // setF(x, y, z)
            // set the current node's xyz forward orientation
            let setF: @convention(block) (Float, Float, Float) -> Void = { [weak self] x, y, z in self!._current!.f = simd_normalize(Vec3(x, y, z)) }
            context.setObject(setF, forKeyedSubscript: "setF" as NSString)
            
            // getScale()
            // set the vector buffer to the current node's xyz scale
            let getScale: @convention(block) () -> Void = { [weak self] in self!._buffer = Vec4(self!._current!.scale, 0) }
            context.setObject(getScale, forKeyedSubscript: "getScale" as NSString)
            
            // setScale(x, y, z)
            // set the current node's xyz scale
            let setScale: @convention(block) (Float, Float, Float) -> Void = { [weak self] x, y, z in self!._current!.scale = Vec3(x, y, z) }
            context.setObject(setScale, forKeyedSubscript: "setScale" as NSString)
            
            // getMin()
            // set the vector buffer to the current node's minimum boundary
            let getMin: @convention(block) () -> Void = { [weak self] in self!._buffer = Vec4(self!._current!.bounds.min, 0) }
            context.setObject(getMin, forKeyedSubscript: "getMin" as NSString)
            
            // getMax()
            // set the vector buffer to the current node's maximum boundary
            let getMax: @convention(block) () -> Void = { [weak self] in self!._buffer = Vec4(self!._current!.bounds.max, 0) }
            context.setObject(getMax, forKeyedSubscript: "getMax" as NSString)
            
            // getAmbientColor()
            // set the vector buffer to the current node's rgba ambient color
            let getAmbientColor: @convention(block) () -> Void = { [weak self] in self!._buffer = self!._current!.ambientColor }
            context.setObject(getAmbientColor, forKeyedSubscript: "getAmbientColor" as NSString)
            
            // setAmbientColor(r, g, b, a)
            // set the current node's rgba ambient color
            let setAmbientColor: @convention(block) (Float, Float, Float, Float) -> Void = { [weak self] r, g, b, a in self!._current!.ambientColor = Vec4(r, g, b, a) }
            context.setObject(setAmbientColor, forKeyedSubscript: "setAmbientColor" as NSString)
            
            // getDiffuseColor()
            // set the vector buffer to the current node's rgba diffuse color
            let getDiffuseColor: @convention(block) () -> Void = { [weak self] in self!._buffer = self!._current!.diffuseColor }
            context.setObject(getDiffuseColor, forKeyedSubscript: "getDiffuseColor" as NSString)
            
            // setDiffuseColor(r, g, b, a)
            // set the current node's rgba diffuse color
            let setDiffuseColor: @convention(block) (Float, Float, Float, Float) -> Void = { [weak self] r, g, b, a in self!._current!.diffuseColor = Vec4(r, g, b, a) }
            context.setObject(setDiffuseColor, forKeyedSubscript: "setDiffuseColor" as NSString)
            
            // getSpecularColor()
            // set the vector buffer to the current node's rgba specular color
            let getSpecularColor: @convention(block) () -> Void = { [weak self] in self!._buffer = self!._current!.specularColor }
            context.setObject(getSpecularColor, forKeyedSubscript: "getSpecularColor" as NSString)
            
            // setSpecularColor(r, g, b, a)
            // set the current node's rgba specular color
            let setSpecularColor: @convention(block) (Float, Float, Float, Float) -> Void = { [weak self] r, g, b, a in self!._current!.specularColor = Vec4(r, g, b, a) }
            context.setObject(setSpecularColor, forKeyedSubscript: "setSpecularColor" as NSString)
            
            // getLightColor()
            // set the vector buffer to the current node's rgba light color
            let getLightColor: @convention(block) () -> Void = { [weak self] in self!._buffer = self!._current!.lightColor }
            context.setObject(getLightColor, forKeyedSubscript: "getLightColor" as NSString)
            
            // setLightColor(r, g, b, a)
            // set the current node's rgba light color
            let setLightColor: @convention(block) (Float, Float, Float, Float) -> Void = { [weak self] r, g, b, a in self!._current!.lightColor = Vec4(r, g, b, a) }
            context.setObject(setLightColor, forKeyedSubscript: "setLightColor" as NSString)
            
            // zOrder()
            // return the z order of the current node
            let zOrder: @convention(block) () -> Int = { [weak self] in self!._current!.zOrder }
            context.setObject(zOrder, forKeyedSubscript: "zOrder" as NSString)
            
            // setZOrder(zOrder)
            // set the current node's z order
            let setZOrder: @convention(block) (Int) -> Void = { [weak self] zOrder in self!._current!.zOrder = zOrder }
            context.setObject(setZOrder, forKeyedSubscript: "setZOrder" as NSString)
            
            // specularPower()
            // return the current node's specular power
            let specularPower: @convention(block) () -> Float = { [weak self] in self!._current!.specularPower }
            context.setObject(specularPower, forKeyedSubscript: "specularPower" as NSString)
            
            // setSpecularPower(specularPower)
            // set the current node's specular power
            let setSpecularPower: @convention(block) (Float) -> Void = { [weak self] specularPower in self!._current!.specularPower = specularPower }
            context.setObject(setSpecularPower, forKeyedSubscript: "setSpecularPower" as NSString)
            
            // warpAmplitude()
            // return the current node's warp amplitude
            let warpAmplitude: @convention(block) () -> Float = { [weak self] in self!._current!.warpAmplitude }
            context.setObject(warpAmplitude, forKeyedSubscript: "warpAmplitude" as NSString)
            
            // setWarpAmplitude(warpAmplitude)
            // set the current node's warp amplitude
            let setWarpAmplitude: @convention(block) (Float) -> Void = { [weak self] warpAmplitude in self!._current!.warpAmplitude = warpAmplitude }
            context.setObject(setWarpAmplitude, forKeyedSubscript: "setWarpAmplitude" as NSString)
            
            // warpFrequency()
            // return the current node's warp frequency
            let warpFrequency: @convention(block) () -> Float = { [weak self] in self!._current!.warpFrequency }
            context.setObject(warpFrequency, forKeyedSubscript: "warpFrequency" as NSString)
            
            // setWarpFrequency(warpFrequency)
            // set the current node's warp frequency
            let setWarpFrequency: @convention(block) (Float) -> Void = { [weak self] warpFrequency in self!._current!.warpFrequency = warpFrequency }
            context.setObject(setWarpFrequency, forKeyedSubscript: "setWarpFrequency" as NSString)
            
            // warpSpeed()
            // return the current node's warp speed
            let warpSpeed: @convention(block) () -> Float = { [weak self] in self!._current!.warpSpeed }
            context.setObject(warpSpeed, forKeyedSubscript: "warpSpeed" as NSString)
            
            // setWarpSpeed(warpSpeed)
            // set the current node's warp speed
            let setWarpSpeed: @convention(block) (Float) -> Void = { [weak self] warpSpeed in self!._current!.warpSpeed = warpSpeed }
            context.setObject(setWarpSpeed, forKeyedSubscript: "setWarpSpeed" as NSString)
            
            // warpY()
            // return the current node's warp y state
            let warpY: @convention(block) () -> Bool = { [weak self] in self!._current!.warpY }
            context.setObject(warpY, forKeyedSubscript: "warpY" as NSString)
            
            // setWarpY(warpY)
            // set the current node's warp y state
            let setWarpY: @convention(block) (Bool) -> Void = { [weak self] warpY in self!._current!.warpY = warpY }
            context.setObject(setWarpY, forKeyedSubscript: "setWarpY" as NSString)
            
            // lightRadius()
            // return the current node's light radius
            let lightRadius: @convention(block) () -> Float = { [weak self] in self!._current!.lightRadius }
            context.setObject(lightRadius, forKeyedSubscript: "lightRadius" as NSString)
            
            // setLightRadius(radius)
            // set the current node's light radius
            let setLightRadius: @convention(block) (Float) -> Void = { [weak self] lightRadius in self!._current!.lightRadius = lightRadius }
            context.setObject(setLightRadius, forKeyedSubscript: "setLightRadius" as NSString)
            
            // getGraphic()
            // cache the current node's graphic
            let getGraphic: @convention(block) () -> Void = { [weak self] in self!._graphic = self!._current!.encodable }
            context.setObject(getGraphic, forKeyedSubscript: "getGraphic" as NSString)
            
            // setGraphic(cloneMesh)
            // set the current node's graphic to the cached graphic, if the graphic is a mesh, clone the mesh if clone mesh is true
            let setGraphic: @convention(block) (Bool) -> Void = { [weak self] cloneMesh in
                if let mesh = self!._graphic as? Mesh {
                    if cloneMesh {
                        self!._current!.encodable = mesh.newInstance()
                    } else {
                        self!._current!.encodable = mesh
                    }
                } else if let graphic = self!._graphic {
                    self!._current!.encodable = graphic.newInstance()
                }
            }
            context.setObject(setGraphic, forKeyedSubscript: "setGraphic" as NSString)
            
            // clearGraphic()
            // clear the current node's graphic
            let clearGraphic: @convention(block) () -> Void = { [weak self] in self!._current!.encodable = nil }
            context.setObject(clearGraphic, forKeyedSubscript: "clearGraphic" as NSString)
            
            // hasGraphic()
            // return true if the current node has a graphic and false otherwise
            let hasGraphic: @convention(block) () -> Bool = { [weak self] in self!._current!.encodable != nil }
            context.setObject(hasGraphic, forKeyedSubscript: "hasGraphic" as NSString)
            
            // isAsset(name)
            // return true if the given name is an asset or false otherwise
            let isAsset: @convention(block) (String) -> Bool = { name in GameView.instance!.assets.assetExists(path: name) }
            context.setObject(isAsset, forKeyedSubscript: "isAsset" as NSString)
            
            // saveText(text, name)
            // save the given text to the given asset
            let saveText: @convention(block) (String, String) -> Void = { [weak self] text, name in
                do {
                    if (name as NSString).pathExtension == "txt" {
                        try text.write(to: AssetManager.rootURL!.appending(path: name), atomically: true, encoding: .ascii)
                    } else {
                        Log.instance.put("not a txt file")
                    }
                } catch {
                    self!.raiseError(error.localizedDescription)
                }
            }
            context.setObject(saveText, forKeyedSubscript: "saveText" as NSString)
            
            // loadText(name)
            // return the text loaded from the given asset
            let loadText: @convention(block) (String) -> String = { [weak self] name in
                var txt = ""
                
                do {
                    txt = try String(contentsOf: AssetManager.rootURL!.appending(path: name), encoding: .ascii)
                } catch {
                    self!.raiseError(error.localizedDescription)
                }
                return txt
            }
            context.setObject(loadText, forKeyedSubscript: "loadText" as NSString)
            
            // setMesh(fileName)
            // set the graphic of the current node, to the given obj file name
            let setMesh: @convention(block) (String) -> Void = { [weak self] fileName in
                do {
                    self!._current!.encodable = try GameView.instance!.assets.load(path: fileName) as? Encodable
                } catch {
                    self!.raiseError(error.localizedDescription)
                }
            }
            context.setObject(setMesh, forKeyedSubscript: "setMesh" as NSString)
            
            // partCount()
            // return the number of parts in the current node's mesh
            let partCount: @convention(block) () -> Int = { [weak self] in
                if let mesh = self!._current!.encodable as? Mesh {
                    return mesh.parts.count
                }
                return 0
            }
            context.setObject(partCount, forKeyedSubscript: "partCount" as NSString)
            
            // partName(part)
            // return the name of the given part in the current node's mesh, or null if the current node does not have a mesh
            let partName: @convention(block) (Int) -> String? = { [weak self] i in
                if let mesh = self!._current!.encodable as? Mesh {
                    if i >= 0 && i < mesh.parts.count {
                        return mesh.parts[i].name;
                    } else {
                        self!.raiseError("part index out of bounds")
                    }
                }
                return nil
            }
            context.setObject(partName, forKeyedSubscript: "partName" as NSString)
            
            // setMeshTexture(part, fileName)
            // set the current node's mesh part texture to the given png file name
            let setMeshTexture: @convention(block) (Int, String) -> Void = { [weak self] part, fileName in
                if let mesh = self!._current!.encodable as? Mesh {
                    if part >= 0 && part < mesh.parts.count {
                        do {
                            mesh.parts[part].texture = try GameView.instance!.assets.load(path: fileName) as? MTLTexture
                        } catch {
                            self!.raiseError(error.localizedDescription)
                        }
                    } else {
                        self!.raiseError("part index out of bounds")
                    }
                }
            }
            context.setObject(setMeshTexture, forKeyedSubscript: "setMeshTexture" as NSString)
            
            // setMeshDecal(part, fileName)
            // set the current node's mesh part decal to the given png file name
            let setMeshDecal: @convention(block) (Int, String) -> Void = { [weak self] part, fileName in
                if let mesh = self!._current!.encodable as? Mesh {
                    if part >= 0 && part < mesh.parts.count {
                        do {
                            mesh.parts[part].decal = try GameView.instance!.assets.load(path: fileName) as? MTLTexture
                        } catch {
                            self!.raiseError(error.localizedDescription)
                        }
                    } else {
                        self!.raiseError("part index out of bounds")
                    }
                }
            }
            context.setObject(setMeshDecal, forKeyedSubscript: "setMeshDecal" as NSString)
            
            // join()
            // join all meshes under the current node to one mesh and detach all children
            let join: @convention(block) () -> Void = { [weak self] in self!._current!.join() }
            context.setObject(join, forKeyedSubscript: "join" as NSString)
            
            // setVolume(fileName, volume)
            // set the given wav file name's volume to the given volume
            let setVolume: @convention(block) (String, Float) -> Void = { [weak self] fileName, volume in
                do {
                    let sound = try GameView.instance!.assets.load(path: fileName) as? AVAudioPlayer
                    
                    sound!.volume = volume
                } catch {
                    self!.raiseError(error.localizedDescription)
                }
            }
            context.setObject(setVolume, forKeyedSubscript: "setVolume" as NSString)
            
            // play(fileName, looping)
            // play the given wav file name with the given looping state
            let play: @convention(block) (String, Bool) -> Void = { [weak self] fileName, looping in
                do {
                    let sound = try GameView.instance!.assets.load(path: fileName) as? AVAudioPlayer
                    
                    sound!.numberOfLoops = (looping) ? -1 : 0
                    sound!.play()
                } catch {
                    self!.raiseError(error.localizedDescription)
                }
            }
            context.setObject(play, forKeyedSubscript: "play" as NSString)
            
            // setParticles(maxParticles, textureFile)
            // set the current node's graphic to a particle system, with the given texture file
            let setParticles: @convention(block) (Int, String) -> Void = { [weak self] maxParticles, texture in
                self!._current!.encodable = ParticleSystem(maxParticles: maxParticles)
                do {
                    if let particles = self!._current!.encodable as? ParticleSystem {
                        particles.texture = try GameView.instance!.assets.load(path: texture) as? MTLTexture
                    }
                } catch {
                    self!.raiseError(error.localizedDescription)
                }
            }
            context.setObject(setParticles, forKeyedSubscript: "setParticles" as NSString)
            
            // setEmitPosition(x, y, z)
            // set the emit position of the current node's particle system
            let setEmitPosition: @convention(block) (Float, Float, Float) -> Void = { [weak self] x, y, z in
                if let particles = self!._current!.encodable as? ParticleSystem {
                    particles.emitPosition = Vec3(x, y, z)
                }
            }
            context.setObject(setEmitPosition, forKeyedSubscript: "setEmitPosition" as NSString)
            
            // emitParticle(velX, velY, velZ, posX, posY, posZ, startSizeX, startSizeY, endSizeX, endSizeY, startR, startG, startB, startA, endR, endG, endB, endA, lifeSpan)
            // emit a particle in the current node's particle system, with the given state
            let emitParticle: @convention(block) (Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float) -> Void = {
                [weak self] velX, velY, velZ, posX, posY, posZ, startSizeX, startSizeY, endSizeX, endSizeY, startR, startG, startB, startA, endR, endG, endB, endA, lifeSpan in
                if let particles = self!._current!.encodable as? ParticleSystem {
                    var p = Particle()
                    
                    p.velocity = Vec3(velX, velY, velZ)
                    p.startPosition = Vec3(posX, posY, posZ)
                    p.position = p.startPosition
                    p.startSize = Vec2(startSizeX, startSizeY)
                    p.endSize = Vec2(endSizeX, endSizeY)
                    p.startColor = Vec4(startR, startG, startB, startA)
                    p.endColor = Vec4(endR, endG, endB, endA)
                    p.color = p.startColor
                    p.lifeSpan = lifeSpan
                    p.time = GameView.instance!.totalTime
                    
                    particles.emit(particle: p)
                }
            }
            context.setObject(emitParticle, forKeyedSubscript: "emitParticle" as NSString)
            
            // setKFMesh(file)
            // set the current node's graphic to the given key frame mesh
            let setKFMesh: @convention(block) (String) -> Void = { [weak self] file in
                do {
                    self!._current!.encodable = try GameView.instance!.assets.load(path: file) as? KFMesh
                    if let encodable = self!._current!.encodable {
                        self!._current!.encodable = encodable.newInstance()
                    }
                } catch {
                    self!.raiseError(error.localizedDescription)
                }
            }
            context.setObject(setKFMesh, forKeyedSubscript: "setKFMesh" as NSString)
            
            // setKFMeshTexture(textureFile)
            // set the texture, of the current node's key frame mesh, to the given texture file
            let setKFMeshTexture: @convention(block) (String) -> Void = { [weak self] texture in
                if let mesh = self!._current!.encodable as? KFMesh {
                    do {
                        mesh.texture = try GameView.instance!.assets.load(path: texture) as? MTLTexture
                    } catch {
                        self!.raiseError(error.localizedDescription)
                    }
                }
            }
            context.setObject(setKFMeshTexture, forKeyedSubscript: "setKFMeshTexture" as NSString)
            
            // setKFMeshDecal(decalFile)
            // set the decal, of the current node's key frame mesh, to the given decal file
            let setKFMeshDecal: @convention(block) (String) -> Void = { [weak self] decal in
                if let mesh = self!._current!.encodable as? KFMesh {
                    do {
                        mesh.decal = try GameView.instance!.assets.load(path: decal) as? MTLTexture
                    } catch {
                        self!.raiseError(error.localizedDescription)
                    }
                }
            }
            context.setObject(setKFMeshDecal, forKeyedSubscript: "setKFMeshDecal" as NSString)
            
            // isDone()
            // return true if the current node's key frame mesh has finished a none looping animation sequence
            let isDone: @convention(block) () -> Bool = { [weak self] in
                if let mesh = self!._current!.encodable as? KFMesh {
                    return mesh.isDone
                }
                return false
            }
            context.setObject(isDone, forKeyedSubscript: "isDone" as NSString)
            
            // setSequence(start, end, speed, looping)
            // set the animation sequence for the current node's key frame mesh
            let setSequence: @convention(block) (Int, Int, Int, Bool) -> Void = { [weak self] start, end, speed, looping in
                if let mesh = self!._current!.encodable as? KFMesh {
                    mesh.setSequence(start, end, speed, looping)
                }
            }
            context.setObject(setSequence, forKeyedSubscript: "setSequence" as NSString)
            
            // frameCount()
            // return the number of frames in the current node's key frame mesh
            let frameCount: @convention(block) () -> Int = { [weak self] in
                if let mesh = self!._current!.encodable as? KFMesh {
                    return mesh.frames.count
                }
                return 0
            }
            context.setObject(frameCount, forKeyedSubscript: "frameCount" as NSString)
        }
    }
}
