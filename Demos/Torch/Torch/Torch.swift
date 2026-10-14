//
//  Torch.swift
//  Torch
//
//  Created by Douglas McNamara on 10/13/26.
//

import Foundation
import simd
import Metal
import XGE

public class Torch : GameComponent {
    
    public func create(gameView: GameView, scene: Scene, node: Node) throws {
        node.encodable = try gameView.assets.load(path: "torch.obj") as? Encodable
        
        node.addChild(Node())
        node[0].emitsLight = true
        node[0].lightRadius = 300
        node[0].lightColor = Vec4(1, 2, 4, 1)
        
        node.addChild(Node())
        
        let ps = ParticleSystem(maxParticles: 500)
        
        srand48(100)
        
        ps.texture = try gameView.assets.load(path: "fire.png") as? MTLTexture
        
        node[1].encodable = ps
        node[1].receivesLight = false
        node[1].zOrder = 100
        node[1].depthWriteEnabled = false
        node[1].blendEnabled = true
        node[1].alphaBlend = false
    }
    
    public func update(gameView: GameView, scene: Scene, node: Node) throws {
        if let ps = node[1].encodable as? ParticleSystem {
            var p = Particle()
            let sc = 0.5 + Float(drand48() * 0.5)
            let ss = 10 + Float(drand48() * 20)
            let ls = 0.5 + Float(drand48() * 1.5)
            
            p.velocity = Vec3(0, 10 + Float(drand48() * 30), 0)
            p.startPosition = Vec3(-5 + Float(drand48() * 10), -5 + Float(drand48() * 10), -5 + Float(drand48() * 10))
            p.startColor = Vec4(sc, sc, sc, 1)
            p.endColor = Vec4(0, 0, 0, 1)
            p.startSize = Vec2(ss, ss)
            p.endSize = Vec2(1, 1)
            p.lifeSpan = ls
            
            ps.emit(particle: p)
        }
    }
}
