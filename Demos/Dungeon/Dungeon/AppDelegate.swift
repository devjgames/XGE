//
//  AppDelegate.swift
//  YourGame
//

import Cocoa
import Metal
import MetalKit
import JavaScriptCore
import AVFoundation
import XGE

@main
class AppDelegate: NSObject, NSApplicationDelegate, MTKViewDelegate {
    
    @IBOutlet var window: NSWindow!
    
    var gameView: GameView?
    var start = true
    let collider = Collider()
    var name = "scene1.scx"
    var down = false
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        GameView.inDesign = false
        
        gameView = GameView(frame: window.contentView!.frame, device: MTLCreateSystemDefaultDevice())
        
        gameView!.autoresizingMask = [ .width, .height, .maxXMargin, .maxYMargin, .minXMargin, .maxXMargin ]
        
        window.contentView!.addSubview(gameView!)
        
        gameView!.scene.backgroundColor = Vec4(0, 0, 0, 1)
        gameView!.continuousMouseEnabled = true
        gameView!.delegate = self
        
        window.toggleFullScreen(self)
        
        srand48(100)
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
        let w = Int(gameView!.drawableSize.width)
        let h = Int(gameView!.drawableSize.height)
        
        if start {
            let scene = gameView!.scene
            
            if let sprite = scene.sprite {
                sprite.push("click to start", 8, 16, 16, 0, w / 2 - 7 * 16, h / 2 - 8, Vec4(1, 1, 1, 1))
            }
            if gameView!.isButtonDown(button: 0) {
                start = false
                
                load()
            }
        } else {
            let scene = gameView!.scene
            
            if let sprite = scene.sprite {
                sprite.push("""
                FPS = \(gameView!.fps)
                TST = \(collider.tested)
                CNT = \(scene.rendered):\(scene.trianglesRendered):\(scene.depthStateBinds):\(scene.cullStateBinds)
                SF  = Next, Fire
                """, 8, 16, 16, 5, 10, 10, Vec4(1, 1, 1, 1)
                )
                sprite.push(21, 2, 1, 1, w / 2 - 8, h / 2 - 1, 16, 2, Vec4(1, 1, 1, 1))
                sprite.push(21, 2, 1, 1, w / 2 - 1, h / 2 - 8, 2, 16, Vec4(1, 1, 1, 1))
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
            
            for i in (0..<scene.root.childCount) {
                let node = scene.root[i]
                
                if node.name == "gem.obj" || node.name == "energy.obj" {
                    node.rotate(axis: 1, degrees: 45 * gameView!.elapsedTime)
                } else if node.name == "door.obj" {
                    let d = simd_length(scene.eye * Vec3(1, 0, 1) - node.absolutePosition * Vec3(1, 0, 1))
                    let a = 1 - min(d / 125, 1)
                    
                    node.position.y = (node.data["y"] as! Float) - a * 300
                } else if node.name == "spell" {
                    if let particles = node.encodable as? ParticleSystem {
                        for _ in (0..<2) {
                            let sc = 0.25 + Float(drand48()) * 0.5
                            let ss = 20 + Float(drand48()) * 40
                            var p = Particle()
                            
                            p.velocity = Vec3(-10 + Float(drand48()) * 20, -10 + Float(drand48()) * 20, -10 + Float(drand48()) * 20)
                            p.startSize = Vec2(ss, ss)
                            p.endSize = Vec2(0.1, 0.1)
                            p.startColor = Vec4(sc, sc, sc, 1)
                            p.endColor = Vec4(0, 0, 0, 1)
                            p.lifeSpan = 0.5 + Float(drand48()) * 1.5
                            
                            particles.emitPosition = Vec3(0, sinf(gameView!.totalTime * 2) * 25, 0)
                            particles.emit(particle: p)
                        }
                    }
                }
            }
            
            if let node = scene.root.find(name: "smoke") {
                if let particles = node.encodable as? ParticleSystem {
                    var s1 = node.data["s1"] as! Float
                    var s2 = node.data["s2"] as! Float
                    
                    if gameView!.isKeyDown(key: 3) && s1 > 0.75 { // F
                        let d = simd_normalize(scene.target - scene.eye)
                        var time = Float.greatestFiniteMagnitude
                        
                        if collider.isect(
                            root: scene.root,
                            origin: scene.eye,
                            direction: d,
                            buffer: 0.1,
                            collidablesOnly: true,
                            time: &time) != nil {
                            
                            do {
                                if let sound = try gameView!.assets.load(path: "fire.wav") as? AVAudioPlayer {
                                    sound.volume = 0.1
                                    sound.numberOfLoops = 0
                                    sound.play()
                                }
                            } catch {
                                Log.instance.put(error.localizedDescription)
                            }
                            
                            if let triangle = collider.hitTriangle {
                                let r = simd_normalize(triangle.p2 - triangle.p1)
                                let u = triangle.normal
                                let f = simd_normalize(simd_cross(r, u))
                                
                                s2 = 1
                                
                                node.data["p"] = scene.eye + d * time
                                node.data["r"] = r
                                node.data["u"] = u
                                node.data["f"] = f
                                
                                s1 = 0
                            }
                        }
                    }
                    
                    s1 += gameView!.elapsedTime
                    
                    if s2 > 0 {
                        var p = Particle()
                        let s = 10 + Float(drand48()) * 15
                        let a = 0.25 + Float(drand48()) * 0.5
                        let l = node.data["p"] as! Vec3
                        let r = node.data["r"] as! Vec3
                        let u = node.data["u"] as! Vec3
                        let f = node.data["f"] as! Vec3
                        
                        p.velocity =
                        (-20 + Float(drand48()) * 40) * r +
                        (+10 + Float(drand48()) * 20) * u +
                        (-20 + Float(drand48()) * 40) * f
                        
                        p.startPosition = l + u * 7
                        p.startColor = Vec4(1, 1, 1, a)
                        p.endColor = Vec4(1, 1, 1, 0)
                        p.startSize = Vec2(s, s)
                        p.endSize = Vec2(5, 5)
                        p.lifeSpan = 0.25 + Float(drand48())
                        
                        particles.emit(particle: p)
                        
                        s2 -= gameView!.elapsedTime
                    }
                    
                    node.data["s1"] = s1
                    node.data["s2"] = s2
                }
            }
            
            if gameView!.isKeyDown(key: 49) { // SPACE
                if !down {
                    down = true
                    load()
                }
            } else {
                down = false
            }
            
            if gameView!.isKeyDown(key: 53) { // ESC
                gameView!.continuousMouseEnabled = false
                NSApplication.shared.terminate(self)
            }
        }
        gameView!.scene.encode()
        gameView!.tick()
    }
    
