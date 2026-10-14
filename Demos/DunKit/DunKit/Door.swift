//
//  Door.swift
//  DunKit
//
//  Created by Douglas McNamara on 10/14/26.
//

import Foundation
import simd
import Metal
import XGE

public class Door : GameComponent {
    
    public func create(gameView: GameView, scene: Scene, node: Node) throws {
        if let mesh = try gameView.assets.load(path: "door.obj") as? Mesh {
            mesh.parts[0].decal = try gameView.assets.load(path: "door-glow.png") as? MTLTexture
            
            node.encodable = mesh
            node.data["y"] = node.position.y
        }
    }
    
    public func update(gameView: GameView, scene: Scene, node: Node) throws {
        if !scene.inDesign {
            let d = simd_length(scene.eye * Vec3(1, 0, 1) - node.absolutePosition * Vec3(1, 0, 1))
            let a = 1 - min(d / 75, 1)
            
            if let y = node.data["y"] as? Float {
                node.position.y = y - a * 200
            }
        }
    }
}
