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
        
        do {
            scene.root.addChild(Node())
            scene.root[0].encodable = try gameView.assets.load(path: "map.obj") as? Mesh
            scene.root[0].collidable = true
            
            scene.root.addChild(Node())
            scene.root[1].emitsLight = true
            scene.root[1].lightRadius = 300
            scene.root[1].lightColor = Vec4(0, 2, 4, 1)
            scene.root[1].position = Vec3(132, 128, -132)
            
            scene.root.addChild(Node())
            scene.root[2].emitsLight = true
            scene.root[2].lightRadius = 300
            scene.root[2].lightColor = Vec4(0, 2, 4, 1)
            scene.root[2].position = Vec3(364, 128, -664)
            
            scene.root.addChild(Node())
            scene.root[3].emitsLight = true
            scene.root[3].lightRadius = 200
            scene.root[3].lightColor = Vec4(0, 2, 4, 1)
            scene.root[3].position = Vec3(300, 64, -300)
            
            scene.root.addChild(Node())
            scene.root[4].addChild(Node())
            scene.root[4][0].encodable = try gameView.assets.load(path: "cube.obj") as? Mesh
            scene.root[4].addChild(Node())
            scene.root[4][1].emitsLight = true
            scene.root[4][1].lightColor = Vec4(4, 4, 4, 1)
            scene.root[4][1].lightRadius = 300
            scene.root[4][1].position = Vec3(150, 150, 150)
            scene.root[4].visible = false
            
            renderTarget = try RenderTarget(w: 128, h: 128)
            
            scene.eye = Vec3(132, 64, -132)
            scene.target = scene.eye + Vec3(1, 0, -1)
            scene.up = Vec3(0, 1, 0)
            
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
            """, 1, 8, 16, 16, 5, 10, 10, Vec4(1, 1, 0.5, 1), Vec4(1, 0.5, 0, 1))
        
        scene.eye = Vec3(64, 64, 64)
        scene.target = Vec3(0, 0, 0)
        scene.up = Vec3(0, 1, 0)
        scene.backgroundColor = Vec4(0, 0, 0, 0)
        scene.root[4].visible = true
        scene.encode(root: scene.root[4], renderPassDescriptor: renderTarget!.descriptor, drawable: nil)
        scene.root[4].visible = false
        scene.backgroundColor = bg
        scene.eye = eye
        scene.target = target
        scene.up = up
        
        scene.root[4][0].rotate(axis: 1, degrees: 45 * gameView.elapsedTime)
        
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
    }
    
    public override var name: String {
        get { "Map Sample" }
    }
}
