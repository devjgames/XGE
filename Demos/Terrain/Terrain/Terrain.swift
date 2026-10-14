//
//  Terrain.swift
//  Terrain
//
//  Created by Douglas McNamara on 10/13/26.
//

import Foundation
import XGE

public class Terrain : GameComponent {
    
    public func create(gameView: GameView, scene: Scene, node:Node) throws {
        
        node.encodable = try gameView.assets.load(path: "terrain2.obj") as? Encodable
        node.receivesLight = false
        node.collidable = true
    }
    
    public func update(gameView: GameView, scene: Scene, node: Node) throws {
    }
}
