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
public func loadSCX(name:String) {
    
    Log.instance.put("loading '\(name)' ...")
    
    let url = AssetManager.rootURL!.appending(path: name)
    let scene = GameView.instance!.scene
    
    do {
        let doc = try XMLDocument(data: try Data(contentsOf: url))
        
        if let root = doc.rootElement() {
            scene.backgroundColor = try parseVec4(value: attribute(root, named: "backgroundColor"))
            scene.eye = try parseVec3(value: attribute(root, named: "eye"))
            scene.target = try parseVec3(value: attribute(root, named: "target"))
            scene.up = try parseVec3(value: attribute(root, named: "up"))
            scene.fieldOfView = (attribute(root, named: "fovDegrees") as NSString).floatValue
            scene.zNear = (attribute(root, named: "zNear") as NSString).floatValue
            scene.zFar = (attribute(root, named: "zFar") as NSString).floatValue
            
            Log.instance.put("scene parsed!")
            
            for i in (0..<root.childCount) {
                if let element = root.child(at: i) as? XMLElement {
                    try scene.root.addChild(parseNode(element))
                }
            }
        }
    } catch {
        Log.instance.put(error.localizedDescription)
    }
}

@MainActor
fileprivate func parseVec4(value:String) throws -> Vec4 {
    let tokens = value.components(separatedBy: .whitespaces)
    
    if(tokens.count != 4) {
        throw NSError(domain: "failed to parse vec4", code: 0)
    }
    return Vec4(
        (tokens[0] as NSString).floatValue,
        (tokens[1] as NSString).floatValue,
        (tokens[2] as NSString).floatValue,
        (tokens[3] as NSString).floatValue
    )
}

@MainActor
fileprivate func parseVec3(value:String) throws -> Vec3 {
    let tokens = value.components(separatedBy: .whitespaces)
    
    if(tokens.count != 3) {
        throw NSError(domain: "failed to parse vec3", code: 0)
    }
    return Vec3(
        (tokens[0] as NSString).floatValue,
        (tokens[1] as NSString).floatValue,
        (tokens[2] as NSString).floatValue
    )
}

@MainActor
fileprivate func parseVec2(value:String) throws -> Vec2 {
    let tokens = value.components(separatedBy: .whitespaces)
    
    if(tokens.count != 2) {
        throw NSError(domain: "failed to parse vec2", code: 0)
    }
    return Vec2(
        (tokens[0] as NSString).floatValue,
        (tokens[1] as NSString).floatValue
    )
}

@MainActor
fileprivate func attribute(_ element:XMLElement, named:String) -> String {
    if let attr = element.attribute(forName: named) {
        if let value = attr.stringValue {
            return value
        }
    }
    return ""
}

@MainActor
fileprivate func parseNode(_ element:XMLElement) throws -> Node {
    let node = Node()
    
    node.name = attribute(element, named: "name")
    node.visible = (attribute(element, named: "visible") == "true") ? true : false
    node.collidable = (attribute(element, named: "collidable") == "true") ? true : false
    node.dynamic = (attribute(element, named: "dynamic") == "true") ? true : false
    node.emitsLight = (attribute(element, named: "emitsLight") == "true") ? true : false
    node.receivesLight = (attribute(element, named: "receivesLight") == "true") ? true : false
    
    let depthState = attribute(element, named: "depthState")
    
    node.depthWriteEnabled = depthState == "READWRITE"
    node.depthTestEnabled = depthState != "NONE"
    
    let blendState = attribute(element, named: "blendState")
    
    node.blendEnabled = blendState != "OPAQUE"
    node.alphaBlend = blendState == "ALPHA"
    
    let cullState = attribute(element, named: "cullState")
    
    node.cullEnabled = cullState != "NONE"
    
    node.position = try parseVec3(value:attribute(element, named: "position"))
    node.r = try parseVec3(value:attribute(element, named: "r"))
    node.u = try parseVec3(value:attribute(element, named: "u"))
    node.f = try parseVec3(value:attribute(element, named: "f"))
    node.scale = try parseVec3(value:attribute(element, named: "scale"))
    
    node.ambientColor = try parseVec4(value:attribute(element, named: "ambientColor"))
    node.diffuseColor = try parseVec4(value:attribute(element, named: "diffuseColor"))
    node.specularColor = try parseVec4(value:attribute(element, named: "specularColor"))
    node.lightColor = try parseVec4(value:attribute(element, named: "lightColor"))
    
    node.lightRadius = (attribute(element, named: "lightRadius") as NSString).floatValue
    node.specularPower = (attribute(element, named: "specularPower") as NSString).floatValue
    node.zOrder = (attribute(element, named: "zOrder") as NSString).integerValue
    
    node.warpEnabled = (attribute(element, named: "warpEnabled") == "true") ? true : false
    node.warpAmplitude = (attribute(element, named: "warpAmplitude") as NSString).floatValue
    node.warpFrequency = (attribute(element, named: "warpFrequency") as NSString).floatValue
    node.warpSpeed = (attribute(element, named: "warpSpeed") as NSString).floatValue
    node.warpY = (attribute(element, named: "warpY") == "true") ? true : false
    
    do {
        let renderable = attribute(element, named: "renderable")
        
        if !renderable.isEmpty {
            node.encodable = try GameView.instance!.assets.load(path: renderable) as? Encodable
            if let mesh = node.encodable as? KFMesh {
                node.encodable = mesh.newInstance()
            }
        }
    } catch {
        Log.instance.put(error.localizedDescription)
    }
    
    for i in (0..<element.childCount) {
        if let child = element.child(at: i) as? XMLElement {
            if child.name == "node" {
                node.addChild(try parseNode(child))
            }
        }
    }
    return node
}


