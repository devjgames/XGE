//
//  ButterFly.swift
//  Terrain
//
//  Created by Douglas McNamara on 10/13/26.
//

import Foundation
import Metal
import XGE

public class ButterFly : GameComponent {
    
    public func create(gameView: GameView, scene: Scene, node:Node) throws {
        var mesh = try gameView.assets.load(path: "ButterFly.kfm") as? KFMesh
        
        mesh = mesh?.newInstance() as? KFMesh
        if let mesh = mesh {
            mesh.setSequence(0, mesh.frames.count - 1, 4, true)
            mesh.texture = try gameView.assets.load(path: "ButterFly.png") as? MTLTexture
            node.encodable = mesh
            node.receivesLight = false
            node.scale *= 0.5
        }
    }
    
    public func update(gameView: GameView, scene: Scene, node: Node) throws {
    }
}
