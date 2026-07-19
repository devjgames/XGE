//
//  Node.swift
//  XGE
//
//  Created by Douglas McNamara on 9/8/25.
//

import Foundation
import Metal
import MetalKit
import simd
import JavaScriptCore

@MainActor
public protocol Encodable {
    
    var bounds : AABB { get }
    
    var triangleCount : Int { get }
    
    func triangleAt(node: Node, i: Int) -> Triangle
    
    func update(node: Node)
    
    func encode(encoder: MTLRenderCommandEncoder, node: Node, lights: inout [Light]) -> Int
    
    func newInstance() -> Encodable
}

@MainActor
public class Node {
    
    public var name = ""
    public var data:[String:Any] = [:]
    public var visible = true
    public var collidable = false
    public var dynamic = false
    public var emitsLight = false
    public var receivesLight = true
    public var blendEnabled = false
    public var alphaBlend = true
    public var depthWriteEnabled = true
    public var depthTestEnabled = true
    public var cullEnabled = true
    public var warpEnabled = false
    public var position = Vec3(0, 0, 0)
    public var absolutePosition = Vec3(0, 0, 0)
    public var r = Vec3(1, 0, 0)
    public var u = Vec3(0, 1, 0)
    public var f = Vec3(0, 0, 1)
    public var scale = Vec3(1, 1, 1)
    public var model = Mat4.identity()
    public var modelIT = Mat4.identity()
    public var bounds = AABB()
    public var ambientColor = Vec4(0.2, 0.2, 0.2, 1)
    public var diffuseColor = Vec4(1, 1, 1, 1)
    public var specularColor = Vec4(0, 0, 0, 1)
    public var lightColor = Vec4(1, 1, 1, 1)
    public var zOrder:Int = 0
    public var specularPower:Float = 32
    public var warpAmplitude:Float = 8
    public var warpFrequency:Float = 0.05
    public var warpSpeed:Float = 2
    public var warpTime:Float = 0
    public var warpY:Bool = false
    public var lightRadius:Float = 300
    public var encodable:Encodable?
    
    private weak var _parent:Node?
    private var _children:[Node] = []
    private var _triangles:[Triangle]?
    
    public init() {
    }
    
    public var isLocation : Bool {
        get {
            if encodable == nil {
                for child in _children {
                    if !child.isLocation {
                        return false
                    }
                }
                return true
            }
            return false
        }
    }
    
    public var parent : Node? {
        get { _parent }
    }
    
    public var root : Node {
        get {
            var root = self
            
            while root.parent != nil {
                root = root.parent!
            }
            return root
        }
    }
    
    public var triangleCount : Int {
        get {
            if collidable {
                if let encodable = encodable {
                    return encodable.triangleCount
                }
            }
            return 0
        }
    }
    
    public var childCount : Int {
        get { _children.count }
    }
    
    public subscript(_ i:Int) -> Node {
        get { _children[i] }
    }
    
    public func addChild(_ child: Node) {
        child.detachFromParent()
        child._parent = self
        _children.append(child)
    }
    
    public func detachFromParent() {
        if _parent != nil {
            _parent!._children.removeAll { n in n === self }
            _parent = nil
        }
    }
    
    public func detachAll() {
        while childCount != 0 {
            _children.first!.detachFromParent()
        }
    }
    
    public func triangleAt(i :Int) -> Triangle? {
        if let encodable = encodable {
            if collidable {
                if dynamic {
                    var triangle = encodable.triangleAt(node: self, i: i)
                    
                    triangle.transform(model)
                    
                    return triangle
                } else {
                    if _triangles == nil {
                        _triangles = []
                        for i in (0..<encodable.triangleCount) {
                            var triangle = encodable.triangleAt(node: self, i: i)
                            
                            triangle.transform(model)
                            
                            _triangles!.append(triangle)
                        }
                    }
                    return _triangles![i]
                }
            }
        }
        return nil
    }
    
