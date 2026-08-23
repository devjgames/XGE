//
//  GameControl.swift
//  GameMaker
//
//  Created by Douglas McNamara on 3/8/26.
//

import SwiftUI
import Metal
import MetalKit
import XGE
import JavaScriptCore

#if os(macOS)
public struct GameControl : NSViewRepresentable {
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    public func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSViewType, context: Context) -> CGSize? {
        nil
    }
    
    public func makeNSView(context: Context) -> some NSView {
        let gameView = GameView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), device: MTLCreateSystemDefaultDevice())
        
        GameView.inProduction = true
        
        gameView.delegate = context.coordinator
        
        return gameView
    }
    
    public func updateNSView(_ nsView: NSViewType, context: Context) {
    }
    
    public class Coordinator : NSObject, MTKViewDelegate {
        
        public var parent:GameControl
        
        private var start = true
        private var game = Game()
        
        public init(parent:GameControl) {
            self.parent = parent
            
            super.init()
        }
        
        public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }
        
        public func draw(in view: MTKView) {
            if let gameView = view as? GameView {
                if start {
                    start = false
                    do {
                        try game.load(gameView: gameView, root: gameView.scene.root, name: "scene1.scene")
                    } catch {
                        Log.instance.put(error.localizedDescription)
                    }
                } else {
                    game.update(gameView: gameView, textScale: 1, textColor1: Vec4(1, 1, 0.5, 1), textColor2: Vec4(1, 0.5, 0, 1))
                }
                gameView.scene.encode()
                gameView.tick()
            }
        }
    }
}
#else
public struct GameControl : UIViewRepresentable {
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    public func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIViewType, context: Context) -> CGSize? {
        nil
    }
    
    public func makeUIView(context: Context) -> some UIView {
        let gameView = GameView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), device: MTLCreateSystemDefaultDevice())
        
        GameView.inProduction = true
        
        gameView.delegate = context.coordinator
        
        return gameView
    }
    
    public func updateUIView(_ uiView: UIViewType, context: Context) {
    }
    
    public class Coordinator : NSObject, MTKViewDelegate {
        
        public var parent:GameControl
        
        private var start = true
        private var game = Game()
        
        public init(parent:GameControl) {
            self.parent = parent
            
            super.init()
        }
        
        public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }
        
        public func draw(in view: MTKView) {
            if let gameView = view as? GameView {
                if start {
                    start = false
                    do {
                        try game.load(gameView: gameView, root: gameView.scene.root, name: "scene1.scene")
                    } catch {
                        Log.instance.put(error.localizedDescription)
                    }
                } else {
                    game.update(gameView: gameView, textScale: 2, textColor1: Vec4(1, 1, 0.5, 1), textColor2: Vec4(1, 0.5, 0, 1))
                }
                gameView.scene.encode()
                gameView.tick()
            }
        }
    }
}
#endif

