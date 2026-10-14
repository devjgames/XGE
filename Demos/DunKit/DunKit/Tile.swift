//
//  Tile.swift
//  DunKit
//
//  Created by Douglas McNamara on 10/14/26.
//

import Foundation
import XGE

public class Tile : GameComponent {
    
    private let _asset:String
    
    public init(asset:String) {
        _asset = asset
    }
    
    public func create(gameView: GameView, scene: Scene, node: Node) throws {
        node.encodable = try gameView.assets.load(path: _asset) as? Encodable
        
        if _asset == "coins.obj" {
            node.receivesLight = false
        } else {
            node.ambientColor = Vec4(0.7, 0.7, 0.7, 1)
            node.collidable = true
        }
    }
    
    public func update(gameView: GameView, scene: Scene, node: Node) throws {
    }
}
