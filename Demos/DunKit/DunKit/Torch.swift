//
//  Torch.swift
//  DunKit
//
//  Created by Douglas McNamara on 10/14/26.
//

import Foundation
import simd
import Metal
import XGE

public class Torch : GameComponent {
    
    public func create(gameView: GameView, scene: Scene, node: Node) throws {
        
        node.addChild(Node())
        
        node[0].encodable = try gameView.assets.load(path: "torch.obj") as? Encodable
        node[0].position.z = -24
        
        node[0].addChild(Node())
        node[0][0].position = Vec3(0, 32, 0)
        node[0][0].emitsLight = true
        node[0][0].lightRadius = 75
        node[0][0].lightColor = Vec4(4, 2, 0, 1)
        
        node[0].addChild(Node())
        
        let ps = ParticleSystem(maxParticles: 500)
        
        ps.texture = try gameView.assets.load(path: "fire.png") as? MTLTexture
        
        node[0][1].encodable = ps
        node[0][1].depthWriteEnabled = false
        node[0][1].blendEnabled = true
        node[0][1].alphaBlend = false
        node[0][1].zOrder = 100
        node[0][1].position = Vec3(0, 32, 0)
        
        srand48(100)
    }
    
    public func update(gameView: GameView, scene: Scene, node: Node) throws {
        node[0][0].lightRadius = 75 + sinf(gameView.totalTime * 7) * 25
        
        if let ps = node[0][1].encodable as? ParticleSystem {
            var p = Particle()
            let ss = 5 + Float(drand48() * 10)
            let sc = 0.5 + Float(drand48() * 0.5)
            let ls = 0.5 + Float(drand48() * 1.5)
            
            p.velocity = Vec3(0, 5 + Float(drand48() * 10), 0)
            p.startPosition = Vec3(-2 + Float(drand48() * 4), -2 + Float(drand48() * 4), -2 + Float(drand48() * 4))
            p.startColor = Vec4(sc, sc, sc, 1)
            p.endColor = Vec4(0, 0, 0, 1)
            p.startSize = Vec2(ss, ss)
            p.endSize = Vec2(1, 1)
            p.lifeSpan = ls
            
            ps.emit(particle: p)
        }
    }
}
