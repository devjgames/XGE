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
        if done {
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
        Log.instance.put("cloning key frame mesh ...")
        
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
            let lines = try String(contentsOf: url, encoding: .utf8).components(separatedBy: .newlines)
            var meshName:String?
            var texture:MTLTexture?
            
            for line in lines {
                let tLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if tLine.hasPrefix("mesh ") {
                    meshName = (tLine as NSString).substring(from: 4).trimmingCharacters(in: .whitespacesAndNewlines)
                } else if tLine.hasPrefix("texture ") {
                    let asset = (tLine as NSString).substring(from: 7).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    texture = try GameView.instance!.assets.load(path: asset) as? MTLTexture
                }
            }
            if meshName == nil {
                throw NSError(domain: "failed to find mesh line in kfm", code: 0)
            }
            
            if let data = NSMutableData(contentsOf: url.deletingLastPathComponent().appending(path: meshName!)) {
                var i:Int = 0
                
                
                var frames:[KFMeshFrame] = []
                var vertices:[Vertex] = []
                var header = MD2Header(data, &i)
                var triangles:[MD2Triangle] = []
                var texCoords:[MD2TexCoord] = []
                var frames2:[MD2Frame] = []
                
                i = header.offTris
                for _ in (0..<header.numTris) {
                    triangles.append(MD2Triangle(data, &i))
                }
                i = header.offST
                for _ in (0..<header.numST) {
                    texCoords.append(MD2TexCoord(header, data, &i))
                }
                for j in (0..<header.numFrames) {
                    i = header.offFrames + header.frameSize * j
                    frames2.append(MD2Frame(header, data, &i))
                }
                
                for f in frames2 {
                    var vertices:[Vertex] = []
                    
                    for j in (0..<header.numTris) {
                        let tri = triangles[j]
                        let p1 = f.verts[tri.vertex[0]]
                        let p2 = f.verts[tri.vertex[1]]
                        let p3 = f.verts[tri.vertex[2]]
                        let t1 = texCoords[tri.st[0]]
                        let t2 = texCoords[tri.st[1]]
                        let t3 = texCoords[tri.st[2]]
                        var v1 = Vertex()
                        var v2 = Vertex()
                        var v3 = Vertex()
                        
                        v1.position = p1.v
                        v1.textureCoordinate = t1.coord
                        v1.color = Vec4(1, 1, 1, 1)
                        v1.normal = MD2Normals[p1.n]
                        vertices.append(v1)
                        
                        v2.position = p2.v
                        v2.textureCoordinate = t2.coord
                        v2.color = Vec4(1, 1, 1, 1)
                        v2.normal = MD2Normals[p2.n]
                        vertices.append(v2)
                        
                        v3.position = p3.v
                        v3.textureCoordinate = t3.coord
                        v3.color = Vec4(1, 1, 1, 1)
                        v3.normal = MD2Normals[p3.n]
                        vertices.append(v3)
                    }
                    frames.append(KFMeshFrame(vertices: &vertices))
                }
                
                mesh = KFMesh(frames: &frames)
                mesh!.texture = texture
            } else {
                throw NSError(domain: "failed to load MD2 mesh", code: 0)
            }
        } catch {
            throw NSError(domain: error.localizedDescription, code: 0)
        }
        return mesh
    }
}

@MainActor
fileprivate func readFloat(_ data: NSMutableData, _ i: inout Int) -> Float {
    var f:Float = 0
    
    memmove(&f, data.mutableBytes + i, 4)
    i += 4
    
    return f
}

@MainActor
fileprivate func readInt32(_ data: NSMutableData, _ i: inout Int) -> Int {
    var x:Int32 = 0
    
    memmove(&x, data.mutableBytes + i, 4)
    i += 4
    
    return Int(x)
}

@MainActor
fileprivate func readInt16(_ data: NSMutableData, _ i: inout Int) -> Int {
    var x:Int16 = 0
    
    memmove(&x, data.mutableBytes + i, 2)
    i += 2
    
    return Int(x)
}

@MainActor
fileprivate func readInt8(_ data: NSMutableData, _ i: inout Int) -> Int {
    var x:UInt8 = 0
    
    memmove(&x, data.mutableBytes + i, 1)
    i += 1
    
    return Int(x)
}

