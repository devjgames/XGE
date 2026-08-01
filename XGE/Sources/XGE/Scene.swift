//
//  Scene.swift
//  XGE
//
//  Created by Douglas McNamara on 9/8/25.
//

import Foundation
import simd
import Metal
import MetalKit
import JavaScriptCore

@MainActor
public class Scene {
    
    public var loadSceneName:String?
    public var backgroundColor = Vec4(0.25, 0.25, 0.25, 1)
    public var eye = Vec3(200, 200, 200)
    public var target = Vec3(0, 0, 0)
    public var up = Vec3(0, 1, 0)
    public var fieldOfView:Float = 60
    public var zNear:Float = 1
    public var zFar:Float = 50000
    public var projection = Mat4.identity()
    public var view = Mat4.identity()
    public var root = Node()
    public var snap = 1
    public let frustum = Frustum()
    
    fileprivate var url:URL?
    
    private var _lights : [Node] = []
    private var _encodables : [Node] = []
    private var _sprite:Sprite?
    private var _lines = Node()
    private var _lineEncoder:LineEncoder?
    private var _trianglesRendered:Int = 0
    private var _cullStateBinds = 0
    private var _depthStateBinds = 0
    private var _renderStateBinds = 0
    private var _rendered:Int = 0
    
    public init() {
        let path = "sprites.png"
        
        if GameView.instance!.assets.assetExists(path: path) {
            do {
                _sprite = Sprite(texture: try GameView.instance!.assets.load(path: path) as! MTLTexture)
            } catch {
                Log.instance.put(error)
            }
        }
        _lineEncoder = LineEncoder()
    }
    
    public var trianglesRendered: Int {
        get { _trianglesRendered }
    }
    
    public var cullStateBinds: Int {
        get { _cullStateBinds }
    }
    
    public var depthStateBinds: Int {
        get { _depthStateBinds }
    }
    
    public var renderStateBinds: Int {
        get { _renderStateBinds }
    }
    
    public var rendered: Int {
        get { _rendered }
    }
    
    public var name : String {
        get {
            if let url = url {
                return url.lastPathComponent
            }
            return ""
        }
    }
    
    public var sprite: Sprite? {
        get { _sprite }
    }
    
    public func rotateAroundEye(dx: Float, dy: Float) {
        var f = simd_normalize(target - eye)
        var m = Mat4.rotate(dx, Vec3(0, 1, 0))
        let r = simd_normalize(Mat4.transformNormal(m, simd_cross(f, up)))
        
        f = simd_normalize(Mat4.transformNormal(m, f))
        m = Mat4.rotate(dy, r)
        up = simd_normalize(Mat4.transformNormal(m, simd_cross(r, f)))
        target = eye + simd_normalize(Mat4.transformNormal(m, f))
    }
    
