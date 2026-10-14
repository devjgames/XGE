//
//  Start.swift
//  Terrain
//
//  Created by Douglas McNamara on 10/13/26.
//

import Foundation
import MetalKit
import simd
import XGE

public class Start : GameComponent {
    
    public func create(gameView: GameView, scene: Scene, node:Node) throws {
        scene.backgroundColor = Vec4(0, 0, 0, 1)
        
        if scene.inDesign {
            node.encodable = try gameView.assets.load(path: "axis.obj") as? Encodable
            node.receivesLight = false
        } else {
            gameView.continuousMouseEnabled = true
        }
    }
    
    public func update(gameView: GameView, scene: Scene, node: Node) throws {
        if !scene.inDesign {
            let w:Int = Int(gameView.drawableSize.width)
            let h:Int = Int(gameView.drawableSize.height)
            
            if let sprite = scene.sprite {
                sprite.push("click to start", 1, 8, 16, 16, 0, w / 2 - 16 * 7, h / 2 - 8, Vec4(1, 1, 0, 1), Vec4(1, 0.5, 0, 1))
            }
            if gameView.isButtonDown(button: 0) {
                Game.loadSceneName = "scene2.scene"
            }
        }
    }
}
