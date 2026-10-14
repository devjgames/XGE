//
//  Player.swift
//  Torch
//
//  Created by Douglas McNamara on 10/13/26.
//

import Foundation
import simd
import XGE

public class Player : GameComponent {
    
    public func create(gameView: GameView, scene: Scene, node:Node) throws {
        if scene.inDesign {
            node.encodable = try gameView.assets.load(path: "axis.obj") as? Encodable
            node.receivesLight = false
        } else {
            scene.eye = node.position
            scene.target = scene.eye + node.r
            scene.up = node.u
            
            node.data["collider"] = Collider()
        }
    }
    
    public func update(gameView: GameView, scene: Scene, node: Node) throws {
        var text = """
            FPS = \(gameView.fps)
            BND = \(scene.depthStateBinds):\(scene.renderStateBinds):\(scene.cullStateBinds)
            RND = \(scene.trianglesRendered):\(scene.rendered)
            """
        if let collider = node.data["collider"] as? Collider {
            scene.rotateAroundEye(dx: -gameView.deltaX, dy: -gameView.deltaY)
            
            let d = scene.target - scene.eye

            collider.velocity *= Vec3(0, 1, 0)
            if gameView.isButtonDown(button: 0) {
                collider.setForwardVelocity(speedAndDirection: 100)
            } else if gameView.isButtonDown(button: 1) {
                collider.setForwardVelocity(speedAndDirection: -100)
            }
            collider.velocity.y -= 2000 * gameView.elapsedTime
            scene.eye = collider.resolve(root: scene.root, position: scene.eye)
            scene.target = scene.eye + d
            
            text = "\(text)\nTST = \(collider.tested)"
        }
        if let sprite = scene.sprite {
            sprite.push(text, 1, 8, 16, 16, 5, 10, 10, Vec4(1, 1, 0, 1), Vec4(1, 0.5, 0, 1))
        }
    }
}

