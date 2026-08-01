//
//  KFMesh.swift
//  XGE
//
//  Created by Douglas McNamara on 11/5/25.
//

import Foundation
import simd
import Metal
import MetalKit

@MainActor
public class KFMeshFrame {
    
    public let bounds:AABB
    public let vertices:[Vertex]
    
    public init(vertices: inout [Vertex]) {
        var b = AABB()
        
        for vertex in vertices {
            b.add(vertex.position)
        }
        bounds = b
        self.vertices = vertices
    }
}

@MainActor
public class KFMesh : Encodable {
    
    public var bounds = AABB()
    public var frames:[KFMeshFrame]
    public var texture:MTLTexture?
    public var decal:MTLTexture?
    public var vertexBuffer:MTLBuffer?
    public var paused = false
    
    private var start:Int = 0
    private var end:Int = 0
    private var speed:Int = 0
    private var amount:Float = 0
    private var frame:Int = 0
    private var looping:Bool = false
    private var done:Bool = true
    private var vertices:[Vertex] = []
    
    public init(frames: inout[KFMeshFrame]) {
        self.frames = frames
        self.vertexBuffer = GameView.instance!.device!.makeBuffer(length: frames[0].vertices.count * MemoryLayout<Vertex>.stride, options: .storageModeManaged)
        
        reset()
    }
    
    public var isDone: Bool {
        get { done }
    }
    
    public var triangleCount: Int {
        get {
            return frames[0].vertices.count / 3
        }
    }
    
    public func triangleAt(node: Node, i: Int) -> Triangle {
        let j = i * 3
        let f1 = frames[frame]
        var f2 = frames[frame]
        
        if frame == end {
            f2 = frames[start]
        } else {
            f2 = frames[frame + 1]
        }
        
        return Triangle(
            f1.vertices[j + 0].position + amount * (f2.vertices[j + 0].position - f1.vertices[j + 0].position),
            f1.vertices[j + 1].position + amount * (f2.vertices[j + 1].position - f1.vertices[j + 1].position),
            f1.vertices[j + 2].position + amount * (f2.vertices[j + 2].position - f1.vertices[j + 2].position)
        )
    }
    
    public func reset() {
        frame = start
        amount = 0
        done = start == end
        bounds = frames[frame].bounds
        buffer()
    }
    
    public func setSequence(_ start: Int, _ end: Int, _ speed: Int, _ looping: Bool) {
        if start >= 0 && start < frames.count && end >= 0 && end < frames.count && start <= end && speed >= 0 {
            if start != self.start || end != self.end || speed != self.speed || looping != self.looping {
                self.start = start
                self.end = end
                self.speed = speed
                self.looping = looping
                reset()
            }
        }
    }
    
    public func update(node: Node) {
        if done || paused {
            return
        }
        
        amount += Float(speed) * GameView.instance!.elapsedTime
        if amount >= 1 {
            if looping {
                if frame == end {
                    frame = start
                } else {
                    frame = frame + 1
                }
                amount = 0
            } else if frame == end - 1 {
                amount = 1
                done = true
            } else {
                frame = frame + 1
                amount = 0
            }
        }
        
        let f1 = frames[frame]
        var f2 = frames[frame]
        
        if frame == end {
            f2 = frames[start]
        } else {
            f2 = frames[frame + 1]
        }
        
        bounds.min = f1.bounds.min + amount * (f2.bounds.min - f1.bounds.min)
        bounds.max = f1.bounds.max + amount * (f2.bounds.max - f1.bounds.max)
        
        buffer()
    }
    
    private func buffer() {
        let f1 = frames[frame]
        var f2 = frames[frame]
        
        if frame == end {
            f2 = frames[start]
        } else {
            f2 = frames[frame + 1]
        }
        
        vertices.removeAll(keepingCapacity: true)
        
        for i in (0..<f1.vertices.count) {
            let v1 = f1.vertices[i]
            let v2 = f2.vertices[i]
            var v = Vertex()
            
            v.position = v1.position + amount * (v2.position - v1.position)
            v.textureCoordinate = v1.textureCoordinate
            v.normal = v1.normal + amount * (v2.normal - v1.normal)
            
            vertices.append(v)
        }
        
        memmove(vertexBuffer!.contents(), vertices, MemoryLayout<Vertex>.stride * vertices.count)
        vertexBuffer!.didModifyRange((0..<MemoryLayout<Vertex>.stride * vertices.count))
        
        let commandBuffer = GameView.instance!.commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeBlitCommandEncoder()!
        
        encoder.synchronize(resource: vertexBuffer!)
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    public func encode(encoder: any MTLRenderCommandEncoder, node: Node, lights: inout [Light]) -> Int {
        if let vertexBuffer = vertexBuffer {
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
            fragmentData.decalEnabled = (decal == nil) ? 0 : 1
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
            if let decal = decal {
                encoder.setFragmentTexture(decal, index: 1)
            }
            
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: frames[0].vertices.count)
            
            return frames[0].vertices.count / 3
        }
        return 0
    }
    
    public func newInstance() -> any Encodable {
        let mesh = KFMesh(frames: &frames)
        
        mesh.texture = texture
        mesh.decal = decal
        
        return mesh
    }
}

@MainActor
public class KFMeshLoader : AssetLoader {
    
    public func load(url: URL) throws -> AnyObject? {
        var mesh:KFMesh?
        
        do {
            let data = NSMutableData(contentsOf: url)
            
            if data == nil {
                throw NSError(domain: "failed to load kf mesh data", code: 0)
            }
            
            let length = data!.count
            var frameCount:Int32 = 0
            var vertexCount:Int32 = 0
            var i = 8
            
            if length < 8 {
                throw NSError(domain: "invalid kf mesh header", code: 0)
            }
            memmove(&frameCount, data!.mutableBytes, 4)
            memmove(&vertexCount, data!.mutableBytes + 4, 4)
            
            if frameCount <= 0 {
                throw NSError(domain: "invalid kf mesh header, frame count <= 0", code: 0)
            } else if vertexCount <= 0 {
                throw NSError(domain: "invalid kf mesh header, vertex count <= 0", code:0)
            } else if vertexCount / 3 * 3 != vertexCount {
                throw NSError(domain: "invalid kf mesh header, vertex count not evenly divisible by 3", code: 0)
            } else if length != 8 + Int(vertexCount) * 32 * Int(frameCount) {
                throw NSError(domain: "invalid kf mesh file length", code: 0)
            }
            
            var frames:[KFMeshFrame] = []
            var vertices:[Vertex] = []
            
            for _ in (0..<Int(frameCount)) {
                vertices.removeAll(keepingCapacity: true)
                
                for _ in (0..<Int(vertexCount)) {
                    var v = Vertex()
                    
                    v.position.x = readFloat(data!, &i)
                    v.position.y = readFloat(data!, &i)
                    v.position.z = readFloat(data!, &i)
                    v.textureCoordinate.x = readFloat(data!, &i)
                    v.textureCoordinate.y = readFloat(data!, &i)
                    v.normal.x = readFloat(data!, &i)
                    v.normal.y = readFloat(data!, &i)
                    v.normal.z = readFloat(data!, &i)
                    
                    vertices.append(v)
                }
                frames.append(KFMeshFrame(vertices: &vertices))
            }
            mesh = KFMesh(frames: &frames)
        } catch {
            throw NSError(domain: error.localizedDescription, code: 0)
        }
        return mesh
    }
    
    private func readFloat(_ data: NSMutableData, _ i: inout Int) -> Float {
        var f:Float = 0
        
        memmove(&f, data.mutableBytes + i, 4)
        i += 4
        
        return f
    }
}
