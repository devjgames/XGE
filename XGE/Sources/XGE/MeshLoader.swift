//
//  MeshLoader.swift
//  XGE
//
//  Created by Douglas McNamara on 1/23/26.
//

import Foundation
import simd
import Metal

@MainActor
public class MeshLoader : AssetLoader {
    
    public func load(url: URL) throws -> AnyObject? {
        if !FileManager.default.fileExists(atPath: url.path()) {
            throw NSError(domain: "obj file not found", code: 0)
        }
        let lines = try String(contentsOf: url, encoding: .ascii).components(separatedBy: .newlines)
        let directory = url.deletingLastPathComponent()
        var vlist : [Vec3] = []
        var tlist : [Vec2] = []
        var nlist : [Vec3] = []
        var textures : [String:MTLTexture] = [:]
        var texturePaths : [String:String] = [:]
        let mesh : Mesh = Mesh()
        
        for line in lines {
            let tline = line.trimmingCharacters(in: .whitespaces)
            let tokens = tline.components(separatedBy: .whitespaces)
            
            if tline.hasPrefix("mtllib ") {
                let mtlURL = directory.appendingPathComponent((tline as NSString).substring(from: 6).trimmingCharacters(in: .whitespaces))
                
                if !FileManager.default.fileExists(atPath: mtlURL.path()) {
                    throw NSError(domain: "mtl file not found", code: 0)
                }
                let mlines = try String(contentsOf: mtlURL, encoding: .ascii).components(separatedBy: .newlines)
                var name = ""
                
                for mline in mlines {
                    let mtline = mline.trimmingCharacters(in: .whitespaces)
                    
                    if mtline.hasPrefix("newmtl ") {
                        name = (mtline as NSString).substring(from: 6).trimmingCharacters(in: .whitespaces)
                    } else if mtline.hasPrefix("map_Kd ") {
                        let tfile = (mtline as NSString).substring(from: 6).trimmingCharacters(in: .whitespaces)
                        
                        do {
                            if let texture = try GameView.instance!.assets.load(path: tfile) as? MTLTexture {
                                textures[name] = texture
                                texturePaths[name] = tfile
                            } else {
                                throw NSError(domain: "not a texture file", code: 0)
                            }
                        } catch {
                            throw NSError(domain: "could not load '\(tfile)'", code: 0)
                        }
                    }
                }
            } else if tline.hasPrefix("usemtl ") {
                let name = (tline as NSString).substring(from: 6).trimmingCharacters(in: .whitespaces)
                let part = MeshPart()
                
                part.name = name
                
                if let texture = textures[name] {
                    part.texture = texture
                    part.name = texturePaths[name]!
                }
                mesh.parts.append(part)
            } else if tline.hasPrefix("v ") {
                if tokens.count == 4 {
                    vlist.append(Vec3((tokens[1] as NSString).floatValue, (tokens[2] as NSString).floatValue, (tokens[3] as NSString).floatValue))
                } else {
                    throw NSError(domain: "v line invalid", code: 0)
                }
            } else if tline.hasPrefix("vt ") {
                if tokens.count == 3 {
                    tlist.append(Vec2((tokens[1] as NSString).floatValue, 1 - (tokens[2] as NSString).floatValue))
                } else {
                    throw NSError(domain: "vt line invalid", code: 0)
                }
            } else if tline.hasPrefix("vn ") {
                if tokens.count == 4 {
                    nlist.append(Vec3((tokens[1] as NSString).floatValue, (tokens[2] as NSString).floatValue, (tokens[3] as NSString).floatValue))
                } else {
                    throw NSError(domain: "vn line invalid", code: 0)
                }
            } else if tline.hasPrefix("f ") {
                if mesh.parts.isEmpty {
                    mesh.parts.append(MeshPart())
                }
                
                if tokens.count < 4 {
                    throw NSError(domain: "f line invalid, edges < 3", code: 0)
                }
                
                let part = mesh.parts.last!
                let count = part.vertices.count
                let tris = tokens.count - 3
                var indices : [Int32] = []
                
                for i in (1..<tokens.count) {
                    let itokens = tokens[i].components(separatedBy: "/")
                    
                    if itokens.count != 3 {
                        throw NSError(domain: "f line invalid, edge component count != 3", code: 0)
                    }
                    
                    let vI = (itokens[0] as NSString).integerValue - 1
                    let tI = (itokens[1] as NSString).integerValue - 1
                    let nI = (itokens[2] as NSString).integerValue - 1
                    
                    if (vI >= 0 && vI < vlist.count) && (tI >= 0 && tI < tlist.count) && (nI >= 0 && nI < nlist.count) {
                        var v = Vertex()
                        
                        v.position = vlist[vI]
                        v.textureCoordinate = tlist[tI]
                        v.normal = nlist[nI]
                        
                        part.vertices.append(v)
                        
                        indices.append(Int32(count + i - 1))
                    } else {
                        throw NSError(domain: "f line invalid, index out of bounds", code: 0)
                    }
                }
                for i in (0..<tris) {
                    part.indices.append(indices[0])
                    part.indices.append(indices[i + 2])
                    part.indices.append(indices[i + 1])
                }
            }
        }
        
        for i in (0..<GameView.instance!.scene.root.childCount) {
            let node = GameView.instance!.scene.root[i]
            
            if let mesh = node.encodable as? Mesh {
                mesh.calcBounds(calcPartBounds: true)
            }
        }
        
        mesh.calcBounds(calcPartBounds: true)
        mesh.createBuffers()
        
        return mesh
    }
}
