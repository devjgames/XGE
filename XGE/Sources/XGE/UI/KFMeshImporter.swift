//
//  KFMeshImporter.swift
//  GameMaker
//
//  Created by Douglas McNamara on 6/13/26.
//

import AppKit
import simd
import XGE

@MainActor
fileprivate struct KFVertex {
    public var position = Vec3(0, 0, 0)
    public var textureCoordinate = Vec2(0, 0)
    public var normal = Vec3(0, 0, 0)
}

@MainActor
func importKFMesh(dir:URL) throws {
    do {
        let files = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        var objFiles:[URL] = []
        
        for file in files {
            var isDir:ObjCBool = false
            
            if FileManager.default.fileExists(atPath: dir.appendingPathComponent(file).path, isDirectory: &isDir) {
                if !isDir.boolValue {
                    if (file as NSString).pathExtension == "obj" {
                        objFiles.append(dir.appendingPathComponent(file))
                    }
                }
            }
        }
        
        if objFiles.isEmpty {
            throw NSError(domain: "mesh does not have any obj frames", code: 0)
        }
        
        objFiles.sort { a, b in
            return a.lastPathComponent < b.lastPathComponent
        }
        
        let data = NSMutableData()
        var count:Int32 = Int32(objFiles.count)
        var vertexCount:Int32 = -1
        
        data.append(&count, length: 4)
        
        for url in objFiles {
            do {
                let lines = try String(contentsOf: url, encoding: .ascii).components(separatedBy: .newlines)
                var vList:[Vec3] = []
                var tList:[Vec2] = []
                var nList:[Vec3] = []
                var vertices:[KFVertex] = []
                
                for line in lines {
                    let tLine = line.trimmingCharacters(in: .whitespaces)
                    let tokens = tLine.components(separatedBy: .whitespaces)
                    
                    if tLine.hasPrefix("v ") {
                        if tokens.count != 4 {
                            throw NSError(domain: "invalid v line", code: 0)
                        }
                        vList.append(Vec3((tokens[1] as NSString).floatValue, (tokens[2] as NSString).floatValue, (tokens[3] as NSString).floatValue))
                    } else if tLine.hasPrefix("vt ") {
                        if tokens.count != 3 {
                            throw NSError(domain: "invalid vt line", code: 0)
                        }
                        tList.append(Vec2((tokens[1] as NSString).floatValue, 1 - (tokens[2] as NSString).floatValue))
                    } else if tLine.hasPrefix("vn ") {
                        if tokens.count != 4 {
                            throw NSError(domain: "invalid vn line", code: 0)
                        }
                        nList.append(Vec3((tokens[1] as NSString).floatValue, (tokens[2] as NSString).floatValue, (tokens[3] as NSString).floatValue))
                    } else if tLine.hasPrefix("f ") {
                        var face:[KFVertex] = []
                        
                        if tokens.count < 4 {
                            throw NSError(domain: "invalid f line, edge count < 3", code: 0)
                        }
                        for i in (1..<tokens.count) {
                            let iTokens = tokens[i].components(separatedBy: CharacterSet(charactersIn: "/"))
                            
                            if iTokens.count != 3 {
                                throw NSError(domain: "invalid f line, edge component count != 3", code: 0)
                            }
                            
                            let vI = (iTokens[0] as NSString).integerValue - 1
                            let tI = (iTokens[1] as NSString).integerValue - 1
                            let nI = (iTokens[2] as NSString).integerValue - 1
                            
                            if vI >= 0 && vI < vList.count && tI >= 0 && tI < tList.count && nI >= 0 && nI < nList.count {
                                var vertex = KFVertex()
                                
                                vertex.position = vList[vI]
                                vertex.textureCoordinate = tList[tI]
                                vertex.normal = nList[nI]
                                
                                face.append(vertex)
                            } else {
                                throw NSError(domain: "invalid f line, edge component index out of bounds", code: 0)
                            }
                        }
                        
                        let tris = face.count - 2
                        
                        for i in (0..<tris) {
                            vertices.append(face[0])
                            vertices.append(face[i + 2])
                            vertices.append(face[i + 1])
                        }
                    }
                }
                if vertexCount < 0 {
                    if vertices.count == 0 {
                        throw NSError(domain: "invalid obj frame, has zero vertices", code: 0)
                    }
                    vertexCount = Int32(vertices.count)
                    
                    data.append(&vertexCount, length: 4)
                } else if vertexCount != vertices.count {
                    throw NSError(domain: "invalid obj frame, vertex count != \(vertexCount)", code: 0)
                }
                for vertex in vertices {
                    var v = vertex
                    
                    data.append(&v.position.x, length: 4)
                    data.append(&v.position.y, length: 4)
                    data.append(&v.position.z, length: 4)
                    data.append(&v.textureCoordinate.x, length: 4)
                    data.append(&v.textureCoordinate.y, length: 4)
                    data.append(&v.normal.x, length: 4)
                    data.append(&v.normal.y, length: 4)
                    data.append(&v.normal.z, length: 4)
                }
            } catch {
                throw NSError(domain: "failed to import kf mesh frame '\(url.lastPathComponent)'", code: 0)
            }
        }
        
        let url = AssetManager.rootURL!.appendingPathComponent((dir.lastPathComponent as NSString).appendingPathExtension("kfm")!)
        
        Log.instance.put("imported kfm, \(data.length), \(8 + Int32(count) * Int32(vertexCount) * 32)")
        
        try data.write(to: url)
    } catch {
        throw NSError(domain: error.localizedDescription, code: 0)
    }
}

@MainActor
func importKFMesh(populateItems: @escaping () -> Void) {
    let panel = NSOpenPanel()
    
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.canCreateDirectories = false
    panel.allowsMultipleSelection = false
    
    if panel.runModal() == .OK {
        for url in panel.urls {
            var isDir:ObjCBool = false
            
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
                if isDir.boolValue {
                    do {
                        try importKFMesh(dir: url)
                    } catch {
                        Log.instance.put(error.localizedDescription)
                    }
                }
            }
        }
        populateItems()
    }
}
