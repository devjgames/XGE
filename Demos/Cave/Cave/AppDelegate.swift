//
//  AppDelegate.swift
//  YourGame
//

import Cocoa
import Metal
import MetalKit
import JavaScriptCore
import XGE

@main
class AppDelegate: NSObject, NSApplicationDelegate, MTKViewDelegate {
    
    @IBOutlet var window: NSWindow!
    
    var gameView: GameView?
    let collider = Collider()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        GameView.inDesign = false
        
        gameView = GameView(frame: window.contentView!.frame, device: MTLCreateSystemDefaultDevice())
        
        gameView!.autoresizingMask = [ .width, .height, .maxXMargin, .maxYMargin, .minXMargin, .maxXMargin ]
        window.contentView!.addSubview(gameView!)
        
        loadSCX(name: "scene1.scx")
        
        gameView!.scene.root.calcBoundsAndTransform()
        
        if let node = gameView!.scene.root.find(name: "canvas") {
            Log.instance.put("optimizing canvas ...")
            
            node.join()
            node.collidable = true
            node.receivesLight = false
        }
        gameView!.delegate = self
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    func draw(in view: MTKView) {
        let scene = gameView!.scene
        
        if let sprite = scene.sprite {
            var key = -1
            
            for i in (0..<200) {
                if gameView!.isKeyDown(key: i) {
                    key = i
                    break
                }
            }
            sprite.push("""
                FPS = \(gameView!.fps)
                TST = \(collider.tested)
                CNT = \(scene.rendered):\(scene.trianglesRendered):\(scene.depthStateBinds):\(scene.cullStateBinds)
                KEY = \(key)
                """, 8, 16, 16, 5, 10, 10, Vec4(1, 1, 1, 1)
            )
        }
        if let node = scene.root.find(name: "player") {
            node[2].rotate(axis: 1, degrees: 90 * gameView!.elapsedTime)
            
            collider.velocity *= Vec3(0, collider.velocity.y, 0)
            if gameView!.isKeyDown(key: 123) { // left arrow
                collider.velocity.x = -100
            } else if gameView!.isKeyDown(key: 124) { // right arrow
                collider.velocity.x = 100
            }
            if gameView!.isKeyDown(key: 125) { // down arrow
                collider.velocity.z = 100
            } else if gameView!.isKeyDown(key: 126) { // up arrow
                collider.velocity.z = -100
            }
            collider.velocity.y -= 2000 * gameView!.elapsedTime
            node.position = collider.resolve(root: scene.root, position: node.position)
            
            let o = scene.eye - scene.target
            
            scene.target = node.position
            
            scene.target.x = max(scene.root.bounds.min.x + 256 + 64, scene.target.x)
            scene.target.x = min(scene.root.bounds.max.x - 256 - 64, scene.target.x)
            
            scene.eye = scene.target + o
        }
        
        gameView!.scene.encode()
        gameView!.tick()
    }
}