@MainActor
fileprivate class MD2Header {
    public let ident:Int
    public let version:Int
    public let skinW:Int
    public let skinH:Int
    public let frameSize:Int
    public let numSkins:Int
    public let numVertices:Int
    public let numST:Int
    public let numTris:Int
    public let numGLcmds:Int
    public let numFrames:Int
    public let offSkins:Int
    public let offST:Int
    public let offTris:Int
    public let offFrames:Int
    public let offGLcmds:Int
    public let offEnd:Int
    
    public init(_ data: NSMutableData, _ i: inout Int) {
        ident = readInt32(data, &i)
        version = readInt32(data, &i)
        skinW = readInt32(data, &i)
        skinH = readInt32(data, &i)
        frameSize = readInt32(data, &i)
        numSkins = readInt32(data, &i)
        numVertices = readInt32(data, &i)
        numST = readInt32(data, &i)
        numTris = readInt32(data, &i)
        numGLcmds = readInt32(data, &i)
        numFrames = readInt32(data, &i)
        offSkins = readInt32(data, &i)
        offST = readInt32(data, &i)
        offTris = readInt32(data, &i)
        offFrames = readInt32(data, &i)
        offGLcmds = readInt32(data, &i)
        offEnd = readInt32(data, &i)
    }
}

@MainActor
fileprivate class MD2TexCoord {
    public let coord:Vec2
    
    public init(_ header: MD2Header, _ data: NSMutableData, _ i: inout Int) {
        let s = readInt16(data, &i)
        let t = readInt16(data, &i)
        let c = Vec2(Float(s), Float(t)) / Vec2(Float(header.skinW), Float(header.skinH))
        
        coord = c
    }
}

@MainActor
fileprivate class MD2Triangle {
    public let vertex:[Int]
    public let st:[Int]
    
    public init(_ data: NSMutableData, _ i: inout Int) {
        let v1 = readInt16(data, &i)
        let v2 = readInt16(data, &i)
        let v3 = readInt16(data, &i)
        let t1 = readInt16(data, &i)
        let t2 = readInt16(data, &i)
        let t3 = readInt16(data, &i)
        
        vertex = [ v1, v2, v3 ]
        st = [ t1, t2, t3 ]
    }
}

@MainActor
fileprivate class MD2Vertex {
    public var v:Vec3
    public let n:Int
    
    public init(_ data: NSMutableData, _ i: inout Int) {
        let x = readInt8(data, &i)
        let y = readInt8(data, &i)
        let z = readInt8(data, &i)
        
        v = Vec3(Float(x), Float(y), Float(z))
        n = readInt8(data, &i)
    }
}

@MainActor
fileprivate class MD2Frame {
    public let scale:Vec3
    public let translate:Vec3
    public var verts:[MD2Vertex] = []
    
    public init(_ header: MD2Header, _ data: NSMutableData, _ i: inout Int) {
        let sx = readFloat(data, &i)
        let sy = readFloat(data, &i)
        let sz = readFloat(data, &i)
        let tx = readFloat(data, &i)
        let ty = readFloat(data, &i)
        let tz = readFloat(data, &i)
        
        scale = Vec3(sx, sy, sz)
        translate = Vec3(tx, ty, tz)
        
        i += 16
        for _ in (0..<header.numVertices) {
            var v = MD2Vertex(data, &i)
            
            v.v = v.v * scale + translate
            verts.append(v)
        }
    }
}

