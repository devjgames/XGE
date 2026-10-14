//
//  Game.swift
//  XGE
//
//  Created by Douglas McNamara on 8/15/26.
//

import Foundation
import simd
import Metal
import JavaScriptCore
import AVFoundation

@MainActor
fileprivate var _game:Game?

@MainActor
public protocol GameComponent {
    
    func create(gameView:GameView, scene:Scene, node:Node) throws
    
    func update(gameView:GameView, scene:Scene, node:Node) throws
}

@MainActor
public class Game {
    
    public static var factories:[String:GameComponent] = [:]
    public static var components:[String] = []
    public static var loadSceneName:String?
    
    public init() {
        Game.loadSceneName = nil
        
        if let gameView = GameView.instance {
            gameView.newScene(inDesign: false)
        }
    }
    
    public func create(name:String, inDesign:Bool) throws {
        Game.loadSceneName = nil
        
        if let gameView = GameView.instance {
            gameView.newScene(inDesign: inDesign)
            
            do {
                try loadScene(name: name, game: self)
            } catch {
                Log.instance.put(error.localizedDescription)
            }
        }
    }
    
    public func update() throws {
        if let gameView = GameView.instance {
            let scene = gameView.scene
            
            for i in (0..<scene.root.childCount) {
                let node = scene.root[i]
                
                if let component = node.gameComponent {
                    try component.update(gameView: gameView, scene: scene, node:node)
                }
            }
            if !scene.inDesign {
                if let name = Game.loadSceneName {
                    try create(name: name, inDesign:false)
                }
            }
        }
    }
    
    public static func run(gameView:GameView, name:String?) -> String? {
        do {
            if let name = name {
                _game = Game()
                if let game = _game {
                    try game.create(name: name, inDesign: false)
                }
            } else {
                if let game = _game {
                    try game.update()
                }
            }
        } catch {
            Log.instance.put(error.localizedDescription)
        }
        if(gameView.isKeyDown(key: 53)) {
            gameView.continuousMouseEnabled = false
            _game = nil
        }
        gameView.scene.clearCounts()
        gameView.scene.encode()
        gameView.tick()
        
        return nil
    }
}
