//
//  AABB.swift
//  XGE
//
//  Created by Douglas McNamara on 9/4/25.
//

import Foundation
import simd

public struct AABB {
    public var min = Vec3()
    public var max = Vec3()
    
    public init() {
        clear()
    }
    
    public init(_ min:Vec3, _ max:Vec3) {
        self.init()
        self.min = min
        self.max = max
    }
    
    public var isEmpty:Bool {
        get {
            min.x > max.x || min.y > max.y || min.z > max.z
        }
    }
    
    public var center:Vec3 {
        get {
            (max + min) / 2
        }
    }
    
    public var size:Vec3 {
        get {
            max - min
        }
    }
    
    public func touches(_ b:AABB) -> Bool {
        if !isEmpty {
            return !(
                b.min.x > max.x ||
                b.max.x < min.x ||
                b.min.y > max.y ||
                b.max.y < min.y ||
                b.min.z > max.z ||
                b.max.z < min.z
            )
        }
        return false
    }
    
    public func contains(_ p:Vec3) -> Bool {
        if !isEmpty {
            return p.x >= min.x && p.x <= max.x &&
            p.y >= min.y && p.y <= max.y &&
            p.z >= min.z && p.z <= max.z
        }
        return false
    }
    
    public mutating func clear() {
        min = Vec3(1, 1, 1) * Float.greatestFiniteMagnitude
        max = -min
    }
    
    public mutating func add(_ p:Vec3) {
        min.x = Float.minimum(p.x, min.x)
        min.y = Float.minimum(p.y, min.y)
        min.z = Float.minimum(p.z, min.z)
        max.x = Float.maximum(p.x, max.x)
        max.y = Float.maximum(p.y, max.y)
        max.z = Float.maximum(p.z, max.z)
    }
    
    public mutating func add(_ b:AABB) {
        if !b.isEmpty {
            add(b.min)
            add(b.max)
        }
    }
    
    public mutating func transform(_ m:Mat4) {
        if !isEmpty {
            let b = self
            
            min = Vec3(m.columns.3.x, m.columns.3.y, m.columns.3.z)
            max = min
            
            min.x += (m.columns.0.x < 0) ? m.columns.0.x * b.max.x : m.columns.0.x * b.min.x
            min.x += (m.columns.1.x < 0) ? m.columns.1.x * b.max.y : m.columns.1.x * b.min.y
            min.x += (m.columns.2.x < 0) ? m.columns.2.x * b.max.z : m.columns.2.x * b.min.z
            max.x += (m.columns.0.x > 0) ? m.columns.0.x * b.max.x : m.columns.0.x * b.min.x
            max.x += (m.columns.1.x > 0) ? m.columns.1.x * b.max.y : m.columns.1.x * b.min.y
            max.x += (m.columns.2.x > 0) ? m.columns.2.x * b.max.z : m.columns.2.x * b.min.z
            
            min.y += (m.columns.0.y < 0) ? m.columns.0.y * b.max.x : m.columns.0.y * b.min.x
            min.y += (m.columns.1.y < 0) ? m.columns.1.y * b.max.y : m.columns.1.y * b.min.y
            min.y += (m.columns.2.y < 0) ? m.columns.2.y * b.max.z : m.columns.2.y * b.min.z
            max.y += (m.columns.0.y > 0) ? m.columns.0.y * b.max.x : m.columns.0.y * b.min.x
            max.y += (m.columns.1.y > 0) ? m.columns.1.y * b.max.y : m.columns.1.y * b.min.y
            max.y += (m.columns.2.y > 0) ? m.columns.2.y * b.max.z : m.columns.2.y * b.min.z
            
            min.z += (m.columns.0.z < 0) ? m.columns.0.z * b.max.x : m.columns.0.z * b.min.x
            min.z += (m.columns.1.z < 0) ? m.columns.1.z * b.max.y : m.columns.1.z * b.min.y
            min.z += (m.columns.2.z < 0) ? m.columns.2.z * b.max.z : m.columns.2.z * b.min.z
            max.z += (m.columns.0.z > 0) ? m.columns.0.z * b.max.x : m.columns.0.z * b.min.x
            max.z += (m.columns.1.z > 0) ? m.columns.1.z * b.max.y : m.columns.1.z * b.min.y
            max.z += (m.columns.2.z > 0) ? m.columns.2.z * b.max.z : m.columns.2.z * b.min.z
        }
    }
    
    public mutating func buffer(_ amount:Vec3) {
        if !isEmpty {
            min -= amount
            max += amount
        }
    }
    
    public func isect(origin: Vec3, direction:Vec3, time:inout Float) -> Bool {
        var tnear = -Float.infinity
        var tfar = Float.infinity
        
        for i in (0..<3) {
            if abs(direction[i]) < 0.0000001 {
                if origin[i] < min[i] || origin[i] > max[i] {
                    return false
                }
            } else {
                var t1 = (min[i] - origin[i]) / direction[i]
                var t2 = (max[i] - origin[i]) / direction[i]
                
                if t1 > t2 {
                    let temp = t1
                    t1 = t2
                    t2 = temp
                }
                if t1 > tnear {
                    tnear = t1
                }
                if t2 < tfar {
                    tfar = t2
                }
                if tnear > tfar {
                    return false
                }
                if tfar < 0 {
                    return false
                }
            }
        }
        if tnear > 0 {
            if tnear < time {
                time = tnear
                return true
            }
        } else if tfar < time {
            time = tfar
            return true
        }
        return false
    }
    
    public var description:String {
        get { "\(min) -> \(max)"}
    }
}
