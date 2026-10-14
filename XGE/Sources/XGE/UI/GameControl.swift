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

@MainActor
var _snapVec = Vec3(1, 1, 1)

@MainActor
fileprivate var _game = Game()

@MainActor
var game: Game {
    get { _game }
}

@MainActor
var _pickTri = -1

@MainActor
var _triPoint = Vec3(0, 0, 0)

extension XGE.Scene {
    
    func snap(_ point: Vec3) -> Vec3 {
        let s = simd_max(Vec3(1, 1, 1), _snapVec)
        
        return round(point /  s) * s
    }
    
    func zoom() {
        if let gameView = GameView.instance {
            let d = gameView.scene.eye - gameView.scene.target
            
            if fabsf(gameView.deltaY) > 0.1 {
                gameView.scene.eye = gameView.scene.target + simd_normalize(d) * (simd_length(d) - gameView.deltaY)
            }
        }
    }
    
    func rotateAroundTarget() {
        if let gameView = GameView.instance {
            var m = Mat4.rotate(-gameView.deltaX, Vec3(0, 1, 0))
            var f = gameView.scene.eye - gameView.scene.target
            var u = gameView.scene.up
            let r = simd_normalize(Mat4.transformNormal(m, simd_cross(f, u)))
            
            f = Mat4.transformNormal(m, f)
            m = Mat4.rotate(-gameView.deltaY, r)
            u = simd_normalize(Mat4.transformNormal(m, simd_cross(r, f)))
            f = Mat4.transformNormal(m, f)
            gameView.scene.eye = gameView.scene.target + f
            gameView.scene.up = u
        }
    }
    
    func pick(root: Node, node: Node, orig: Vec3, dir: Vec3, time: inout Float) -> Bool {
        var hit = false
        
        if root.isLocation {
            let d = Vec3(1, 1, 1) * 16
            let b = AABB(node.absolutePosition - d, node.absolutePosition + d)
            
            if b.isect(origin: orig, direction: dir, time: &time) {
                hit = true
            }
        } else {
            if let encodable = node.encodable {
                for i in (0..<encodable.triangleCount) {
                    var triangle = encodable.triangleAt(node: node, i: i)
                    var t = time
                    
                    triangle.transform(node.model)
                    
                    if encodable is KFMesh || encodable is ParticleSystem {
                        if triangle.isects(origin: orig, direction: dir, buffer: 0, time: &t) {
                            time = t
                            _pickTri = i
                            _triPoint = triangle.p1
                            hit = true
                        }
                    } else {
                        if simd_dot(triangle.normal, dir) < 0 {
                            if triangle.isectsPlane(origin: orig, direction: dir, time: &t) {
                                if triangle.contains(point: orig + t * dir, buffer: 0) {
                                    time = t
                                    _pickTri = i
                                    _triPoint = triangle.p1
                                    hit = true
                                }
                            }
                        }
                    }
                }
            }
            for i in (0..<node.childCount) {
                let child = node[i]
                
                if pick(root: root, node: child, orig: orig, dir: dir, time: &time) {
                    hit = true
                }
            }
        }
        return hit
    }
    
    func save(url: URL) {
        var text = ""
        
        Log.instance.put("saving scene \(url.path)")
        
        for i in (0..<GameView.instance!.scene.root.childCount) {
            let node = GameView.instance!.scene.root[i]
            let name = node.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let p = node.position
            let r = node.r
            let u = node.u
            let f = node.f
            
            if !name.isEmpty {
                text = "\(text)# name x y z rx ry rz ux uy uz fx fy fz\n"
                text = "\(text)\(name) \(p.x) \(p.y) \(p.z) \(r.x) \(r.y) \(r.z) \(u.x) \(u.y) \(u.z) \(f.x) \(f.y) \(f.z)"
                if let value = node.data["value"] as? String {
                    text = "\(text) \(value)"
                }
                text = "\(text)\n"
            }
        }
        do {
            try text.write(to: url, atomically: true, encoding: .ascii)
        } catch {
            Log.instance.put(error.localizedDescription)
        }
    }
}

@MainActor
struct GameControl : NSViewRepresentable {
    
