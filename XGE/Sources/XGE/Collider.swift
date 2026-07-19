//
//  Collider.swift
//  XGE
//
//  Created by Douglas McNamara on 9/8/25.
//

import Foundation
import simd

@MainActor
public class Collider {
    
    public var radius:Float = 16
    public var groundSlope:Float = 60
    public var roofSlope:Float = 45
    public var velocity:Vec3 = Vec3(0, 0, 0)
    
    private var _groundNormal:Vec3 = Vec3(0, 0, 0)
    private var _groundMatrix:Mat4 = Mat4.identity()
    private var _onGround = false
    private var _hitRoof = false
    private var _hitNode:Node?
    private var _hitTriangle:Triangle?
    private var _resolvedPosition:Vec3?
    private var _resolvedNormal:Vec3?
    private var _time:Float = 0
    private var _bounds:AABB = AABB()
    private var _position:Vec3 = Vec3(0, 0, 0)
    private var _tested:Int = 0
    private var _hitNodes:[Node] = []
    
    public init() {
    }
    
    public var hitTriangle:Triangle? {
        get { _hitTriangle }
    }
    
    public var onGround:Bool {
        get { _onGround }
    }
    
    public var hitRoof:Bool {
        get { _hitRoof }
    }
    
    public var tested: Int {
        get { _tested }
    }
    
    public var hitNodeCount: Int {
        get { _hitNodes.count }
    }
    
    public func hitNodeAt(_ i:Int) -> Node {
        _hitNodes[i]
    }
    
    public func setForwardVelocity(speedAndDirection:Float) {
        let scene = GameView.instance!.scene
        let f = (scene.target - scene.eye) * Vec3(1, 0, 1)
        let y = velocity.y
        
        if simd_length(f) > 0.0000001 {
            velocity = simd_normalize(f) * speedAndDirection
        } else {
            velocity = Vec3(0, 0, 0)
        }
        velocity.y = y
    }
    
    public func isect(root:Node, origin:Vec3, direction:Vec3, buffer:Float, collidablesOnly: Bool, time:inout Float) -> Node? {
        _hitNode = nil
        _hitTriangle = nil
        
        isect(node: root, origin: origin, direction: direction, buffer: buffer, collidablesOnly: collidablesOnly, time: &time)
        
        return _hitNode
    }
    
    private func isect(node:Node, origin:Vec3, direction:Vec3, buffer:Float, collidablesOnly: Bool, time:inout Float) {
        var b = AABB()
        
        b.add(origin)
        b.add(origin + direction * time)
        b.buffer(Vec3(1, 1, 1))
        
        if node.bounds.touches(b) {
            if node.collidable {
                for i in (0..<node.triangleCount) {
                    let triangle = node.triangleAt(i:i)
                    
                    if triangle!.isects(origin: origin, direction: direction, buffer: buffer, time: &time) {
                        _hitTriangle = triangle
                        _hitNode = node
                    }
                }
            } else if !collidablesOnly {
                if let encodable = node.encodable {
                    for i in (0..<encodable.triangleCount) {
                        var triangle = encodable.triangleAt(node: node, i: i)
                        
                        triangle.transform(node.model)
                        
                        if triangle.isects(origin: origin, direction: direction, buffer: buffer, time: &time) {
                            _hitTriangle = triangle
                            _hitNode = node
                        }
                    }
                }
            }
            for i in (0..<node.childCount) {
                isect(node: node[i], origin: origin, direction: direction, buffer: buffer, collidablesOnly:collidablesOnly, time: &time)
            }
        }
    }
    
    public func resolve(root:Node, position:Vec3) -> Vec3 {
        var d = velocity * GameView.instance!.elapsedTime
        let v = _groundMatrix * Vec4(d.x, d.y, d.z, 1)
        
        _tested = 0
        _hitNodes.removeAll(keepingCapacity: true)
        
        d = Vec3(v.x, v.y, v.z)
        if simd_length(d) > radius * 0.5 {
            d = simd_normalize(d) * radius * 0.5
        }
        
        _position = position + d
        _groundNormal = Vec3(0, 0, 0)
        _groundMatrix = Mat4.identity()
        _hitRoof = false
        _onGround = false
        
        for _ in (0..<3) {
            _hitNode = nil
            _hitTriangle = nil
            _resolvedPosition = nil
            _resolvedNormal = nil
            _bounds = AABB(_position - Vec3(1, 1, 1) * radius, _position + Vec3(1, 1, 1) * radius)
            _time = radius
            
            resolve(node: root)
            
            if let _ = _hitTriangle, let rNormal = _resolvedNormal, let rPosition = _resolvedPosition, let hNode = _hitNode {
                if acos(Float.maximum(-0.9999, Float.minimum(0.9999, dot(rNormal, Vec3(0, 1, 0))))) < Float.pi * groundSlope / 180.0 {
                    _groundNormal += rNormal
                    _onGround = true
                    velocity.y = 0
                }
                if acos(Float.maximum(-0.9999, Float.minimum(0.9999, dot(rNormal, Vec3(0, -1, 0))))) < Float.pi * roofSlope / 180.0 {
                    _hitRoof = true
                    velocity.y = 0
                }
                _position = rPosition
                
                _hitNodes.append(hNode)
            } else {
                break
            }
        }
        if _onGround {
            let u = simd_normalize(_groundNormal)
            var r = Vec3(1, 0, 0)
            let f = simd_normalize(simd_cross(r, u))
            
            r = simd_normalize(simd_cross(u, f))
            
            _groundMatrix = Mat4(
                rows: [
                    [ r.x, u.x, f.x, 0 ],
                    [ r.y, u.y, f.y, 0 ],
                    [ r.z, u.z, f.z, 0 ],
                    [ 0, 0, 0, 1 ]
                ]
            )
        }
        return _position
    }
    
    private func resolve(node:Node) {
        if(node.bounds.touches(_bounds)) {
            if node.collidable {
                for i in (0..<node.triangleCount) {
                    let triangle = node.triangleAt(i: i)!
                    var t = _time
                    let origin = _position
                    let direction = -triangle.normal
                    
                    _tested += 1
                    
                    if triangle.isectsPlane(origin: origin, direction: direction, time: &t) {
                        let p = origin + t * direction
                        
                        if triangle.contains(point: p, buffer: 0) {
                            _resolvedNormal = triangle.normal
                            _resolvedPosition = p + triangle.normal * radius
                            _time = t
                            _hitTriangle = triangle
                            _hitNode = node
                        } else {
                            let c = triangle.closestPoint(point: origin)
                            let d = _position - c
                            let l = simd_length(d)
                            
                            if l > 0.0000001 && l < _time {
                                _time = l
                                _resolvedNormal = simd_normalize(d)
                                _resolvedPosition = c + _resolvedNormal! * radius
                                _hitTriangle = triangle
                                _hitNode = node
                            }
                        }
                    }
                }
            }
            for i in (0..<node.childCount) {
                resolve(node: node[i])
            }
        }
    }
}

