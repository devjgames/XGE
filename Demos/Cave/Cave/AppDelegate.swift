//
//  AppDelegate.swift
//  YourGame
//

import Cocoa
import Metal
import MetalKit
import XGE

@main
class AppDelegate: NSObject, NSApplicationDelegate, MTKViewDelegate {
    
    @IBOutlet var window: NSWindow!
    
    var gameView: GameView?
    var api = Api()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        gameView = GameView(frame: window.contentView!.frame, device: MTLCreateSystemDefaultDevice())
        
        gameView!.autoresizingMask = [ .width, .height, .maxXMargin, .maxYMargin, .minXMargin, .maxXMargin ]
        window.contentView!.addSubview(gameView!)
        
        gameView!.delegate = self
        
        api.compile()
        api.eval(isInit:true)
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
        api.eval(isInit:false)
        gameView!.scene.encode()
        gameView!.tick()
    }
}