    @Binding public var selectedNode: Int
    @Binding public var mouseMode:Int
    @Binding public var snap:String
    @Binding public var running:Bool
    @Binding public var runURL:URL?
    @Binding public var sceneURL:URL?
    @Binding public var shouldLoadScene:Bool
    @Binding public var shouldSaveScene:Bool
    @Binding public var selectedNodeLabel:String
    @Binding public var selectedURL:URL?
    @Binding public var x2:Bool
    @Binding public var value:String
    
    public init(selectedNode: Binding<Int>,
                mouseMode: Binding<Int>,
                snap: Binding<String>,
                running: Binding<Bool>,
                runURL: Binding<URL?>,
                sceneURL: Binding<URL?>,
                selectedNodeLabel: Binding<String>,
                shouldLoadScene: Binding<Bool>,
                shouldSaveScene: Binding<Bool>,
                selectedURL: Binding<URL?>,
                x2: Binding<Bool>,
                value: Binding<String>
    ) {
        _selectedNode = selectedNode
        _mouseMode = mouseMode
        _snap = snap
        _running = running
        _runURL = runURL
        _sceneURL = sceneURL
        _selectedNodeLabel = selectedNodeLabel
        _shouldLoadScene = shouldLoadScene
        _shouldSaveScene = shouldSaveScene
        _selectedURL = selectedURL
        _x2 = x2
        _value = value
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    public func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSViewType, context: Context) -> CGSize? {
        nil
    }
    
    public func makeNSView(context: Context) -> some NSView {
        let gameView = GameView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), device: MTLCreateSystemDefaultDevice(), inProduction: false)
        
        gameView.delegate = context.coordinator
        
        return gameView
    }
    
    public func updateNSView(_ nsView: NSViewType, context: Context) {
    }
    
    @MainActor
    public class Coordinator : NSObject, MTKViewDelegate {
        
        public var parent:GameControl
        
        private var controller = GameViewController()
        
        public init(parent:GameControl) {
            self.parent = parent
            
            super.init()
        }
        
        public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }
        
        public func draw(in view: MTKView) {
            if let gameView = view as? GameView {
                gameView.x2 = parent.x2
                
                if parent.running {
                    do {
                        if let runURL = parent.runURL {
                            parent.runURL = nil
                            _game = Game()
                            try _game.create(name: runURL.lastPathComponent, inDesign: false)
                        } else {
                            try _game.update()
                        }
                    } catch {
                        Log.instance.put(error.localizedDescription)
                    }
                    if(gameView.isKeyDown(key: 53)) {
                        gameView.continuousMouseEnabled = false
                        parent.running = false
                        try _game = Game()
                    }
                } else {
                    if let url = parent.sceneURL {
                        if parent.shouldLoadScene {
                            parent.shouldLoadScene = false
                            do {
                                _game = Game()
                                try _game.create(name: url.lastPathComponent, inDesign: true)
                                
                                controller.selectedNode = nil
                            } catch {
                                Log.instance.put(error.localizedDescription)
                            }
                        }
                        
                        do {
                            try _game.update()
                        } catch {
                            Log.instance.put(error.localizedDescription)
                        }
                        
                        if parent.shouldSaveScene {
                            parent.shouldSaveScene = false
                            gameView.scene.save(url: url)
                        }
                        
                        let s = parent.snap.split(whereSeparator: \.isWhitespace)
                        
                        if s.count == 2 {
                            _snapVec = Vec3(
                                (s[0] as NSString).floatValue,
                                (s[1] as NSString).floatValue,
                                (s[0] as NSString).floatValue
                            )
                        }
                        
                        if parent.selectedNode != -1 {
                            controller.selectedNode = gameView.scene.root[parent.selectedNode]
                            controller.selectedNode!.data["value"] = parent.value
                        } else {
                            controller.selectedNode = nil
                            parent.value = ""
                        }
                        controller.mode = parent.mouseMode
                        
                        if let i = controller.handleInput() {
                            parent.selectedNode = i
                            if i == -1 {
                                parent.selectedNodeLabel = ""
                            } else {
                                parent.selectedNodeLabel = gameView.scene.root[i].name
                            }
                        }

                        if let selectedNode = controller.selectedNode {
                            if let value = selectedNode.data["value"] as? String {
                                parent.value = value
                            } else {
                                parent.value = ""
                            }
                        } else {
                            parent.value = ""
                        }
                    }
                }
                gameView.scene.clearCounts()
                gameView.scene.encode()
                gameView.tick()
            }
        }
    }
}

