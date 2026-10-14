//
//  Portal.swift
//  DunKit
//
//  Created by Douglas McNamara on 10/14/26.
//

import Foundation
import simd
import Metal
import XGE

public class Portal : GameComponent {
    
    public func create(gameView: GameView, scene: Scene, node: Node) throws {
        node.encodable =  try gameView.assets.load(path: "energy.obj") as? Encodable
        node.depthWriteEnabled = false
        node.blendEnabled = true
        node.alphaBlend = true
        node.zOrder = 100
        node.receivesLight = false
    }
    
    public func update(gameView: GameView, scene: Scene, node: Node) throws {
        if !scene.inDesign {
            node.rotate(axis: 1, degrees: 45 * gameView.elapsedTime)
        }
    }
}
