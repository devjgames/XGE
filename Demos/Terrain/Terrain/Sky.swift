//
//  Sky.swift
//  Terrain
//
//  Created by Douglas McNamara on 10/13/26.
//

import Foundation
import Metal
import XGE

public class Sky : GameComponent {
    
    public func create(gameView: GameView, scene: Scene, node:Node) throws {
        node.encodable = try gameView.assets.load(path: "sky.obj") as? Encodable
        if !scene.inDesign {
            node.depthTestEnabled = false
            node.depthWriteEnabled = false
            node.zOrder = -1000
        }
        node.receivesLight = false
    }
    
    public func update(gameView: GameView, scene: Scene, node: Node) throws {
        if !scene.inDesign {
            node.position = scene.eye
        }
    }
}
