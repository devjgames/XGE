//
//  Orb.swift
//  DunKit
//
//  Created by Douglas McNamara on 10/14/26.
//

import Foundation
import XGE

public class Orb : GameComponent {
    
    public func create(gameView: GameView, scene: Scene, node: Node) throws {
        node.encodable = try gameView.assets.load(path: "orb.obj") as? Encodable
        node.warpEnabled = true
        node.warpY = true
        node.warpAmplitude  = 2
        node.warpFrequency = 0.25
        node.warpSpeed = 2
        node.receivesLight = false
    }
    
    public func update(gameView: GameView, scene: Scene, node: Node) throws {
    }
}
