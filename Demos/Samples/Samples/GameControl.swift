//
//  GameControl.swift
//  Samples
//
//  Created by Douglas McNamara on 3/8/26.
//

import SwiftUI
import Metal
import MetalKit
import XGE

@MainActor
public class Sample {
    
    open func setup() {
    }
    
    open func update() {
    }
    
    open var name:String {
        get { "Sample" }
    }
}

@MainActor
let _samples:[Sample] = [
    FXSample(),
    MapSample()
]

@MainActor
var _sel:Int = 0

@MainActor
var _sample:Int = -1

@MainActor
var _down = false

@MainActor
var _sdown = false

@MainActor
public struct GameControl : NSViewRepresentable {
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    public func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSViewType, context: Context) -> CGSize? {
        nil
    }
    
    public func makeNSView(context: Context) -> some NSView {
        let gameView = GameView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), device: MTLCreateSystemDefaultDevice())
        
        gameView.delegate = context.coordinator
        
        return gameView
    }
    
    public func updateNSView(_ nsView: NSViewType, context: Context) {
    }
    
    public class Coordinator : NSObject, MTKViewDelegate {
        
        public var parent:GameControl
        
        private var game = Game()
        
        public init(parent:GameControl) {
            self.parent = parent
            
            super.init()
        }
        
        public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }
        
        public func draw(in view: MTKView) {
            if let gameView = view as? GameView {
                if _sample == -1 {
                    let sprite = gameView.scene.sprite!
                    var y:Int = 10
                    
                    gameView.scene.backgroundColor = Vec4(0, 0, 0, 1)
                    
                    for s in _samples {
                        var c1 = Vec4(1, 1, 0.5, 1)
                        var c2 = Vec4(1, 0.5, 0, 1)
                        
                        if s !== _samples[_sel] {
                            c1 = Vec4(1, 1, 1, 1)
                            c2 = Vec4(0.5, 0.5, 0.5, 1)
                        }
                        sprite.push(s.name, 1, 8, 16, 16, 5, 10, y, c1, c2)
                        y += 22
                    }
                    
                    if gameView.isKeyDown(key: 125) {
                        if !_down {
                            _down = true
                            
                            _sel = (_sel + 1) % _samples.count
                        }
                    } else {
                        _down = false
                    }
                    if gameView.isKeyDown(key: 49) {
                        _sdown = true
                    } else {
                        if _sdown {
                            gameView.newScene()
                            gameView.scene.backgroundColor = Vec4(0, 0, 0, 1)
                            
                            _sample = _sel
                            _samples[_sample].setup()
                        }
                        _sdown = false
                    }
                } else {
                    _samples[_sample].update()
                    
                    if gameView.isKeyDown(key: 53) {
                        gameView.continuousMouseEnabled = false
                        gameView.newScene()
                        AssetManager.rootURL = Bundle.main.resourceURL!.appending(path: "Assets")
                        _sample = -1
                    }
                }
                gameView.scene.encode()
                gameView.tick()
            }
        }
    }
}
