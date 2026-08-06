//
//  AppDelegate.swift
//  YourGame
//

import Cocoa
import Metal
import MetalKit
import JavaScriptCore
import XGE

@main
class AppDelegate: NSObject, NSApplicationDelegate, MTKViewDelegate {
    
    let title = "Menu - down arrow select next, space run demo"

    @IBOutlet var window: NSWindow!

    var gameView: GameView?
    var api = Api()
    var demos:[String] = [
        "CaveKit",
        "Terrain",
        "Dungeon"
    ]
    var iDemo:Int = -1
    var iSel:Int = 0
    var down = false
    var sDown = false

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        GameView.inDesign = false
        
        window.title = title
        
        gameView = GameView(frame: window.contentView!.frame, device: MTLCreateSystemDefaultDevice())
        
        gameView!.autoresizingMask = [ .width, .height, .maxXMargin, .maxYMargin, .minXMargin, .maxXMargin ]
        window.contentView!.addSubview(gameView!)
        
        gameView!.delegate = self
        gameView!.newScene()
        
        gameView!.x2 = true
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
        do {
            if iDemo == -1 {
                if let sprite = gameView!.scene.sprite {
                    for i in (0..<demos.count) {
                        var color = Vec4(1, 1, 1, 1)
                        let w = Int(gameView!.drawableSize.width)
                        let h = Int(gameView!.drawableSize.height)
                        if i == iSel {
                            color = Vec4(1, 0.5, 0, 1)
                        }
                        sprite.push(demos[i], 8, 16, 16, 5, w / 2 - demos[i].count / 2 * 16, h / 2 - demos.count * 32 / 2 + i * 32, color)
                    }
                }
                if gameView!.isKeyDown(key: 125) { // down arrow, menu next
                    if !down {
                        down = true
                        if !demos.isEmpty {
                            iSel = (iSel + 1) % demos.count
                        }
                    }
                } else {
                    down = false
                }
                if gameView!.isKeyDown(key: 49) { // space
                    if(!sDown) {
                        sDown = true
                    }
                } else {
                    if(sDown) { // space up run selected demo
                        if iSel != -1 {
                            iDemo = iSel
                            
                            AssetManager.rootURL = Bundle.main.resourceURL!.appending(path: "Assets").appending(path: demos[iDemo])
                            
                            api.setGameState()
                            
                            try loadScene(url: AssetManager.rootURL!.appending(path: "scene1.scene"), api: api)
                            
                            window.title = "\(demos[iDemo]) - press ESC to quit"
                        }
                    }
                    sDown = false
                }
            } else {
                gameView!.scene.root.eval(api:api)
                
                if let scene = gameView!.scene.loadSceneName {
                    gameView!.newScene()
                    
                    try loadScene(url: AssetManager.rootURL!.appending(path: scene), api: api)
                }
                if gameView!.isKeyDown(key: 53) {
                    AssetManager.rootURL = Bundle.main.resourceURL!.appending(path: "Assets")
                    gameView!.continuousMouseEnabled = false
                    gameView!.newScene()
                    iDemo = -1
                    window.title = title
                }
            }
        } catch {
            gameView!.continuousMouseEnabled = false
            NSApplication.shared.terminate(self)
            Log.instance.put(error.localizedDescription)
        }
        
        gameView!.scene.encode()
        gameView!.tick()
    }
}