    public func lookAt(target: Vec3, up: Vec3) {
        u = simd_normalize(up)
        f = simd_normalize(target - absolutePosition)
        r = simd_normalize(simd_cross(u, f))
        u = simd_normalize(simd_cross(f, r))
    }
    
    public func rotate(axis: Int, degrees: Float) {
        if axis == 0 {
            let m = Mat4.rotate(degrees, r)
            
            u = simd_normalize(Mat4.transformNormal(m, u))
            f = simd_normalize(Mat4.transformNormal(m, f))
        } else if axis == 1 {
            let m = Mat4.rotate(degrees, u)
            
            r = simd_normalize(Mat4.transformNormal(m, r))
            f = simd_normalize(Mat4.transformNormal(m, f))
        } else {
            let m = Mat4.rotate(degrees, f)
            
            u = simd_normalize(Mat4.transformNormal(m, u))
            r = simd_normalize(Mat4.transformNormal(m, r))
        }
    }
    
    public func update() {
        warpTime += GameView.instance!.elapsedTime * warpSpeed
        
        if let encodable = encodable {
            encodable.update(node: self)
        }
        for child in _children {
            child.update()
        }
    }
    
    public func find(name: String) -> Node? {
        if name == self.name {
            return self
        }
        for child in _children {
            if let node = child.find(name: name) {
                return node
            }
        }
        return nil
    }
    
    public func calcBoundsAndTransform() {
        model =
        Mat4.translation(position) *
        Mat4(rows:
                [
                    [ r.x, u.x, f.x, 0 ],
                    [ r.y, u.y, f.y, 0 ],
                    [ r.z, u.z, f.z, 0 ],
                    [ 0, 0, 0, 1 ]
                    ]
        ) *
        Mat4.scale(scale)

        if let parent = _parent {
            model = parent.model * model
        }
        modelIT = simd_transpose(simd_inverse(model))
        
        let ap = model * Vec4(0, 0, 0, 1)
        
        absolutePosition = Vec3(ap.x, ap.y, ap.z)
        
        bounds = AABB()
        if let encodable = encodable {
            bounds = encodable.bounds
            bounds.transform(model)
        }
        if emitsLight {
            bounds.add(absolutePosition - Vec3(1, 1, 1) * lightRadius)
            bounds.add(absolutePosition + Vec3(1, 1, 1) * lightRadius)
        }
        for child in _children {
            child.calcBoundsAndTransform()
            
            bounds.add(child.bounds)
        }
    }
    
    public func join() {
        let mesh = Mesh()
        var parts:[String:MeshPart] = [:]

        join(parts: &parts)

        for name in parts.keys {
            if let part = parts[name] {
                mesh.parts.append(part)
            }
        }
        mesh.calcBounds(calcPartBounds: true)
        mesh.createBuffers()
        
        encodable = mesh
        
        detachAll()
    }
    
    private func join(parts: inout [String:MeshPart]) {
        if let mesh = encodable as? Mesh {
            for ipart in mesh.parts {
                var name = ""
                
                if let texture = ipart.texture {
                    if let label = texture.label {
                        name = label
                    }
                }
                if parts[name] == nil {
                    let part = MeshPart()
                    
                    Log.instance.put("creating part '\(name)' ...")
                    
                    part.name = name
                    part.texture = ipart.texture
                    part.decal = ipart.decal
                    
                    parts[name] = part
                }
                if let part = parts[name] {
                    let base = part.vertices.count
                    
                    for v in ipart.vertices {
                        var tv = v
                        let p = model * Vec4(v.position, 1)
                        let n = modelIT * Vec4(v.normal, 0)
                        
                        tv.position = Vec3(p.x, p.y, p.z)
                        tv.normal = Vec3(n.x, n.y, n.z)
                        tv.color = diffuseColor
                        part.vertices.append(tv)
                    }
                    for i in ipart.indices {
                        part.indices.append(Int32(base) + i)
                    }
                }
            }
        }
        for node in _children {
            node.join(parts: &parts)
        }
    }
}
