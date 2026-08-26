//
//  MapSample.swift
//  Samples
//
//  Created by Douglas McNamara on 8/22/26.
//

import Foundation
import Metal
import MetalKit
import simd
import XGE

@MainActor
public class MapSample : Sample {
    
    private let collider = Collider()
    private var renderTarget:RenderTarget?
    
    public override func setup() {
        AssetManager.rootURL! = AssetManager.rootURL!.appending(path: "Map")
        
        let gameView = GameView.instance!
        let scene = gameView.scene
        
        srand48(100)
        
        do {
            scene.root.addChild(Node())
            
            scene.root.addChild(Node())
            scene.root[0].addChild(Node())
            scene.root[0][0].encodable = try gameView.assets.load(path: "cube.obj") as? Mesh
            scene.root[0].addChild(Node())
            scene.root[0][1].emitsLight = true
            scene.root[0][1].lightColor = Vec4(4, 4, 4, 1)
            scene.root[0][1].lightRadius = 300
            scene.root[0][1].position = Vec3(150, 150, 150)
            scene.root[0].visible = false
            
            try loadScene(name: "scene1.scene")
            
            for i in (0..<scene.root.childCount) {
                let node = scene.root[i]
                
                if node.name == "torch.obj" {
                    node.emitsLight = true
                    node.lightColor = Vec4(1, 2, 4, 1)
                    node.lightRadius = 300
                    node.addChild(Node())
                    
                    let ps = ParticleSystem(maxParticles: 500)
                    
                    node.addChild(Node())
                    node[0].encodable = ps
                    ps.texture = try gameView.assets.load(path: "fire.png") as? MTLTexture
                    node[0].depthWriteEnabled = false
                    node[0].blendEnabled = true
                    node[0].alphaBlend = false
                    node[0].zOrder = 100
                } else if node.name == "axis.obj" {
                    node.visible = false
                    scene.eye = node.position
                    scene.target = node.position + node.r
                    scene.up = node.u
                } else if node.name == "map.obj" {
                    node.collidable = true
                }
            }
            renderTarget = try RenderTarget(w: 128, h: 128)
            
            gameView.continuousMouseEnabled = true
        } catch {
            Log.instance.put(error.localizedDescription)
        }
    }
    
    public override func update() {
        let gameView = GameView.instance!
        let scene = gameView.scene
        let sprite = scene.sprite!
        let bg = scene.backgroundColor
        let eye = scene.eye
        let target = scene.target
        let up = scene.up
        let w = Int(gameView.drawableSize.width)
        let h = Int(gameView.drawableSize.height)
        
        sprite.push("""
            FPS = \(gameView.fps)
            TRI = \(scene.trianglesRendered)
            RND = \(scene.rendered)
            BND = \(scene.cullStateBinds):\(scene.depthStateBinds):\(scene.renderStateBinds)
            TST = \(collider.tested)
            POS = \(Int(eye.x)),\(Int(eye.y)),\(Int(eye.z))
            """, 1, 8, 16, 16, 5, 10, 10, Vec4(1, 1, 0.5, 1), Vec4(1, 0.5, 0, 1))
        
        scene.clearCounts()
        
        scene.eye = Vec3(64, 64, 64)
        scene.target = Vec3(0, 0, 0)
        scene.up = Vec3(0, 1, 0)
        scene.backgroundColor = Vec4(0, 0, 0, 0)
        scene.root[0].visible = true
        scene.encode(root: scene.root[0], renderPassDescriptor: renderTarget!.descriptor, drawable: nil)
        scene.root[0].visible = false
        scene.backgroundColor = bg
        scene.eye = eye
        scene.target = target
        scene.up = up
        
        scene.root[0][0].rotate(axis: 1, degrees: 45 * gameView.elapsedTime)
        
        let tw = renderTarget!.descriptor.colorAttachments[0].texture!.width
        let th = renderTarget!.descriptor.colorAttachments[0].texture!.height
        
        sprite.push(
            renderTarget!.descriptor.colorAttachments[0].texture!,
            0, 0, tw, th,
            w - tw - 16, h - th - 16, tw, th,  Vec4(1, 1, 1, 1), Vec4(1, 1, 1, 1),
            false
        )
        
        scene.rotateAroundEye(dx: -gameView.deltaX, dy: -gameView.deltaY)
        
        let f = simd_normalize(scene.target - scene.eye)
        
        if gameView.isButtonDown(button: 0) {
            collider.setForwardVelocity(speedAndDirection: 100)
        } else if gameView.isButtonDown(button: 1) {
            collider.setForwardVelocity(speedAndDirection: -100)
        } else {
            collider.setForwardVelocity(speedAndDirection: 0)
        }
        collider.velocity.y -= 2000 * gameView.elapsedTime
        scene.eye = collider.resolve(root: scene.root, position: scene.eye)
        scene.target = scene.eye + f
        
        for i in (0..<scene.root.childCount) {
            let node = scene.root[i]
            
            if node.name == "torch.obj" {
                if let ps = node[0].encodable as? ParticleSystem {
                    let sc = 0.25 + Float(drand48() * 0.5)
                    let ss = 10 + Float(drand48() * 30)
                    let vy = 20 + Float(drand48() * 30)
                    var p = Particle()
                    
                    p.startPosition = Vec3(
                        -5 + Float(drand48() * 10),
                        -5 + Float(drand48() * 10),
                        -5 + Float(drand48() * 10)
                         )
                    p.velocity = Vec3(0, vy, 0)
                    p.startColor = Vec4(sc, sc, sc, 1)
                    p.endColor = Vec4(0, 0, 0, 1)
                    p.startSize = Vec2(ss, ss)
                    p.endSize = Vec2(0.1, 0.1)
                    p.lifeSpan = 0.5 + Float(drand48() * 1.5)
                    
                    ps.emit(particle: p)
                }
            }
        }
    }
    
    public override var name: String {
        get { "Map Sample" }
    }
}
