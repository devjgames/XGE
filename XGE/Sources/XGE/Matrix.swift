//
//  Matrix.swift
//  XGE
//
//  Created by Douglas McNamara on 9/4/25.
//

import AppKit
import simd
import MetalKit

public typealias Vec2 = simd_float2
public typealias Vec3 = simd_float3
public typealias Vec4 = simd_float4
public typealias Mat4 = simd_float4x4

public extension Mat4 {
    
    static func identity() -> Mat4 {
        Mat4(rows: [
            [ 1, 0, 0, 0 ],
            [ 0, 1, 0, 0 ],
            [ 0, 0, 1, 0 ],
            [ 0, 0, 0, 1 ]
        ])
    }
    
    static func translation(_ t:Vec3) -> Mat4 {
        Mat4(rows: [
            [ 1, 0, 0, t.x ],
            [ 0, 1, 0, t.y ],
            [ 0, 0, 1, t.z ],
            [ 0, 0, 0, 1 ]
        ])
    }
    
    static func scale(_ s:Vec3) -> Mat4 {
        Mat4(rows: [
            [ s.x, 0, 0, 0 ],
            [ 0, s.y, 0, 0 ],
            [ 0, 0, s.z, 0 ],
            [ 0, 0, 0, 1 ]
        ])
    }
    
    static func rotate(_ degrees:Float, _ axis:Vec3) -> Mat4 {
        let r = Float.pi / 180.0 * degrees
        let c = cos(r)
        let s = sin(r)
        let a = simd_normalize(axis)
        let x = a.x
        let y = a.y
        let z = a.z
        
        return Mat4(rows: [
            [ x * x * (1 - c) + c, x * y * (1 - c) - z * s, x * z * (1 - c) + y * s, 0 ],
            [ y * x * (1 - c) + z * s, y * y * (1 - c) + c, y * z * (1 - c) - x * s, 0 ],
            [ x * z * (1 - c) - y * s, y * z * (1 - c) + x * s, z * z * (1 - c) + c, 0 ],
            [ 0, 0, 0, 1 ]
        ])
    }
    
    static func ortho(_ l: Float, _ r:Float, _ b:Float, _ t:Float, _ znear:Float, _ zfar:Float) -> Mat4 {
        let x = 2 / (r - l)
        let y = 2 / (t - b)
        let z = -2 / (zfar - znear)
        let tx = -(r + l) / (r - l)
        let ty = -(t + b) / (t - b)
        let tz = -(zfar + znear) / (zfar - znear)
        
        return Mat4(rows: [
            [ x, 0, 0, tx ],
            [ 0, y, 0, ty ],
            [ 0, 0, z, tz ],
            [ 0, 0, 0, 1 ]
        ])
    }
    
    static func perspective(_ fov:Float, _ aspect:Float, _ zNear:Float, _ zFar:Float) -> Mat4 {
        let r = Float.pi / 180.0 * fov
        let f = 1 / tan(r / 2)
        let sx = f / aspect
        let sy = f
        let sz = (zFar + zNear) / (zNear - zFar)
        let tz = 2 * zFar * zNear / (zNear - zFar)
        
        return Mat4(rows: [
            [ sx, 0, 0, 0 ],
            [ 0, sy, 0, 0 ],
            [ 0, 0, sz, tz ],
            [ 0, 0, -1, 0 ]
        ])
    }
    
    static func lookAt(_ eye:Vec3, _ center:Vec3, _ up:Vec3) -> Mat4 {
        var f = simd_normalize(center - eye)
        var u = simd_normalize(up)
        let r = simd_normalize(simd_cross(f, u))
        
        u = simd_normalize(simd_cross(r, f))
        f = -f
        
        return Mat4(rows: [
            [ r.x, r.y, r.z, simd_dot(r, -eye) ],
            [ u.x, u.y, u.z, simd_dot(u, -eye) ],
            [ f.x, f.y, f.z, simd_dot(f, -eye) ],
            [ 0, 0, 0, 1 ]
        ])
    }
    
    static func transformNormal(_ m: Mat4, _ n: Vec3) -> Vec3 {
        let v = m * Vec4(n.x, n.y, n.z, 0)
        
        return Vec3(v.x, v.y, v.z)
    }
}


public class Frustum {
    
    private var planes:[Vec4] = [
        Vec4(),
        Vec4(),
        Vec4(),
        Vec4(),
        Vec4(),
        Vec4()
    ]
    
    public init() {
    }
    
    public func calcPlanes(projection:Mat4, view:Mat4) {
        let matrix = simd_transpose(projection * view)
        
        planes[0] = matrix.columns.3 + matrix.columns.0
        planes[1] = matrix.columns.3 - matrix.columns.0
        planes[2] = matrix.columns.3 + matrix.columns.1
        planes[3] = matrix.columns.3 - matrix.columns.1
        planes[4] = matrix.columns.3 + matrix.columns.2
        planes[5] = matrix.columns.3 - matrix.columns.2
        
        for i in (0..<planes.count) {
            let l = simd_length(Vec3(planes[i].x, planes[i].y, planes[i].z))
            
            planes[i] /= l
        }
    }
    
    public func contains(bounds:AABB) -> Bool {
        if bounds.isEmpty {
            return false
        }
        for plane in planes {
            var minD = plane.w
            var maxD = plane.w
            
            minD += (plane.x < 0) ? bounds.max.x * plane.x : bounds.min.x * plane.x
            minD += (plane.y < 0) ? bounds.max.y * plane.y : bounds.min.y * plane.y
            minD += (plane.z < 0) ? bounds.max.z * plane.z : bounds.min.z * plane.z
            
            maxD += (plane.x > 0) ? bounds.max.x * plane.x : bounds.min.x * plane.x
            maxD += (plane.y > 0) ? bounds.max.y * plane.y : bounds.min.y * plane.y
            maxD += (plane.z > 0) ? bounds.max.z * plane.z : bounds.min.z * plane.z
            
            if(minD < 0 && maxD < 0) {
                return false
            }
        }
        return true
    }
    
    public func contains(center:Vec3, radius:Float) -> Bool {
        contains(bounds: AABB(center - Vec3(1, 1, 1) * radius, center + Vec3(1, 1, 1) * radius))
    }
}
