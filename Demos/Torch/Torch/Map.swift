//
//  Map.swift
//  Torch
//
//  Created by Douglas McNamara on 10/13/26.
//

import Foundation
import XGE

public class Map : GameComponent {
    
    public func create(gameView: GameView, scene: Scene, node: Node) throws {
        node.encodable = try gameView.assets.load(path: "map.obj") as? Encodable
        node.collidable = true
    }
    
    public func update(gameView: GameView, scene: Scene, node: Node) throws {
    }
}
