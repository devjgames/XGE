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
    var start = true
    let collider = Collider()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        GameView.inDesign = false
        
        gameView = GameView(frame: window.contentView!.frame, device: MTLCreateSystemDefaultDevice())
        
        gameView!.autoresizingMask = [ .width, .height, .maxXMargin, .maxYMargin, .minXMargin, .maxXMargin ]
        
        window.contentView!.addSubview(gameView!)
        
        gameView!.scene.backgroundColor = Vec4(1, 1, 1, 1)
        gameView!.continuousMouseEnabled = true
        gameView!.delegate = self
        
        window.toggleFullScreen(self)
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
        if start {
            let scene = gameView!.scene
            
            if let sprite = scene.sprite {
                let w = Int(gameView!.drawableSize.width)
                let h = Int(gameView!.drawableSize.height)
                
                sprite.push("click to start", 8, 16, 16, 0, w / 2 - 7 * 16, h / 2 - 8, Vec4(0, 0, 0, 1))
            }
            if gameView!.isButtonDown(button: 0) {
                start = false
                
                loadSCX(name: "scene1.scx")
                
                let scene = gameView!.scene
                
                for i in (0..<scene.root.childCount) {
                    let node = scene.root[i]
                    
                    if node.name == "sky.obj" {
                        Log.instance.put("setting sky ...")
                        
                        node.zOrder = -1000
                        node.depthTestEnabled = false
                        node.depthWriteEnabled = false
                    } else if node.name == "player" {
                        Log.instance.put("setting player ...")
                        
                        scene.eye = node.position
                        scene.target = node.position + node.r
                        scene.up = node.u
                    } else if node.name == "ButterFly.kfm" {
                        Log.instance.put("setting butter fly ...")
                        
                        if let mesh = node.encodable as? KFMesh {
                            mesh.setSequence(0, mesh.frames.count - 1, 5, true)
                        }
                    }
                }
            }
        } else {
            let scene = gameView!.scene
            
            if let sprite = scene.sprite {
                sprite.push("""
                FPS = \(gameView!.fps)
                TST = \(collider.tested)
                CNT = \(scene.rendered):\(scene.trianglesRendered):\(scene.depthStateBinds):\(scene.cullStateBinds)
                """, 8, 16, 16, 5, 10, 10, Vec4(1, 1, 1, 1)
                )
            }
            
            scene.rotateAroundEye(dx: -gameView!.deltaX, dy: -gameView!.deltaY)
            
            collider.velocity *= Vec3(0, 1, 0)
            if gameView!.isButtonDown(button: 0) {
                collider.setForwardVelocity(speedAndDirection: 100)
            } else if gameView!.isButtonDown(button: 1) {
                collider.setForwardVelocity(speedAndDirection: -100)
            }
            collider.velocity.y -= 2000 * gameView!.elapsedTime
            
            let d = simd_normalize(scene.target - scene.eye)
            
            scene.eye = collider.resolve(root: scene.root, position: scene.eye)
            scene.target = scene.eye + d
            
            if let node = scene.root.find(name: "sky.obj") {
                node.position = scene.eye
            }
            
            if(gameView!.isKeyDown(key: 53)) { // ESC
                gameView!.continuousMouseEnabled = false
                NSApplication.shared.terminate(self)
            }
        }
        gameView!.scene.encode()
        gameView!.tick()
    }
}

