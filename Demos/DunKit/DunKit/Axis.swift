//
//  Axis.swift
//  DunKit
//
//  Created by Douglas McNamara on 10/14/26.
//

import Foundation
import XGE

public class Axis : GameComponent {
    
    public func create(gameView: GameView, scene: Scene, node:Node) throws {
        if scene.inDesign {
            node.encodable = try gameView.assets.load(path: "axis.obj") as? Encodable
            node.receivesLight = false
            node.followTarget = true
        }
    }
    
    public func update(gameView: GameView, scene: Scene, node: Node) throws {
    }
}


