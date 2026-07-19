//
//  Buffers.swift
//  XGE
//
//  Created by Douglas McNamara on 9/11/25.
//

import Foundation
import Metal
import simd

public let MaxLights = 8

public struct Vertex {
    public var position = Vec3(0, 0, 0)
    public var textureCoordinate = Vec2(0, 0)
    public var normal = Vec3(0, 0, 0)
    public var color = Vec4(1, 1, 1, 1)
}

public struct VertexData {
    public var projection = Mat4.identity()
    public var view = Mat4.identity()
    public var model = Mat4.identity()
    public var modelIT = Mat4.identity()
    public var warpEnabled:Int32 = 0
    public var warpAmplitude:Float = 0
    public var warpFrequency:Float = 0
    public var warpTime:Float = 0
    public var warpY:Int32 = 0
}

public struct FragmentData {
    public var eye = Vec3(0, 0, 0)
    public var ambientColor = Vec4(0, 0, 0, 0)
    public var diffuseColor = Vec4(0, 0, 0, 0)
    public var specularColor = Vec4(0, 0, 0, 1)
    public var specularPower:Float = 32
    public var textureEnabled:Int32 = 0
    public var decalEnabled:Int32 = 0
    public var lightingEnabled:Int32 = 0
    public var lightCount:Int32 = 0
}

public struct Light {
    public var position = Vec3(0, 0, 0)
    public var color = Vec4(1, 1, 1, 1)
    public var radius:Float = 100
}
