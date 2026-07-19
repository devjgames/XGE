//
//  Triangle.swift
//  XGE
//
//  Created by Douglas McNamara on 9/4/25.
//

import Foundation
import simd

public struct Triangle {
    
    public var p1:Vec3 = Vec3(0, 0, 0)
    public var p2:Vec3 = Vec3(1, 0, 0)
    public var p3:Vec3 = Vec3(0, 0, 1)
    public var normal:Vec3 = Vec3(0, 1, 0)
    public var d:Float = 0
    
    public init() {
        calcPlane()
    }
    
    public init(_ p1:Vec3, _ p2:Vec3, _ p3:Vec3) {
        self.p1 = p1
        self.p2 = p2
        self.p3 = p3
        
        calcPlane()
    }
    
    public subscript(_ i:Int) -> Vec3 {
        get {
            if i == 1 {
                return p2
            } else if i == 2 {
                return p3
            } else {
                return p1
            }
        }
    }
    
    public mutating func calcPlane() {
        normal = simd_normalize(simd_cross(p3 - p2, p2 - p1))
        d = -simd_dot(p1, normal)
    }
    
    public mutating func transform(_ m:Mat4) {
        let a = m * Vec4(p1, 1)
        let b = m * Vec4(p2, 1)
        let c = m * Vec4(p3, 1)
        
        p1 = Vec3(a.x, a.y, a.z)
        p2 = Vec3(b.x, b.y, b.z)
        p3 = Vec3(c.x, c.y, c.z)
        
        calcPlane()
    }
    
    public func contains(point:Vec3, buffer:Float) -> Bool {
        for i in (0..<3) {
            let a = self[i]
            let b = self[i + 1]
            let e = simd_normalize(b - a)
            let n = simd_normalize(simd_cross(e, normal))
            let d = -simd_dot(a - n * buffer, n)
            let s = simd_dot(n, point) + d
            
            if s < 0 {
                return false
            }
        }
        return true
    }
    
    public func isectsPlane(origin:Vec3, direction:Vec3, time:inout Float) -> Bool {
        var t = simd_dot(direction, normal)
        
        if abs(t) > 0.0000001 {
            t = (-d - simd_dot(origin, normal)) / t
            if t > 0.0000001 && t < time {
                time = t
                return true
            }
        }
        return false
    }
    
    public func isects(origin:Vec3, direction:Vec3, buffer:Float, time:inout Float) -> Bool {
        var t = time
        
        if isectsPlane(origin: origin, direction: direction, time: &t) {
            let p = origin + t * direction
            
            if contains(point: p, buffer: buffer) {
                time = t
                return true
            }
        }
        return false
    }
    
    public func closestPoint(point:Vec3) -> Vec3 {
        var cp = p1
        var minL = Float.greatestFiniteMagnitude
        
        for i in (0..<3) {
            let a = self[i]
            let b = self[i + 1]
            let ap = point - a
            let ab = b - a
            var c = a
            var s = simd_dot(ap, ab)
            
            if s > 0.0 {
                s /= simd_dot(ab, ab)
                if s >= 1.0 {
                    c = b
                } else {
                    c = a + s * ab
                }
            }
            
            let v = point - c
            let l = simd_length(v)
            
            if l < minL {
                minL = l
                cp = c
            }
        }
        return cp
    }
    
    public var description:String {
        get { "\(p1) : \(p2) : \(p3) : \(normal) : \(d)" }
    }
}