    public func encode() {
        if let sprite = _sprite {
            sprite.buffer()
        }
        if let drawable = GameView.instance!.currentDrawable {
            if let renderPassDescriptor = GameView.instance!.currentRenderPassDescriptor {
                
                projection = Mat4.perspective(fieldOfView, Float(GameView.instance!.drawableSize.width / GameView.instance!.drawableSize.height), zNear, zFar)
                view = Mat4.lookAt(eye, target, up)
                frustum.calcPlanes(projection: projection, view: view)
                root.calcBoundsAndTransform()
                root.update()
                root.calcBoundsAndTransform()
                
                _trianglesRendered = 0
                _cullStateBinds = 0
                _depthStateBinds = 0
                _renderStateBinds = 0
                _rendered = 0
                
                _lights.removeAll(keepingCapacity: true)
                _encodables.removeAll(keepingCapacity: true)
                
                traverse(node: root)
                
                if GameView.inDesign {
                    if let lineEncoder = _lineEncoder {
                        for i in (0..<root.childCount) {
                            let node = root[i]
                            
                            if node.isLocation {
                                let s:Float = 16
                                let p = node.absolutePosition
                                let r = simd_normalize(node.r)
                                let u = simd_normalize(node.u)
                                let f = simd_normalize(node.f)
                                
                                lineEncoder.pushLine(p1: p, p2: p + r * s, c1: Vec4(1, 0, 0, 1), c2: Vec4(1, 0, 0, 1))
                                lineEncoder.pushLine(p1: p, p2: p + u * s, c1: Vec4(0, 1, 0, 1), c2: Vec4(0, 1, 0, 1))
                                lineEncoder.pushLine(p1: p, p2: p + f * s, c1: Vec4(0, 0, 1, 1), c2: Vec4(0, 0, 1, 1))
                            }
                        }
                        let s:Float = 32
                        let p = target
                        
                        lineEncoder.pushLine(p1: p, p2: p + Vec3(s, 0, 0), c1: Vec4(1, 0, 0, 1), c2: Vec4(1, 0, 0, 1))
                        lineEncoder.pushLine(p1: p, p2: p + Vec3(0, s, 0), c1: Vec4(0, 1, 0, 1), c2: Vec4(0, 1, 0, 1))
                        lineEncoder.pushLine(p1: p, p2: p + Vec3(0, 0, s), c1: Vec4(0, 0, 1, 1), c2: Vec4(0, 0, 1, 1))
                        lineEncoder.buffer()
                        
                        _encodables.append(_lines)
                    }
                }
                
                _encodables.sort {
                    a, b in
                    
                    if a.zOrder == b.zOrder {
                        let da = simd_distance(a.absolutePosition, eye)
                        let db = simd_distance(b.absolutePosition, eye)
                        
                        return db < da
                    } else {
                        return a.zOrder < b.zOrder
                    }
                }
                _lights.sort {
                    a, b in
                    
                    let da = simd_distance(a.absolutePosition, target)
                    let db = simd_distance(b.absolutePosition, target)
                    
                    return da < db
                }
                
                var lights:[Light] = []
                
                for i in (0..<min(_lights.count, MaxLights)) {
                    var light = Light()
                    let node = _lights[i]
                    
                    light.position = node.absolutePosition
                    light.color = node.lightColor
                    light.radius = node.lightRadius
                    lights.append(light)
                }
                if lights.isEmpty {
                    var light = Light()
                    
                    light.position = Vec3(0, -Float.greatestFiniteMagnitude, 0)
                    light.color = Vec4(0, 0, 0, 1)
                    light.radius = 10
                    lights.append(light)
                }
                
                GameView.instance!.clearColor = MTLClearColor(red: Double(backgroundColor.x), green: Double(backgroundColor.y), blue: Double(backgroundColor.z), alpha: Double(backgroundColor.w))
                
                let commandBuffer = GameView.instance!.commandQueue.makeCommandBuffer()!
                let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
                var renderStateKey = ""
                var depthStateKey = ""
                var cullStateKey = ""
                var count:Int = 0
                
                encoder.setViewport(MTLViewport(
                    originX: 0, originY: 0, width: Double(GameView.instance!.drawableSize.width), height: Double(GameView.instance!.drawableSize.height), znear: 0, zfar: 1))
                
                for node in _encodables {
                    if let encodable = node.encodable {
                        let csk = "\(node.cullEnabled)"
                        
                        if csk != cullStateKey {
                            _cullStateBinds += 1
                            if node.cullEnabled {
                                encoder.setCullMode(.back)
                            } else {
                                encoder.setCullMode(.none)
                            }
                            cullStateKey = csk
                        }
                        
                        let dsk = "\(node.depthTestEnabled):\(node.depthWriteEnabled)"

                        if dsk != depthStateKey {
                            if let depthState = GameView.instance!.depthState(depthTestEnabled: node.depthTestEnabled, depthWriteEnabled: node.depthWriteEnabled) {
                                _depthStateBinds += 1
                                encoder.setDepthStencilState(depthState)
                                depthStateKey = dsk
                                count += 1
                            }
                        }
                        
                        let rsk = "\(node.blendEnabled):\(node.alphaBlend)"
                        
                        if rsk != renderStateKey {
                            if let renderPipeline = GameView.instance!.renderPipeline(blendEnabled: node.blendEnabled, alphaBlend: node.alphaBlend) {
                                _renderStateBinds += 1
                                encoder.setRenderPipelineState(renderPipeline)
                                renderStateKey = rsk
                                count += 1
                            }
                        }
                        if count >= 2 {
                            _trianglesRendered += encodable.encode(encoder: encoder, node: node, lights: &lights)
                            _rendered += 1
                        }
                    } else if node === _lines {
                        if let lineEncoder = _lineEncoder {
                            lineEncoder.encode(encoder: encoder)
                        }
                    }
                }
                if let sprite = _sprite {
                    sprite.encode(encoder: encoder)
                }
                encoder.endEncoding()
                commandBuffer.present(drawable)
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
                
                _lights.removeAll(keepingCapacity: true)
                _encodables.removeAll(keepingCapacity: true)
            }
        }
    }
    
