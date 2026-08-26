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

@MainActor
public class Scene {

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
    public let frustum = Frustum()
    
    private var _lights : [Node] = []
    private var _encodables : [Node] = []
    private var _sprite:Sprite?
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
    
    public func clearCounts() {
        _trianglesRendered = 0
        _cullStateBinds = 0
        _depthStateBinds = 0
        _renderStateBinds = 0
        _rendered = 0
    }
    
    public func encode() {
        if let sprite = _sprite {
            sprite.buffer()
        }
        if let drawable = GameView.instance!.currentDrawable {
            if let renderPassDescriptor = GameView.instance!.currentRenderPassDescriptor {
                encode(root: root, renderPassDescriptor: renderPassDescriptor, drawable: drawable)
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
    
    public func encode(root:Node, renderPassDescriptor:MTLRenderPassDescriptor, drawable:CAMetalDrawable?) {
        root.position = Vec3(0, 0, 0)
        root.r = Vec3(1, 0, 0)
        root.u = Vec3(0, 1, 0)
        root.f = Vec3(0, 0, 1)
        root.scale = Vec3(1, 1, 1)
        
        projection = Mat4.perspective(fieldOfView,
                                      Float(renderPassDescriptor.colorAttachments[0].texture!.width) /
                                      Float(renderPassDescriptor.colorAttachments[0].texture!.height),
                                      zNear, zFar)
        view = Mat4.lookAt(eye, target, up)
        frustum.calcPlanes(projection: projection, view: view)
        root.calcBoundsAndTransform()
        root.update()
        root.calcBoundsAndTransform()
        
        _lights.removeAll(keepingCapacity: true)
        _encodables.removeAll(keepingCapacity: true)
        
        traverse(node: root)

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
        
        if drawable === nil {
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: Double(backgroundColor.x),
                                                                                green: Double(backgroundColor.y),
                                                                                blue: Double(backgroundColor.z),
                                                                                alpha: Double(backgroundColor.w))
        } else {
            GameView.instance!.clearColor = MTLClearColor(red: Double(backgroundColor.x),
                                                          green: Double(backgroundColor.y),
                                                          blue: Double(backgroundColor.z),
                                                          alpha: Double(backgroundColor.w))
        }
        
        let commandBuffer = GameView.instance!.commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        var renderStateKey = ""
        var depthStateKey = ""
        var cullStateKey = ""
        var count:Int = 0
        
        encoder.setViewport(MTLViewport(
            originX: 0,
            originY: 0,
            width: Double(renderPassDescriptor.colorAttachments[0].texture!.width),
            height: Double(renderPassDescriptor.colorAttachments[0].texture!.height), znear: 0, zfar: 1))
        
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
            }
        }
        if let _ = drawable {
            if let sprite = _sprite {
                sprite.encode(encoder: encoder)
            }
        }
        encoder.endEncoding()
        if let drawable = drawable {
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        _lights.removeAll(keepingCapacity: true)
        _encodables.removeAll(keepingCapacity: true)
    }
}

@MainActor
public func loadScene(name:String) throws -> Void {
    let lines = try String(contentsOf: AssetManager.rootURL!.appending(path: name), encoding: .utf8).split(whereSeparator: \.isNewline)
    let scene = GameView.instance!.scene
    
    for line in lines {
        let tLine = line.trimmingCharacters(in: .whitespaces)
        let tokens = tLine.split(whereSeparator: \.isWhitespace)
    
        if !tLine.starts(with: "#") && tokens.count >= 13 {
            if (tokens[0] as NSString).pathExtension == "obj" || (tokens[0] as NSString).pathExtension == "kfm" {
                let node = Node()
                
                node.encodable = try GameView.instance!.assets.load(path: "\(tokens[0])") as? Encodable
                
                node.name = "\(tokens[0])"
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
                if tokens.count > 13 {
                    node.data["value"] = "\(tokens[13])"
                } else {
                    node.data["value"] = ""
                }
                
                scene.root.addChild(node)
            }
        }
    }
}