@MainActor
fileprivate let MD2Normals:[Vec3] = [
    Vec3(-0.525731, 0.000000, 0.850651),
    Vec3(-0.442863, 0.238856, 0.864188),
    Vec3(-0.295242, 0.000000, 0.955423),
    Vec3(-0.309017, 0.500000, 0.809017),
    Vec3(-0.162460, 0.262866, 0.951056),
    Vec3(0.000000, 0.000000, 1.000000),
    Vec3(0.000000, 0.850651, 0.525731),
    Vec3(-0.147621, 0.716567, 0.681718),
    Vec3(0.147621, 0.716567, 0.681718),
    Vec3(0.000000, 0.525731, 0.850651),
    Vec3(0.309017, 0.500000, 0.809017),
    Vec3(0.525731, 0.000000, 0.850651),
    Vec3(0.295242, 0.000000, 0.955423),
    Vec3(0.442863, 0.238856, 0.864188),
    Vec3(0.162460, 0.262866, 0.951056),
    Vec3(-0.681718, 0.147621, 0.716567),
    Vec3(-0.809017, 0.309017, 0.500000),
    Vec3(-0.587785, 0.425325, 0.688191),
    Vec3(-0.850651, 0.525731, 0.000000),
    Vec3(-0.864188, 0.442863, 0.238856),
    Vec3(-0.716567, 0.681718, 0.147621),
    Vec3(-0.688191, 0.587785, 0.425325),
    Vec3(-0.500000, 0.809017, 0.309017),
    Vec3(-0.238856, 0.864188, 0.442863),
    Vec3(-0.425325, 0.688191, 0.587785),
    Vec3(-0.716567, 0.681718, -0.147621),
    Vec3(-0.500000, 0.809017, -0.309017),
    Vec3(-0.525731, 0.850651, 0.000000),
    Vec3(0.000000, 0.850651, -0.525731),
    Vec3(-0.238856, 0.864188, -0.442863),
    Vec3(0.000000, 0.955423, -0.295242),
    Vec3(-0.262866, 0.951056, -0.162460),
    Vec3(0.000000, 1.000000, 0.000000),
    Vec3(0.000000, 0.955423, 0.295242),
    Vec3(-0.262866, 0.951056, 0.162460),
    Vec3(0.238856, 0.864188, 0.442863),
    Vec3(0.262866, 0.951056, 0.162460),
    Vec3(0.500000, 0.809017, 0.309017),
    Vec3(0.238856, 0.864188, -0.442863),
    Vec3(0.262866, 0.951056, -0.162460),
    Vec3(0.500000, 0.809017, -0.309017),
    Vec3(0.850651, 0.525731, 0.000000),
    Vec3(0.716567, 0.681718, 0.147621),
    Vec3(0.716567, 0.681718, -0.147621),
    Vec3(0.525731, 0.850651, 0.000000),
    Vec3(0.425325, 0.688191, 0.587785),
    Vec3(0.864188, 0.442863, 0.238856),
    Vec3(0.688191, 0.587785, 0.425325),
    Vec3(0.809017, 0.309017, 0.500000),
    Vec3(0.681718, 0.147621, 0.716567),
    Vec3(0.587785, 0.425325, 0.688191),
    Vec3(0.955423, 0.295242, 0.000000),
    Vec3(1.000000, 0.000000, 0.000000),
    Vec3(0.951056, 0.162460, 0.262866),
    Vec3(0.850651, -0.525731, 0.000000),
    Vec3(0.955423, -0.295242, 0.000000),
    Vec3(0.864188, -0.442863, 0.238856),
    Vec3(0.951056, -0.162460, 0.262866),
    Vec3(0.809017, -0.309017, 0.500000),
    Vec3(0.681718, -0.147621, 0.716567),
    Vec3(0.850651, 0.000000, 0.525731),
    Vec3(0.864188, 0.442863, -0.238856),
    Vec3(0.809017, 0.309017, -0.500000),
    Vec3(0.951056, 0.162460, -0.262866),
    Vec3(0.525731, 0.000000, -0.850651),
    Vec3(0.681718, 0.147621, -0.716567),
    Vec3(0.681718, -0.147621, -0.716567),
    Vec3(0.850651, 0.000000, -0.525731),
    Vec3(0.809017, -0.309017, -0.500000),
    Vec3(0.864188, -0.442863, -0.238856),
    Vec3(0.951056, -0.162460, -0.262866),
    Vec3(0.147621, 0.716567, -0.681718),
    Vec3(0.309017, 0.500000, -0.809017),
    Vec3(0.425325, 0.688191, -0.587785),
    Vec3(0.442863, 0.238856, -0.864188),
    Vec3(0.587785, 0.425325, -0.688191),
    Vec3(0.688191, 0.587785, -0.425325),
    Vec3(-0.147621, 0.716567, -0.681718),
    Vec3(-0.309017, 0.500000, -0.809017),
    Vec3(0.000000, 0.525731, -0.850651),
    Vec3(-0.525731, 0.000000, -0.850651),
    Vec3(-0.442863, 0.238856, -0.864188),
    Vec3(-0.295242, 0.000000, -0.955423),
    Vec3(-0.162460, 0.262866, -0.951056),
    Vec3(0.000000, 0.000000, -1.000000),
    Vec3(0.295242, 0.000000, -0.955423),
    Vec3(0.162460, 0.262866, -0.951056),
    Vec3(-0.442863, -0.238856, -0.864188),
    Vec3(-0.309017, -0.500000, -0.809017),
    Vec3(-0.162460, -0.262866, -0.951056),
    Vec3(0.000000, -0.850651, -0.525731),
    Vec3(-0.147621, -0.716567, -0.681718),
    Vec3(0.147621, -0.716567, -0.681718),
    Vec3(0.000000, -0.525731, -0.850651),
    Vec3(0.309017, -0.500000, -0.809017),
    Vec3(0.442863, -0.238856, -0.864188),
    Vec3(0.162460, -0.262866, -0.951056),
    Vec3(0.238856, -0.864188, -0.442863),
    Vec3(0.500000, -0.809017, -0.309017),
    Vec3(0.425325, -0.688191, -0.587785),
    Vec3(0.716567, -0.681718, -0.147621),
    Vec3(0.688191, -0.587785, -0.425325),
    Vec3(0.587785, -0.425325, -0.688191),
    Vec3(0.000000, -0.955423, -0.295242),
    Vec3(0.000000, -1.000000, 0.000000),
    Vec3(0.262866, -0.951056, -0.162460),
    Vec3(0.000000, -0.850651, 0.525731),
    Vec3(0.000000, -0.955423, 0.295242),
    Vec3(0.238856, -0.864188, 0.442863),
    Vec3(0.262866, -0.951056, 0.162460),
    Vec3(0.500000, -0.809017, 0.309017),
    Vec3(0.716567, -0.681718, 0.147621),
    Vec3(0.525731, -0.850651, 0.000000),
    Vec3(-0.238856, -0.864188, -0.442863),
    Vec3(-0.500000, -0.809017, -0.309017),
    Vec3(-0.262866, -0.951056, -0.162460),
    Vec3(-0.850651, -0.525731, 0.000000),
    Vec3(-0.716567, -0.681718, -0.147621),
    Vec3(-0.716567, -0.681718, 0.147621),
    Vec3(-0.525731, -0.850651, 0.000000),
    Vec3(-0.500000, -0.809017, 0.309017),
    Vec3(-0.238856, -0.864188, 0.442863),
    Vec3(-0.262866, -0.951056, 0.162460),
    Vec3(-0.864188, -0.442863, 0.238856),
    Vec3(-0.809017, -0.309017, 0.500000),
    Vec3(-0.688191, -0.587785, 0.425325),
    Vec3(-0.681718, -0.147621, 0.716567),
    Vec3(-0.442863, -0.238856, 0.864188),
    Vec3(-0.587785, -0.425325, 0.688191),
    Vec3(-0.309017, -0.500000, 0.809017),
    Vec3(-0.147621, -0.716567, 0.681718),
    Vec3(-0.425325, -0.688191, 0.587785),
    Vec3(-0.162460, -0.262866, 0.951056),
    Vec3(0.442863, -0.238856, 0.864188),
    Vec3(0.162460, -0.262866, 0.951056),
    Vec3(0.309017, -0.500000, 0.809017),
    Vec3(0.147621, -0.716567, 0.681718),
    Vec3(0.000000, -0.525731, 0.850651),
    Vec3(0.425325, -0.688191, 0.587785),
    Vec3(0.587785, -0.425325, 0.688191),
    Vec3(0.688191, -0.587785, 0.425325),
    Vec3(-0.955423, 0.295242, 0.000000),
    Vec3(-0.951056, 0.162460, 0.262866),
    Vec3(-1.000000, 0.000000, 0.000000),
    Vec3(-0.850651, 0.000000, 0.525731),
    Vec3(-0.955423, -0.295242, 0.000000),
    Vec3(-0.951056, -0.162460, 0.262866),
    Vec3(-0.864188, 0.442863, -0.238856),
    Vec3(-0.951056, 0.162460, -0.262866),
    Vec3(-0.809017, 0.309017, -0.500000),
    Vec3(-0.864188, -0.442863, -0.238856),
    Vec3(-0.951056, -0.162460, -0.262866),
    Vec3(-0.809017, -0.309017, -0.500000),
    Vec3(-0.681718, 0.147621, -0.716567),
    Vec3(-0.681718, -0.147621, -0.716567),
    Vec3(-0.850651, 0.000000, -0.525731),
    Vec3(-0.688191, 0.587785, -0.425325),
    Vec3(-0.587785, 0.425325, -0.688191),
    Vec3(-0.425325, 0.688191, -0.587785),
    Vec3(-0.425325, -0.688191, -0.587785),
    Vec3(-0.587785, -0.425325, -0.688191),
    Vec3(-0.688191, -0.587785, -0.425325)
]
