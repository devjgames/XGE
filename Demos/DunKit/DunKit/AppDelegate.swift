//
//  AppDelegate.swift
//  DunKit
//
//  Created by Douglas McNamara on 10/14/26.
//

import Cocoa
import MetalKit
import XGE

@main
class AppDelegate: NSObject, NSApplicationDelegate, MTKViewDelegate {

    @IBOutlet var window: NSWindow!

    var name:String? = "scene1.scene"
    var gameView:GameView?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        _ = Log()
        
        let tiles = [
            "coins.obj", "corner.obj", "flats.obj", "hall-corner.obj", "hall-end.obj", "hall-ramp.obj",
            "hall-short.obj", "hall-side.obj", "side.obj", "door-way.obj"
        ]
        
        Game.components.append("Start")
        Game.components.append("Player")
        Game.components.append("Orb")
        Game.components.append("Torch")
        Game.components.append("Portal")
        Game.components.append("Door")
        Game.components.append("Axis")
        
        for tile in tiles {
            Game.components.append(tile)
        }
        
        Game.factories["Start"] = Start()
        Game.factories["Player"] = Player()
        Game.factories["Orb"] = Orb()
        Game.factories["Torch"] = Torch()
        Game.factories["Portal"] = Portal()
        Game.factories["Door"] = Door()
        Game.factories["Axis"] = Axis()
        
        for tile in tiles {
            Game.factories[tile] = Tile(asset: tile)
        }
        
        /*
        window.toggleFullScreen(self)
        
        gameView = GameView(frame: window.contentView!.frame, device: MTLCreateSystemDefaultDevice(), inProduction: true)
        if let gameView = gameView {
            window.contentView!.addSubview(gameView)
            gameView.delegate = self
        }
         */
        
        AssetManager.rootURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
            .appending(path: "XCode")
            .appending(path: "XGE")
            .appending(path: "Demos")
            .appending(path: "DunKit")
            .appending(path: "Assets")
        
        addUI(contentView: window.contentView!)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    func draw(in view: MTKView) {
        if let gameView = gameView {
            name = Game.run(gameView: gameView, name: name)
            if gameView.isKeyDown(key: 53) {
                NSApplication.shared.terminate(self)
            }
        }
    }
}




