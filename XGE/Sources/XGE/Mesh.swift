//
//  Mesh.swift
//  XGE
//
//  Created by Douglas McNamara on 9/17/25.
//

import Foundation
import Metal
import MetalKit
import simd

@MainActor
public class MeshPart {
    
    public var name:String = ""
    public var texture:MTLTexture?
    public var decal:MTLTexture?
    public var vertices:[Vertex] = []
    public var indices:[Int32] = []
    public var vertexBuffer:MTLBuffer?
    public var indexBuffer:MTLBuffer?
    public var bounds:AABB = AABB()
    
    public init() {
    }
    
    public init(part: MeshPart) {
        name = part.name
        texture = part.texture
        decal =  part.decal
        vertices = part.vertices
        indices = part.indices
        bounds = part.bounds
        
        vertexBuffer = part.vertexBuffer
        indexBuffer = part.indexBuffer
    }
    
    public var triangleCount: Int {
        get { indices.count / 3 }
    }
    
    public func triangleAt(node: Node, i: Int) -> Triangle {
        let j = i * 3
        
        return Triangle(
            vertices[Int(indices[j + 0])].position,
            vertices[Int(indices[j + 1])].position,
            vertices[Int(indices[j + 2])].position
        )
    }
    
    public func update(node: Node) {
    }
    
    public func encode(encoder: any MTLRenderCommandEncoder, node: Node, lights: inout [Light]) -> Int {
        if let vertexBuffer = vertexBuffer, let indexBuffer = indexBuffer {
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
            vertexData.warpY = (node.warpY) ? 1 : 0
            
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
            encoder.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0)
            
            return indices.count / 3
        }
        return 0
    }
    
    public func calcBounds() {
        bounds.clear()
        
        for vertex in vertices {
            bounds.add(vertex.position)
        }
    }
    
    public func createBuffers() {
        vertexBuffer = nil
        indexBuffer = nil
        
        if !vertices.isEmpty && !indices.isEmpty && indices.count / 3 * 3 == indices.count {
            var valid = true
            
            for i in indices {
                if i < 0 || i >= vertices.count {
                    valid = false
                    break
                }
            }
            if valid {
                Log.instance.put("creating mesh vertex and index buffers ...")
                
                vertexBuffer = GameView.instance!.device!.makeBuffer(bytes: &vertices,
                                                                     length: MemoryLayout<Vertex>.stride * vertices.count,
                                                                     options: .storageModeManaged)
                indexBuffer = GameView.instance!.device!.makeBuffer(bytes: &indices,
                                                                    length: MemoryLayout<Int32>.stride * indices.count,
                                                                    options: .storageModeManaged)
            } else {
                indices.removeAll()
                vertices.removeAll()
            }
        } else {
            indices.removeAll()
            vertices.removeAll()
        }
    }
}

@MainActor
public class Mesh : Encodable {
    
    public var parts:[MeshPart] = []
    public var bounds:AABB = AABB()
    
    public var triangleCount: Int {
        get {
            var count = 0
            
            for part in parts {
                count += part.triangleCount
            }
            return count
        }
    }
    
    public func triangleAt(node: Node, i: Int) -> Triangle {
        var j = 0
        var triangle:Triangle = Triangle()
        
        for part in parts {
            if i < j + part.triangleCount {
                triangle = part.triangleAt(node: node, i: i - j)
                break
            }
            j += part.triangleCount
        }
        return triangle
    }
    
    public func update(node: Node) {
    }
    
    public func encode(encoder: any MTLRenderCommandEncoder, node: Node, lights: inout [Light]) -> Int {
        var triangles = 0
        
        for part in parts {
            triangles += part.encode(encoder: encoder, node: node, lights: &lights)
        }
        return triangles
    }
    
    public func calcBounds(calcPartBounds: Bool) {
        bounds.clear()
        for part in parts {
            if calcPartBounds {
                part.calcBounds()
            }
            bounds.add(part.bounds)
        }
    }
    
    public func createBuffers() {
        for part in parts {
            part.createBuffers()
        }
    }
    
    public func newInstance() -> any Encodable {
        let mesh = Mesh()

        for part in parts {
            mesh.parts.append(MeshPart(part: part))
        }
        mesh.bounds = bounds
        
        return mesh
    }
}
