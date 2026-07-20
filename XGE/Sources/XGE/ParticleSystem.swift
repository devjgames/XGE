//
//  ParticleSystem.swift
//  XGE
//
//  Created by Douglas McNamara on 1/12/26.
//

import Foundation
import simd
import Metal
import MetalKit

public struct Particle {
    public var velocity = Vec3()
    public var startPosition = Vec3()
    public var position = Vec3()
    public var startSize = Vec2()
    public var endSize = Vec2()
    public var size = Vec2()
    public var startColor = Vec4()
    public var endColor = Vec4()
    public var color = Vec4()
    public var lifeSpan:Float = 0
    public var time:Float = 0
    
    public init() {
    }
}

@MainActor
public class ParticleSystem : Encodable {
    
    public var emitPosition = Vec3()
    public var texture:MTLTexture?
    
    private var _maxParticles:Int
    private var _live:[Particle] = []
    private var _temp:[Particle] = []
    private var _vertexBuffer:MTLBuffer?
    private var _bounds = AABB()
    private var _triangles:[Triangle] = []
    private var _vertices:[Vertex] = []
    
    public init(maxParticles:Int) {
        _maxParticles = maxParticles
        _vertexBuffer = GameView.instance!.device!.makeBuffer(length: MemoryLayout<Vertex>.stride * 6 * maxParticles, options: .storageModeManaged)
    }
    
    public init(particles:ParticleSystem) {
        _maxParticles = particles._maxParticles
        _vertexBuffer = GameView.instance!.device!.makeBuffer(length: MemoryLayout<Vertex>.stride * 6 * _maxParticles, options: .storageModeManaged)
    }
    
    public var bounds: AABB {
        get { _bounds }
    }
    
    public var triangleCount: Int {
        get { _triangles.count }
    }
    
    public func triangleAt(node: Node, i: Int) -> Triangle {
        _triangles[i]
    }
    
    public func emit(particle:Particle) {
        if _live.count < _maxParticles {
            var p = particle
            
            p.startPosition += emitPosition
            p.time = GameView.instance!.totalTime
            
            _live.append(p)
        }
    }
    
    public func update(node: Node) {
        let scene = GameView.instance!.scene
        let m = simd_inverse(scene.view * node.model)
        let rc = m.columns.0
        let uc = m.columns.1
        let fc = m.columns.2
        let r = simd_normalize(Vec3(rc.x, rc.y, rc.z))
        let u = simd_normalize(Vec3(uc.x, uc.y, uc.z))
        let f = simd_normalize(Vec3(fc.x, fc.y, fc.z))
        
        _temp.removeAll(keepingCapacity: true)
        for i in (0..<_live.count) {
            var p = _live[i]
            let t = GameView.instance!.totalTime - p.time
            
            if t < p.lifeSpan {
                let a = t / p.lifeSpan
                
                p.position = p.startPosition + p.velocity * t
                p.size = p.startSize + a * (p.endSize - p.startSize)
                p.color = p.startColor + a * (p.endColor - p.startColor)
                
                _temp.append(p)
            }
        }
        _live = _temp
        
        _triangles.removeAll(keepingCapacity: true)
        _vertices.removeAll(keepingCapacity: true)
        
        _bounds.clear()
        
        for i in (0..<_live.count) {
            let p = _live[i]
            var v = Vertex()
            let p1 = p.position - r * p.size.x * 0.5 - u * p.size.y * 0.5
            let p2 = p.position - r * p.size.x * 0.5 + u * p.size.y * 0.5
            let p3 = p.position + r * p.size.x * 0.5 + u * p.size.y * 0.5
            let p4 = p.position + r * p.size.x * 0.5 - u * p.size.y * 0.5
            
            _bounds.add(p1)
            _bounds.add(p2)
            _bounds.add(p3)
            _bounds.add(p4)

            _triangles.append(Triangle(p1, p2, p3))
            _triangles.append(Triangle(p1, p3, p4))
            
            v.position = p1
            v.textureCoordinate = Vec2()
            v.normal = f
            v.color = p.color
            _vertices.append(v)
        
            v.position = p2
            v.textureCoordinate = Vec2(1, 0)
            v.normal = f
            v.color = p.color
            _vertices.append(v)
            
            v.position = p3
            v.textureCoordinate = Vec2(1, 1)
            v.normal = f
            v.color = p.color
            _vertices.append(v)
            
            v.position = p3
            v.textureCoordinate = Vec2(1, 1)
            v.normal = f
            v.color = p.color
            _vertices.append(v)
            
            v.position = p4
            v.textureCoordinate = Vec2(0, 1)
            v.normal = f
            v.color = p.color
            _vertices.append(v)
            
            v.position = p1
            v.textureCoordinate = Vec2()
            v.normal = f
            v.color = p.color
            _vertices.append(v)
        }
        
        memmove(_vertexBuffer!.contents(), _vertices, MemoryLayout<Vertex>.stride * _vertices.count)
        _vertexBuffer!.didModifyRange((0..<MemoryLayout<Vertex>.stride * _vertices.count))
        
        let commandBuffer = GameView.instance!.commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeBlitCommandEncoder()!
        
        encoder.synchronize(resource: _vertexBuffer!)
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    public func encode(encoder: any MTLRenderCommandEncoder, node: Node, lights: inout [Light]) -> Int {
        if let vertexBuffer = _vertexBuffer {
            var vertexData = VertexData()
            var fragmentData = FragmentData()
            
            vertexData.projection = GameView.instance!.scene.projection
            vertexData.view = GameView.instance!.scene.view
            vertexData.model = node.model
            vertexData.modelIT = node.modelIT
            vertexData.warpEnabled = (node.warpEnabled) ? 1 : 0
            vertexData.warpAmplitude = node.warpAmplitude
            vertexData.warpFrequency = node.warpFrequency
            vertexData.warpTime = node.warpTime
            vertexData.warpY = (node.warpY) ? 1 : 0;
            
            fragmentData.textureEnabled = (texture == nil) ? 0 : 1
            fragmentData.decalEnabled = 0
            fragmentData.ambientColor = node.ambientColor
            fragmentData.diffuseColor = node.diffuseColor
            fragmentData.lightCount = Int32(lights.count)
            fragmentData.lightingEnabled = (node.receivesLight) ? 1 : 0
            fragmentData.eye = GameView.instance!.scene.eye
            fragmentData.specularPower = node.specularPower
            fragmentData.specularColor = node.specularColor
            
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&vertexData, length: MemoryLayout<VertexData>.stride, index: 1)
            
            encoder.setFragmentBytes(&fragmentData, length: MemoryLayout<FragmentData>.stride, index: 0)
            encoder.setFragmentBytes(&lights, length: MemoryLayout<Light>.stride * lights.count, index: 1)
            
            if let texture = texture {
                encoder.setFragmentTexture(texture, index: 0)
            }
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: _vertices.count)
            
            return _vertices.count / 3
        }
        return 0
    }
    
    public func newInstance() -> any Encodable {
        ParticleSystem(particles: self)
    }
}