    func load() {
        loadSCX(name: name)
        
        let scene = gameView!.scene
        
        for i in (0..<scene.root.childCount) {
            let node = scene.root[i]
            
            if node.name == "player" {
                Log.instance.put("setting player ...")
                
                scene.eye = node.position
                scene.target = node.position + node.r
                scene.up = node.u
            } else if node.name == "Monster.kfm" {
                Log.instance.put("setting monster ...")
                
                if let mesh = node.encodable as? KFMesh {
                    mesh.setSequence(0, mesh.frames.count - 1, 9, true)
                }
            } else if node.name == "door.obj" {
                Log.instance.put("setting door ...")
                
                node.data["y"] = node.position.y
            } else if node.name == "spell" {
                Log.instance.put("setting spell ...")
                
                node.encodable = ParticleSystem(maxParticles: 500)
                if let particles = node.encodable as? ParticleSystem {
                    do {
                        particles.texture = try gameView!.assets.load(path: "particle.png") as? MTLTexture
                    } catch {
                        Log.instance.put(error.localizedDescription)
                    }
                }
            } else if node.name == "smoke" {
                Log.instance.put("setting smoke")
                
                node.data["s1"] = Float(0.0)
                node.data["s2"] = Float(-1.0)
                
                node.encodable = ParticleSystem(maxParticles: 500)
                if let particles = node.encodable as? ParticleSystem {
                    do {
                        particles.texture = try gameView!.assets.load(path: "smoke.png") as? MTLTexture
                    } catch {
                        Log.instance.put(error.localizedDescription)
                    }
                }
            }
        }
        if name == "scene1.scx" {
            name = "scene2.scx"
        } else {
            name = "scene1.scx"
        }
    }
}