    private func traverse(node: Node) {
        if node.visible {
            if frustum.contains(bounds: node.bounds) {
                if let _ = node.encodable {
                    _encodables.append(node)
                }
                if node.emitsLight {
                    if frustum.contains(center: node.absolutePosition, radius: node.lightRadius) {
                        _lights.append(node)
                    }
                }
                for i in (0..<node.childCount) {
                    traverse(node: node[i])
                }
            }
        }
    }
}

@MainActor
public func loadScene(url: URL, api:Api) throws {
    Log.instance.put("loading scene '\(url.lastPathComponent)'")

    GameView.instance!.newScene()
    GameView.instance!.scene.url = url
    
    GameView.instance!.resetTimer()
    
    try loadNode(url: url, api: api, root:GameView.instance!.scene.root)
    
    GameView.instance!.scene.root.calcBoundsAndTransform()
    GameView.instance!.resetTimer()
}

@MainActor
public func evalLib(context:JSContext) throws {
    let items = try FileManager.default.contentsOfDirectory(atPath: AssetManager.rootURL!.path)
    
    for item in items {
        if (item as NSString).pathExtension == "js" {
            if item.hasPrefix("Lib") {
                Log.instance.put("evaluating lib '\(item)' ...")
                
                context.evaluateScript(try String(contentsOf: AssetManager.rootURL!.appending(path: item), encoding: .utf8))
            }
        }
    }
}

@MainActor
public func loadNode(url:URL, api:Api, root:Node) throws {
    Log.instance.put("loading node '\(url.lastPathComponent)'")
    
    if !FileManager.default.fileExists(atPath: url.path()) {
        throw NSError(domain: "file not found", code: 0)
    }
    let lines = try String(contentsOf: url, encoding: .ascii).trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .newlines)
    
    for line in lines {
        let tLine = line.trimmingCharacters(in: .whitespaces)
        
        if !tLine.isEmpty && !tLine.hasPrefix("#") {
            let tokens = tLine.components(separatedBy: .whitespaces)
            
            if tokens.count == 1 + 3 * 4 {
                let node = Node()
                
                node.name = tokens[0]

                node.position = Vec3(
                    (tokens[1] as NSString).floatValue,
                    (tokens[2] as NSString).floatValue,
                    (tokens[3] as NSString).floatValue
                )
                node.r = Vec3(
                    (tokens[4] as NSString).floatValue,
                    (tokens[5] as NSString).floatValue,
                    (tokens[6] as NSString).floatValue
                )
                node.u = Vec3(
                    (tokens[7] as NSString).floatValue,
                    (tokens[8] as NSString).floatValue,
                    (tokens[9] as NSString).floatValue
                )
                node.f = Vec3(
                    (tokens[10] as NSString).floatValue,
                    (tokens[11] as NSString).floatValue,
                    (tokens[12] as NSString).floatValue
                )
                root.addChild(node)
                
                api.initApi(node: node)
                api.setScriptNode(node: node)
                api.setInitState(isInit: true)
                if let context = node.context {
                    do {
                        node.script = try String(contentsOf: AssetManager.rootURL!.appending(path: node.name).appendingPathExtension("js"), encoding: .utf8)
                        if let script = node.script {
                            try evalLib(context: context)
                            context.evaluateScript(script)
                        }
                    } catch {
                        Log.instance.put(error.localizedDescription)
                    }
                }
            } else {
                Log.instance.put("invalid scene line '\(line)")
            }
        }
    }
}
