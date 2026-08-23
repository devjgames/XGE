//
//  LightMapSample.swift
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
public class LightMapSample : Sample {
    
    public override func setup() {
        AssetManager.rootURL! = AssetManager.rootURL!.appending(path: "LightMap")
    }
    
    public override func update() {
        let gameView = GameView.instance!
        let scene = gameView.scene
        let sprite = scene.sprite!
        
        sprite.push("""
            FPS = \(gameView.fps)
            TRI = \(scene.trianglesRendered)
            RND = \(scene.rendered)
            BND = \(scene.cullStateBinds):\(scene.depthStateBinds):\(scene.renderStateBinds)
            """, 1, 8, 16, 16, 5, 10, 10, Vec4(1, 1, 0.5, 1), Vec4(1, 0.5, 0, 1))
    }
    
    public override var name: String {
        get { "Light Map Sample" }
    }
}
