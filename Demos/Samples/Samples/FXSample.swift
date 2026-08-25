//
//  FXSample.swift
//  Samples
//
//  Created by Douglas McNamara on 8/22/26.
//

import Foundation
import Metal
import MetalKit
import simd
import XGE

@MainActor
public class FXSample : Sample {
    
    public override func setup() {
        AssetManager.rootURL! = AssetManager.rootURL!.appending(path: "FX")
        
        let gameView = GameView.instance!
        let scene = gameView.scene
        
        do {
            scene.root.addChild(Node())
            scene.root[0].encodable = try gameView.assets.load(path: "smooth.obj") as? Encodable
            scene.root[0].ambientColor = Vec4(0.2, 0.2, 0.2, 1)
            scene.root[0].diffuseColor = Vec4(0.6, 0.6, 0.6, 1)
            scene.root[0].specularColor = Vec4(2, 2, 2, 1)
            scene.root[0].warpEnabled = true
            scene.root.addChild(Node())
            scene.root[1].emitsLight = true
            scene.root[1].lightRadius = 300
            scene.root[1].lightColor = Vec4(2, 1, 0, 1)
            scene.root[1].position = Vec3(100, 100, 100)
            scene.root.addChild(Node())
            scene.root[2].emitsLight = true
            scene.root[2].lightRadius = 300
            scene.root[2].lightColor = Vec4(0, 1, 2, 1)
            scene.root[2].position = Vec3(-100, 100, -100)
        } catch {
            Log.instance.put(error.localizedDescription)
        }
        
        scene.eye = Vec3(120, 120, 120)
        
        gameView.resetTimer()
    }
    
    public override func update() {
        let gameView = GameView.instance!
        let scene = gameView.scene
        let sprite = scene.sprite!
        
        sprite.push("""
            FPS = \(gameView.fps)
            TRI = \(scene.trianglesRendered)
            BND = \(scene.cullStateBinds):\(scene.depthStateBinds):\(scene.renderStateBinds)
            """, 1, 8, 16, 16, 5, 10, 10, Vec4(1, 1, 0.5, 1), Vec4(1, 0.5, 0, 1))
        
        scene.eye = Vec3(cosf(gameView.totalTime) * 120, 120, sinf(gameView.totalTime) * 120)
        
        scene.clearCounts()
    }
    
    public override var name: String {
        get { "FX Sample" }
    }
}
