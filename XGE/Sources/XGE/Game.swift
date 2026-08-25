//
//  Game.swift
//  XGE
//
//  Created by Douglas McNamara on 8/15/26.
//

import Foundation
import simd
import Metal
import JavaScriptCore
import AVFoundation

@MainActor
public class Game {
    
    public let collider = Collider()
    
    private var _topDown = false
    private var _speed:Float = 100
    private var _move:Int = 0
    private var _dir:Int = 1
    private var _offset = Vec3(0, 200, 100)
    private var _playerName = "player.txt"
    private var _clip = Vec4(0, 0, 0, 0)
    private var _fontCols = 8
    private var _fontCharW = 16
    private var _fontCharH = 16
    private var _context:JSContext?
    private var _node:Node?
    private var _current:Node?
    private var _hasError = false
    private var _showStats = true
    private var _textScale:Int = 1
    private var _loadScene:String?
    private var _code:String?
    private var _joined:[String:Node] = [:]
    
    public init() {
        
    }
    
    public var topDown: Bool {
        get { _topDown }
    }
    
    public func parseVec2(tokens: [Substring], i:Int) -> Vec2 {
        var v = Vec2(0, 0)
        
        if i + 2 <= tokens.count {
            v.x = (tokens[i + 0] as NSString).floatValue
            v.y = (tokens[i + 1] as NSString).floatValue
        }
        return v
    }
    
    public func parseVec3(tokens: [Substring], i:Int) -> Vec3 {
        var v = Vec3(0, 0, 0)
        
        if i + 3 <= tokens.count {
            v.x = (tokens[i + 0] as NSString).floatValue
            v.y = (tokens[i + 1] as NSString).floatValue
            v.z = (tokens[i + 2] as NSString).floatValue
        }
        return v
    }
    
    public func loadGame() throws -> [String: [Substring]] {
        let lines = try String(contentsOf: AssetManager.rootURL!.appending(path: "Game.txt"), encoding: .utf8).split(whereSeparator: \.isNewline)
        var game:[String:[Substring]] = [:]
        
        for line in lines {
            let tLine = line.trimmingCharacters(in: .whitespaces)
            let tokens = tLine.split(whereSeparator: \.isWhitespace)
            
            if !tLine.hasPrefix("#") && !tLine.isEmpty {
                game["\(tokens[0])"] = tokens
            }
        }
        return game
    }
    
    public func parseColor(tokens: [Substring], i:Int) -> Vec4 {
        var color = Vec4(0, 0, 0, 1)
        
        if i + 4 <= tokens.count {
            color.x = (tokens[i + 0] as NSString).floatValue
            color.y = (tokens[i + 1] as NSString).floatValue
            color.z = (tokens[i + 2] as NSString).floatValue
            color.w = (tokens[i + 3] as NSString).floatValue
        }
        return color
    }
    
    public func load(gameView:GameView, root:Node, name:String) throws {
        Log.instance.put("loading \(name) ...")
        
        let lines = try String(contentsOf: AssetManager.rootURL!.appending(path: name), encoding: .utf8).split(whereSeparator: \.isNewline)
        let game = try loadGame()
        
        _topDown = false
        _speed = 100
        _move = 0
        _dir = 1
        _offset = Vec3(0, 200, 100)
        _playerName = "player.txt"
        _clip = Vec4(0, 0, 0, 0)
        _fontCols = 8
        _fontCharW = 16
        _fontCharH = 16
        _node = nil
        _current = nil
        _showStats = true
        _loadScene = nil
        
        if(name as NSString).pathExtension == "scene" {
            _joined = [:]
        }
        
        collider.radius = 16
        
        srand48(100)
        
        if let tokens = game["topDown"] {
            if tokens.count == 2 {
                _topDown = (tokens[1] == "true") ? true : false
            }
        }
        if let tokens = game["speed"] {
            if tokens.count == 2 {
                _speed = (tokens[1] as NSString).floatValue
            }
        }
        if let tokens = game["radius"] {
            if tokens.count == 2 {
                collider.radius = (tokens[1] as NSString).floatValue
            }
        }
        if let tokens = game["offset"] {
            let v = parseVec2(tokens: tokens, i:1)
            
            _offset = Vec3(0, v.x, v.y)
        }
        if let tokens = game["playerName"] {
            _playerName = "\(tokens[1])"
        }
        if let tokens = game["font"] {
            if tokens.count == 4 {
                _fontCols = (tokens[1] as NSString).integerValue
                _fontCharW = (tokens[2] as NSString).integerValue
                _fontCharH = (tokens[3] as NSString).integerValue
            }
        }
        if let tokens = game["clip"] {
            _clip = parseColor(tokens: tokens, i:1)
        }
        
        for line in lines {
            let tLine = line.trimmingCharacters(in: .whitespaces)
            let tokens = tLine.split(whereSeparator: \.isWhitespace)
            
            if !tLine.hasPrefix("#") && !tLine.isEmpty  && tokens.count >= 13 {
                let node = Node()
                
                node.name = "\(tokens[0])"
                node.position = Vec3(
                    (tokens[1] as NSString).floatValue,
                    (tokens[2] as NSString).floatValue,
                    (tokens[3] as NSString).floatValue
                )
                node.r = Vec3(
                    (tokens[4] as NSString).floatValue,
                    (tokens[5] as NSString).floatValue,
                    (tokens[6] as NSString).floatValue
                )
                node.u = Vec3(
                    (tokens[7] as NSString).floatValue,
                    (tokens[8] as NSString).floatValue,
                    (tokens[9] as NSString).floatValue
                )
                node.f = Vec3(
                    (tokens[10] as NSString).floatValue,
                    (tokens[11] as NSString).floatValue,
                    (tokens[12] as NSString).floatValue
                )
                if tokens.count > 13 {
                    node.data["value"] = "\(tokens[13])"
                } else {
                    node.data["value"] = ""
                }
                node.data["touched"] = false
 
                var nodeName = node.name
                
                if (nodeName as NSString).pathExtension.isEmpty {
                    nodeName = "\(nodeName).txt"
                }
                if !FileManager.default.fileExists(atPath: AssetManager.rootURL!.appending(path: nodeName).path) {
                    nodeName = nodeName.lowercased()
                }
                node.name = nodeName
                
                if !((nodeName as NSString).pathExtension == "txt" && (name as NSString).pathExtension == "txt") {
                    
                    try load(gameView: gameView, node: node)
                    
                    root.addChild(node)
                }
            }
        }
        if root === gameView.scene.root {
            if let player = root.find(name: _playerName) {
                if _topDown {
                    gameView.scene.target = player.position
                    gameView.scene.eye = player.position + _offset
                } else {
                    player.visible = false
                    gameView.scene.eye = player.position
                    gameView.scene.target = player.position + player.r
                    gameView.scene.up = player.u
                }
            }
        }
    }
    
    public func load(gameView:GameView, node:Node) throws -> Void {
        let game = try loadGame()

        if (node.name as NSString).pathExtension == "txt" {
            var join = false
            
            if let tokens = game["join.*"] {
                join = (tokens[1] == "true") ? true : false
            }
            if let tokens = game["join.\(node.name)"] {
                join = (tokens[1] == "true") ? true : false
            }
            
            if join {
                if let jnode = _joined[node.name] {
                    node.detachAll()
                    node.encodable = jnode.encodable
                } else {
                    try load(gameView: gameView, root: node, name: node.name)
                    
                    Log.instance.put("joining \(node.name) ...")
                    node.join()
                    
                    _joined[node.name] = node
                }
            } else {
                try load(gameView: gameView, root: node, name: node.name)
            }
        } else if (node.name as NSString).pathExtension == "obj" {
            node.encodable = try gameView.assets.load(path: node.name) as? Mesh
        } else {
            var mesh = try gameView.assets.load(path: node.name) as? KFMesh
            
            if let mesh = mesh {
                let m = mesh.newInstance() as! KFMesh
                
                node.encodable = m
            }
        }
        try setup(gameView: gameView, node: node, game: game)
    }
    
    public func findNode(node:Node, value:String) -> Node? {
        if let v = node.data["value"] as? String {
            if v.hasPrefix(value) {
                return node
            }
        }
        for i in (0..<node.childCount) {
            if let n = findNode(node: node[i], value: value) {
                return n
            }
        }
        return nil
    }
    
    private func setup(gameView:GameView, node:Node, game:[String:[Substring]]) throws {
        let name = node.name
        
        if let m = node.encodable as? KFMesh {
            if let tokens = game["sequence.\(name)"] {
                if tokens.count == 5 {
                    let s = (tokens[1] as NSString).integerValue
                    let e = (tokens[2] == "*") ? m.frames.count - 1 : (tokens[2] as NSString).integerValue
                    let v = (tokens[3] as NSString).integerValue
                    let l = (tokens[4] == "true") ? true : false
                    
                    m.setSequence(s, e, v, l)
                }
            }
            let tex = "\((name as NSString).deletingPathExtension).png"
            
            if FileManager.default.fileExists(atPath: AssetManager.rootURL!.appending(path: tex).path) {
                m.texture = try gameView.assets.load(path: tex) as? MTLTexture
            }
        }
        
        if let tokens = game["warp.\(name)"] {
            node.warpEnabled = (tokens[1] == "true") ? true : false
        }
        if let tokens = game["scale.\(name)"] {
            node.scale = parseVec3(tokens: tokens, i: 1)
        }
        if let tokens = game["receivesLight.*"] {
            if tokens.count == 2 {
                node.receivesLight = (tokens[1] == "true") ? true : false
            }
        }
        if let tokens = game["receivesLight.\(name)"] {
            if tokens.count == 2 {
                node.receivesLight = (tokens[1] == "true") ? true : false
            }
        }
        if let tokens = game["visible.*"] {
            if tokens.count == 2 {
                node.visible = (tokens[1] == "true") ? true : false
            }
        }
        if let tokens = game["visible.\(name)"] {
            if tokens.count == 2 {
                node.visible = (tokens[1] == "true") ? true : false
            }
        }
        if let tokens = game["collidable.*"] {
            if tokens.count == 2 {
                node.collidable = (tokens[1] == "true") ? true : false
            }
        }
        if let tokens = game["collidable.\(name)"] {
            if tokens.count == 2 {
                node.collidable = (tokens[1] == "true") ? true : false
            }
        }
        if let tokens = game["dynamic.*"] {
            if tokens.count == 2 {
                node.dynamic = (tokens[1] == "true") ? true : false
            }
        }
        if let tokens = game["dynamic.\(name)"] {
            if tokens.count == 2 {
                node.dynamic = (tokens[1] == "true") ? true : false
            }
        }
        if let tokens = game["ambientColor.*"] {
            node.ambientColor = parseColor(tokens: tokens, i:1)
        }
        if let tokens = game["ambientColor.\(name)"] {
            node.ambientColor = parseColor(tokens: tokens, i:1)
        }
        if let tokens = game["diffuseColor.*"] {
            node.diffuseColor = parseColor(tokens: tokens, i:1)
        }
        if let tokens = game["diffuseColor.\(name)"] {
            node.diffuseColor = parseColor(tokens: tokens, i:1)
        }
        if let tokens = game["depthWriteEnabled.*"] {
            if tokens.count == 2 {
                node.depthWriteEnabled = (tokens[1] == "true") ? true : false
            }
        }
        if let tokens = game["depthWriteEnabled.\(name)"] {
            if tokens.count == 2 {
                node.depthWriteEnabled = (tokens[1] == "true") ? true : false
            }
        }
        if let tokens = game["depthTestEnabled.*"] {
            if tokens.count == 2 {
                node.depthTestEnabled = (tokens[1] == "true") ? true : false
            }
        }
        if let tokens = game["depthTestEnabled.\(name)"] {
            if tokens.count == 2 {
                node.depthTestEnabled = (tokens[1] == "true") ? true : false
            }
        }
        if let tokens = game["blendEnabled.*"] {
            if tokens.count == 2 {
                node.blendEnabled = (tokens[1] == "true") ? true : false
            }
        }
        if let tokens = game["blendEnabled.\(name)"] {
            if tokens.count == 2 {
                node.blendEnabled = (tokens[1] == "true") ? true : false
            }
        }
        if let tokens = game["alphaBlend.*"] {
            if tokens.count == 2 {
                node.alphaBlend = (tokens[1] == "true") ? true : false
            }
        }
        if let tokens = game["alphaBlend.\(name)"] {
            if tokens.count == 2 {
                node.alphaBlend = (tokens[1] == "true") ? true : false
            }
        }
        if let tokens = game["zOrder.*"] {
            if tokens.count == 2 {
                node.zOrder = (tokens[1] as NSString).integerValue
            }
        }
        if let tokens = game["zOrder.\(name)"] {
            if tokens.count == 2 {
                node.zOrder = (tokens[1] as NSString).integerValue
            }
        }
        if let tokens = game["followEye.\(name)"] {
            if tokens.count == 2 {
                node.data["followEye"] = (tokens[1] == "true") ? true : false
            }
        }
        if let tokens = game["door.\(name)"] {
            if tokens.count == 3 {
                node.data["radius"] = (tokens[1] as NSString).floatValue
                node.data["amount"] = (tokens[2] as NSString).floatValue
                node.data["y"] = node.position.y
                node.data["door"] = true
            }
        }
        if let tokens = game["torch.\(name)"] {
            if tokens.count == 13 {
                let child = Node()
                
                child.position = parseVec3(tokens: tokens, i:1)
                child.emitsLight = true
                child.receivesLight = false
                child.lightRadius = (tokens[4] as NSString).floatValue
                child.data["baseRadius"] = child.lightRadius
                child.lightColor = parseColor(tokens: tokens, i: 5)
                child.data["flicker"] = (tokens[9] as NSString).floatValue
                child.scale = parseVec3(tokens: tokens, i: 10)
                child.encodable = ParticleSystem(maxParticles: 500)
                child.data["torch"] = true
                child.depthWriteEnabled = false
                child.blendEnabled = true
                child.alphaBlend = false
                child.zOrder = 1000
                
                if let p = child.encodable as? ParticleSystem {
                    p.texture = try gameView.assets.load(path: "fire.png") as? MTLTexture
                }
                node.addChild(child)
            }
        }
        if let tokens = game["decal.\(name)"] {
            if tokens.count == 3 {
                if let mesh = node.encodable as? Mesh {
                    let part = (tokens[1] as NSString).integerValue
                    
                    if part >= 0 && part < mesh.parts.count {
                        mesh.parts[part].decal = try gameView.assets.load(path: "\(tokens[2])") as? MTLTexture
                    }
                }
            }
        }
    }
    
    public func showStart(gameView:GameView, textColor1: Vec4, textColor2: Vec4) {
        if let sprite = gameView.scene.sprite {
            let w = Int(gameView.drawableSize.width)
            let h = Int(gameView.drawableSize.height)
            
            sprite.push("click to start", 1, _fontCols, _fontCharW, _fontCharH, 5, w / 2 - 7 * 16, h / 2 - 8 , textColor1, textColor2)
        }
    }
    
    public func clearContext() {
        _context = nil
        _hasError = false
        _code = nil
    }
    
    public func update(gameView:GameView, textScale: Int, textColor1: Vec4, textColor2: Vec4) {
        setupJSContext()
        
        _textScale = textScale
        if _showStats {
            if let sprite = gameView.scene.sprite {
                sprite.push(
                    """
                    FPS = \(gameView.fps)
                    TRI = \(gameView.scene.trianglesRendered)
                    RDR = \(gameView.scene.rendered)
                    BND = \(gameView.scene.cullStateBinds):\(gameView.scene.depthStateBinds):\(gameView.scene.renderStateBinds)
                    TST = \(collider.tested)
                    """, textScale, _fontCols, _fontCharW, _fontCharH, 5, 10, 10, textColor1, textColor2
                )
            }
        }
        
        if _topDown {
            topDownUdate(gameView: gameView)
        } else {
#if os(macOS)
            fpUpdate(gameView: gameView)
#endif
        }
        touch()
        update(gameView: gameView, node: gameView.scene.root, inDesign: false)
        
        if let name = _loadScene {
            _loadScene = nil
            do {
                gameView.newScene()
                
                try load(gameView: gameView, root: gameView.scene.root, name: name)
            } catch {
                _hasError = true
                Log.instance.put(error.localizedDescription)
            }
        }
    }
    
    public func updateInDesign(gameView:GameView, textColor1: Vec4, textColor2: Vec4) {
        _textScale = 1
        if let sprite = gameView.scene.sprite {
            sprite.push(
                """
                FPS = \(gameView.fps)
                TRI = \(gameView.scene.trianglesRendered)
                RDR = \(gameView.scene.rendered)
                BND = \(gameView.scene.cullStateBinds):\(gameView.scene.depthStateBinds):\(gameView.scene.renderStateBinds)
                TST = \(collider.tested)
                """, 1, _fontCols, _fontCharW, _fontCharH, 5, 10, 10, textColor1, textColor2
            )
        }
        update(gameView: gameView, node: gameView.scene.root, inDesign: true)
    }
    
    private func topDownUdate(gameView:GameView) {
        var vx:Float = 0
        var vz:Float = 0
        
        if _move == 1 {
            vz = -_speed
        } else if _move == 2 {
            vz = _speed
        } else if _move == 3 {
            vx = -_speed
        } else if _move == 4 {
            vx = _speed
        }
        
        if _move >= 1 && _move <= 4 {
            _dir = _move
        }
        
        if let node = gameView.scene.root.find(name: _playerName) {
            collider.velocity.y -= 2000 * gameView.elapsedTime
            collider.velocity *= Vec3(0, 1, 0)
            collider.velocity += Vec3(vx, 0, vz)
            node.position = collider.resolve(root: gameView.scene.root, position: node.position)
            
            var x = node.position.x
            var z = node.position.z
            
            x = max(gameView.scene.root.bounds.min.x + _clip.x, x)
            x = min(gameView.scene.root.bounds.max.x + _clip.y, x)
            z = max(gameView.scene.root.bounds.min.x + _clip.z, z)
            z = min(gameView.scene.root.bounds.max.x + _clip.w, z)
            
            gameView.scene.target = Vec3(x, node.position.y, z)
            gameView.scene.eye = gameView.scene.target + _offset
            
            vx = 0
            vz = 0
        }
    }
    
    private func fpUpdate(gameView: GameView) {
        gameView.scene.rotateAroundEye(dx: -gameView.deltaX, dy: -gameView.deltaY)
        
        let f = simd_normalize(gameView.scene.target - gameView.scene.eye)
        
        collider.velocity *= Vec3(0, 1, 0)
        if gameView.isButtonDown(button: 0) {
            collider.setForwardVelocity(speedAndDirection: _speed)
        } else if gameView.isButtonDown(button: 1) {
            collider.setForwardVelocity(speedAndDirection: -_speed)
        }
        collider.velocity.y -= 2000 * gameView.elapsedTime
        gameView.scene.eye = collider.resolve(root: gameView.scene.root, position: gameView.scene.eye)
        gameView.scene.target = gameView.scene.eye + f
    }
    
    private func touch() {
        for i in (0..<collider.hitNodeCount) {
            let node = collider.hitNodeAt(i)
            
            node.data["touched"] = true
        }
    }
    
    private func setupJSContext() {
        if _context === nil {
            Log.instance.put("setting up js context ...")
            
            _hasError = false
            _code = nil
            
            do {
                Log.instance.put("loading Game.js ...")
                _code = try String(contentsOf: AssetManager.rootURL!.appending(path: "Game.js"), encoding: .utf8)
            } catch {
                _hasError = true
                _code = nil
                
                Log.instance.put(error.localizedDescription)
            }
            
            _context = JSContext()
            
            if _hasError {
                return
            }
            
            if let context = _context {
                context.exceptionHandler = { [weak self] context, error in
                    Log.instance.put("\(error)")
                    self!._hasError = true
                }
                
                let toMe: @convention(block) () -> Void = { [weak self] in
                    if let node = self!._node {
                        self!._current = node
                    }
                }
                context.setObject(toMe, forKeyedSubscript: "toMe" as NSString)
                
                let to: @convention(block) (String) -> Void = { [weak self] name in
                    if let node = self!.findNode(node: GameView.instance!.scene.root, value: name) {
                        self!._current = node
                    }
                }
                context.setObject(to, forKeyedSubscript: "to" as NSString)
                
                let value: @convention(block) () -> String = { [weak self] in
                    if let current = self!._current {
                        if let value =  current.data["value"] as? String {
                            return value
                        }
                    }
                    return ""
                }
                context.setObject(value, forKeyedSubscript: "value" as NSString)
                
                let x: @convention(block) () -> Float = { [weak self] in
                    if let node = self!._current {
                        return node.position.x
                    }
                    return 0
                }
                context.setObject(x, forKeyedSubscript: "x" as NSString)
                
                let y: @convention(block) () -> Float = { [weak self] in
                    if let node = self!._current {
                        return node.position.y
                    }
                    return 0
                }
                context.setObject(y, forKeyedSubscript: "y" as NSString)
                
                let z: @convention(block) () -> Float = { [weak self] in
                    if let node = self!._current {
                        return node.position.z
                    }
                    return 0
                }
                context.setObject(z, forKeyedSubscript: "z" as NSString)
                
                let ax: @convention(block) () -> Float = { [weak self] in
                    if let node = self!._current {
                        return node.absolutePosition.x
                    }
                    return 0
                }
                context.setObject(ax, forKeyedSubscript: "ax" as NSString)
                
                let ay: @convention(block) () -> Float = { [weak self] in
                    if let node = self!._current {
                        return node.absolutePosition.y
                    }
                    return 0
                }
                context.setObject(ay, forKeyedSubscript: "ay" as NSString)
                
                let az: @convention(block) () -> Float = { [weak self] in
                    if let node = self!._current {
                        return node.absolutePosition.z
                    }
                    return 0
                }
                context.setObject(az, forKeyedSubscript: "az" as NSString)
                
                let position: @convention(block) (Float, Float, Float) -> Void = { [weak self] x, y, z in
                    if let node = self!._current {
                        node.position = Vec3(x, y, z)
                    }
                }
                context.setObject(position, forKeyedSubscript: "position" as NSString)
                
                let rotate: @convention(block) (Int, Float) -> Void = { [weak self] axis, degrees in
                    if let node = self!._current {
                        node.rotate(axis: axis, degrees: degrees * GameView.instance!.elapsedTime)
                    }
                }
                context.setObject(rotate, forKeyedSubscript: "rotate" as NSString)
                
                let resetRotation: @convention(block) () -> Void = { [weak self] in
                    if let node = self!._current {
                        node.r = Vec3(1, 0, 0)
                        node.u = Vec3(0, 1, 0)
                        node.f = Vec3(0, 0, 1)
                    }
                }
                context.setObject(resetRotation, forKeyedSubscript: "resetRotation" as NSString)
                
                let lookAt: @convention(block) (Float, Float, Float, Float, Float, Float) -> Void = { [weak self] x, y, z, ux, uy, uz in
                    if let node = self!._current {
                        node.lookAt(target: Vec3(x, y, z), up: Vec3(ux, uy, uz))
                    }
                }
                context.setObject(lookAt, forKeyedSubscript: "lookAt" as NSString)
                
                let hide: @convention(block) () -> Void = { [weak self] in
                    if let node = self!._current {
                        node.visible = false
                        node.collidable = false
                    }
                }
                context.setObject(hide, forKeyedSubscript: "hide" as NSString)
                
                let touched: @convention(block) () -> Bool = { [weak self] in
                    if let node = self!._current {
                        if let touched = node.data["touched"] as? Bool {
                            return touched
                        }
                    }
                    return false
                }
                context.setObject(touched, forKeyedSubscript: "touched" as NSString)
                
                let playSound: @convention(block) (String, Float) -> Void = { [weak self] name, volume in
                    if let node = self!._current {
                        do {
                            if let sound = try GameView.instance!.assets.load(path: name) as? AVAudioPlayer {
                                sound.volume = volume
                                sound.numberOfLoops = 0
                                sound.play()
                            }
                        } catch {
                            if let context = JSContext.current() {
                                let error = JSValue(newErrorFromMessage: "failed to load sound", in: context)
                                
                                context.exception = error
                            }
                            Log.instance.put("ERROR without context - failed to load sound")
                        }
                    }
                }
                context.setObject(playSound, forKeyedSubscript: "playSound" as NSString)
                
                let startSequence: @convention(block) (Int, Int, Int, Bool) -> Void = { [weak self] start, end, speed, looping in
                    if let node = self!._current {
                        if let kfm = node.encodable as? KFMesh {
                            kfm.setSequence(start, (end < 0) ? kfm.frames.count - 1 : end, speed, looping)
                        }
                    }
                }
                context.setObject(startSequence, forKeyedSubscript: "startSequence" as NSString)
                
                let resetSequence: @convention(block) () -> Void = { [weak self] in
                    if let node = self!._current {
                        if let kfm = node.encodable as? KFMesh {
                            kfm.reset()
                        }
                    }
                }
                context.setObject(resetSequence, forKeyedSubscript: "resetSequence" as NSString)
                
                let isDone: @convention(block) () -> Bool = { [weak self] in
                    if let node = self!._current {
                        if let kfm = node.encodable as? KFMesh {
                            return kfm.isDone
                        }
                    }
                    return true
                }
                context.setObject(isDone, forKeyedSubscript: "isDone" as NSString)
                
                let pause: @convention(block) (Bool) -> Void = { [weak self] paused in
                    if let node = self!._current {
                        if let kfm = node.encodable as? KFMesh {
                            kfm.paused = paused
                        }
                    }
                }
                context.setObject(pause, forKeyedSubscript: "pause" as NSString)
                
                let createParticles: @convention(block) (String, Int, Bool) -> Void = { [weak self] texture, maxCount, alphBlend in
                    if let node = self!._current {
                        let particles = ParticleSystem(maxParticles: maxCount)
                        
                        do {
                            particles.texture = try GameView.instance!.assets.load(path: texture) as? MTLTexture
                            node.depthWriteEnabled = false
                            node.depthTestEnabled = true
                            node.blendEnabled = true
                            node.alphaBlend = alphBlend
                            node.encodable = particles
                        } catch {
                            if let context = JSContext.current() {
                                let error = JSValue(newErrorFromMessage: "failed to load texture", in: context)
                                
                                context.exception = error
                            }
                            Log.instance.put("ERROR without context - failed to load texture")
                        }
                    }
                }
                context.setObject(createParticles, forKeyedSubscript: "createParticles" as NSString)
                
                let emit: @convention(block) (Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float) -> Void = {
                    [weak self] vx, vy, vz, x, y, z, sr, sg, sb, sa, er, eg, eb, ea, sx, sy, ex, ey, ls in
                    if let node = self!._current {
                        if let ps = node.encodable as? ParticleSystem {
                            var p = Particle()
                            
                            p.velocity = Vec3(vx, vy, vz)
                            p.startPosition = Vec3(x, y, z)
                            p.startColor = Vec4(sr, sg, sb, sa)
                            p.endColor = Vec4(er, eg, eb, ea)
                            p.startSize = Vec2(sx, sy)
                            p.endSize = Vec2(ex, ey)
                            p.lifeSpan = ls
                            
                            ps.emit(particle: p)
                        }
                    }
                }
                context.setObject(emit, forKeyedSubscript: "emit" as NSString)
                
                let emitPosition: @convention(block) (Float, Float, Float) -> Void = { [weak self] x, y, z in
                    if let node = self!._current {
                        if let ps = node.encodable as? ParticleSystem {
                            ps.emitPosition = Vec3(x, y, z)
                        }
                    }
                }
                context.setObject(emitPosition, forKeyedSubscript: "emitPosition" as NSString)
                
                let rand: @convention(block) () -> Float = { Float(drand48()) }
                context.setObject(rand, forKeyedSubscript: "rand" as NSString)
                
                let put: @convention(block) (String, Any) -> Void = { [weak self] name, value in
                    if let node = self!._current {
                        if let value = value as? Bool {
                            node.data[name] = value
                        } else if let value = value as? Int {
                            node.data[name] = value
                        } else if let value = value as? Float {
                            node.data[name] = value
                        } else if let value = value as? String {
                            node.data[name] = value
                        }
                    }
                }
                context.setObject(put, forKeyedSubscript: "put" as NSString)
                
                let get: @convention(block) (String) -> Any? = { [weak self] name in
                    if let node = self!._current {
                        if let v = node.data[name] {
                            return v
                        }
                    }
                    return nil
                }
                context.setObject(get, forKeyedSubscript: "get" as NSString)
                
                let setTexture: @convention(block) (String) -> Void = { [weak self] texture in
                    if let node = self!._current {
                        do {
                            if let kfm = node.encodable as? KFMesh {
                                kfm.texture = try GameView.instance!.assets.load(path: texture) as? MTLTexture
                            } else if let mesh = node.encodable as? Mesh {
                                if !mesh.parts.isEmpty {
                                    mesh.parts[0].texture = try GameView.instance!.assets.load(path: texture) as? MTLTexture
                                }
                            }
                        } catch {
                            if let context = JSContext.current() {
                                let error = JSValue(newErrorFromMessage: "failed to load texture", in: context)
                                
                                context.exception = error
                            }
                            Log.instance.put("ERROR without context - failed to load texture")
                        }
                    }
                }
                context.setObject(setTexture, forKeyedSubscript: "setTexture" as NSString)
                
                let setDecal: @convention(block) (String) -> Void = { [weak self] texture in
                    if let node = self!._current {
                        do {
                            if let kfm = node.encodable as? KFMesh {
                                kfm.decal = try GameView.instance!.assets.load(path: texture) as? MTLTexture
                            } else if let mesh = node.encodable as? Mesh {
                                if !mesh.parts.isEmpty {
                                    mesh.parts[0].decal = try GameView.instance!.assets.load(path: texture) as? MTLTexture
                                }
                            }
                        } catch {
                            if let context = JSContext.current() {
                                let error = JSValue(newErrorFromMessage: "failed to load texture", in: context)
                                
                                context.exception = error
                            }
                            Log.instance.put("ERROR without context - failed to load texture")
                        }
                    }
                }
                context.setObject(setDecal, forKeyedSubscript: "setDecal" as NSString)
                
                let isect: @convention(block) () -> Bool = { [weak self] in
                    if let node = self!._current {
                        var o = GameView.instance!.scene.eye
                        var d = simd_normalize(GameView.instance!.scene.target - o)
                        var t = Float.greatestFiniteMagnitude
                        
                        if self!._topDown {
                            if let player = GameView.instance!.scene.root.find(name: self!._playerName) {
                                o = player.position
                                
                                if self!._dir == 1 {
                                    d = Vec3(0, 0, -1)
                                } else if self!._dir == 2 {
                                    d = Vec3(0, 0, 1)
                                } else if self!._dir == 3 {
                                    d = Vec3(-1, 0, 0)
                                } else {
                                    d = Vec3(1, 0, 0)
                                }
                            }
                        }
                        
                        if let n = self!.collider.isect(root: GameView.instance!.scene.root, origin: o, direction: d, buffer: 1, collidablesOnly: true, time: &t) {
                            if let tri = self!.collider.hitTriangle {
                                self!._current = n
                                
                                let f = tri.normal
                                let r = simd_normalize(tri.p2 - tri.p1)
                                let u = simd_normalize(simd_cross(r, f))
                                let p = o + d * t
                                
                                n.data["_rx"] = r.x
                                n.data["_ry"] = r.y
                                n.data["_rz"] = r.z
                                n.data["_ux"] = u.x
                                n.data["_uy"] = u.y
                                n.data["_uz"] = u.z
                                n.data["_fx"] = f.x
                                n.data["_fy"] = f.y
                                n.data["_fz"] = f.z
                                n.data["_ix"] = p.x
                                n.data["_iy"] = p.y
                                n.data["_iz"] = p.z
                                
                                return true
                            }
                        }
                    }
                    return false
                }
                context.setObject(isect, forKeyedSubscript: "isect" as NSString)
                
                let pushText: @convention(block) (String, Int, Int, Int, Int, Int, Int, Float, Float, Float, Float, Float, Float, Float, Float) -> Void = {
                    [weak self] text, cols, charW, charH, lineSpacing, x, y, r1, g1, b1, a1, r2, g2, b2, a2 in
                    if let sprite = GameView.instance!.scene.sprite {
                        sprite.push(text, self!._textScale, cols, charW, charH, lineSpacing, x, y, Vec4(r1, g1, b1, a1), Vec4(r2, g2, b2, a2))
                    }
                }
                context.setObject(pushText, forKeyedSubscript: "pushText" as NSString)
                
                let pushSprite: @convention(block) (Int, Int, Int, Int, Int, Int, Int, Int, Float, Float, Float, Float, Float, Float, Float, Float) -> Void = {
                    sx, sy, sw, sh, dx, dy, dw, dh, r1, g1, b1, a1, r2, g2, b2, a2 in
                    if let sprite = GameView.instance!.scene.sprite {
                        sprite.push(sprite.texture, sx, sy, sw, sh, dx, dy, dw, dh, Vec4(r1, g1, b1, a1), Vec4(r2, g2, b2, a2), false)
                    }
                }
                context.setObject(pushSprite, forKeyedSubscript: "pushSprite" as NSString)
                
                let hideStats: @convention(block) () -> Void = { [weak self] in self!._showStats = false }
                context.setObject(hideStats, forKeyedSubscript: "hideStats" as NSString)
                
                let elapsed: @convention(block) () -> Float = { GameView.instance!.elapsedTime }
                context.setObject(elapsed, forKeyedSubscript: "elapsed" as NSString)
                
                let total: @convention(block) () -> Float = { GameView.instance!.totalTime }
                context.setObject(total, forKeyedSubscript: "total" as NSString)
                
                let print: @convention(block) (String) -> Void = { value in Log.instance.put(value) }
                context.setObject(print, forKeyedSubscript: "print" as NSString)
                
                let width: @convention(block) () -> Int = { Int(GameView.instance!.drawableSize.width) }
                context.setObject(width, forKeyedSubscript: "width" as NSString)
                
                let height: @convention(block) () -> Int = { Int(GameView.instance!.drawableSize.height) }
                context.setObject(height, forKeyedSubscript: "height" as NSString)
                
                let viewWidth: @convention(block) () -> Int = { Int(GameView.instance!.frame.size.width) }
                context.setObject(viewWidth, forKeyedSubscript: "viewWidth" as NSString)
                
                let viewHeight: @convention(block) () -> Int = { Int(GameView.instance!.frame.size.height) }
                context.setObject(viewHeight, forKeyedSubscript: "viewHeight" as NSString)
                
                let isButtonDown: @convention(block) (Int) -> Bool = { button in GameView.instance!.isButtonDown(button: button) }
                context.setObject(isButtonDown, forKeyedSubscript: "isButtonDown" as NSString)
                
                let isKeyDown: @convention(block) (Int) -> Bool = { key in GameView.instance!.isKeyDown(key: key) }
                context.setObject(isKeyDown, forKeyedSubscript: "isKeyDown" as NSString)
                
                let mouseX: @convention(block) () -> Float = { GameView.instance!.mouseX }
                context.setObject(mouseX, forKeyedSubscript: "mouseX" as NSString)
                
                let mouseY: @convention(block) () -> Float = { GameView.instance!.mouseY }
                context.setObject(mouseY, forKeyedSubscript: "mouseY" as NSString)
                
                let loadScene: @convention(block) (String) -> Void = { [weak self] name in self!._loadScene = name }
                context.setObject(loadScene, forKeyedSubscript: "loadScene" as NSString)
                
                let move: @convention(block) (Int) -> Void = { [weak self] m in self!._move = m }
                context.setObject(move, forKeyedSubscript: "move" as NSString)
                
                let iOS: @convention(block) () -> Bool = {
#if os(macOS)
                    return false
#else
                    return true
#endif
                }
                context.setObject(iOS, forKeyedSubscript: "iOS" as NSString)
                
                let emitLight: @convention(block) (Float, Float, Float, Float, Float) -> Void = { [weak self] r, g, b, a, radius in
                    if let node = self!._current {
                        node.emitsLight = true
                        node.lightColor = Vec4(r, g, b, a)
                        node.lightRadius = radius
                    }
                }
                context.setObject(emitLight, forKeyedSubscript: "emitLight" as NSString)
                
                let load: @convention(block) () -> String? = {
                    do {
                        if GameView.inProduction {
                            return try String(contentsOf: URL.documentsDirectory.appending(path: "_data").appendingPathExtension("txt"), encoding: .utf8)
                        } else {
                            return try String(contentsOf: AssetManager.rootURL!.appending(path: "_data").appendingPathExtension("txt"), encoding: .utf8)
                        }
                    } catch {
                        Log.instance.put(error.localizedDescription)
                    }
                    return nil
                }
                context.setObject(load, forKeyedSubscript: "load" as NSString)
                
                let save: @convention(block) (String) -> Void = { text in
                    do {
                        if GameView.inProduction {
                            try text.write(to: URL.documentsDirectory.appending(path: "_data").appendingPathExtension("txt"), atomically: true, encoding: .utf8)
                        } else {
                            try text.write(to: AssetManager.rootURL!.appending(path: "_data").appendingPathExtension("txt"), atomically: true, encoding: .utf8)
                        }
                    } catch {
                        if let context = JSContext.current() {
                            let error = JSValue(newErrorFromMessage: "failed to load _data.txt", in: context)
                            
                            context.exception = error
                        }
                        Log.instance.put("ERROR without context - failed to load _data.txt")
                    }
                }
                context.setObject(save, forKeyedSubscript: "save" as NSString)
                
                let setBlendState: @convention(block) (Int) -> Void = { [weak self] state in
                    if let node = self!._current {
                        if state == 0 {
                            node.depthWriteEnabled = true
                            node.depthTestEnabled = true
                            node.blendEnabled = false
                        } else {
                            node.depthWriteEnabled = false
                            node.depthTestEnabled = true
                            node.blendEnabled = true
                            node.alphaBlend = (state == 1) ? true : false
                        }
                    }
                }
                context.setObject(setBlendState, forKeyedSubscript: "setBlendState" as NSString)
                
                let setZOrder: @convention(block) (Int) -> Void = { [weak self] zOrder in
                    if let node = self!._current {
                        node.zOrder = zOrder
                    }
                }
                context.setObject(setZOrder, forKeyedSubscript: "setZOrder" as NSString)
                
                let setTintColor: @convention(block) (Float, Float, Float, Float) -> Void = { [weak self] r, g, b, a in
                    if let node = self!._current {
                        node.tintColor = Vec4(r, g, b, a)
                    }
                }
                context.setObject(setTintColor, forKeyedSubscript: "setTintColor" as NSString)
                
                let triangleCount: @convention(block) () -> Int = { [weak self] in
                    if let node = self!._current {
                        return node.triangleCount
                    }
                    return 0
                }
                context.setObject(triangleCount, forKeyedSubscript: "triangleCount" as NSString)
                
                let triangle: @convention(block) (Int, Int, Int) -> Float = { [weak self] triI, pointI, component in
                    if let node = self!._current {
                        if let tri = node.triangleAt(i: triI) {
                            var p = tri[pointI]
                            
                            if component == 1 {
                                return p.x
                            } else if component == 2 {
                                return p.y
                            } else {
                                return p.z
                            }
                        }
                    }
                    return 0
                }
                context.setObject(triangle, forKeyedSubscript: "triangle" as NSString)
                
                do {
                    let items = try FileManager.default.contentsOfDirectory(atPath: AssetManager.rootURL!.path)
                    
                    for item in items {
                        if (item as NSString).pathExtension == "js" {
                            if item.lowercased() != "game.js" {
                                Log.instance.put("evaluating \(item) ...")
                                
                                context.evaluateScript(try String(contentsOf: AssetManager.rootURL!.appending(path: item), encoding: .utf8))
                            }
                        }
                    }
                } catch {
                    Log.instance.put(error.localizedDescription)
                    
                    _hasError = true
                    _code = nil
                }
            }
        }
    }
    
    private func update(gameView: GameView, node:Node, inDesign:Bool) {
        if !inDesign {
            if let followEye = node.data["followEye"] as? Bool {
                node.position = gameView.scene.eye
            }

            if let context = _context, let code = _code {
                if !_hasError {
                    _current = node
                    _node = node
                    
                    context.evaluateScript(code)
                }
            }
            
            if let door = node.data["door"] as? Bool {
                if let radius = node.data["radius"] as? Float, let amount = node.data["amount"] as? Float, let y = node.data["y"] as? Float {
                    var position = gameView.scene.eye
                    
                    if topDown {
                        position = gameView.scene.target
                    }
                    let d = simd_length(position * Vec3(1, 0, 1) - node.absolutePosition * Vec3(1, 0, 1))
                    let a = 1 - min(d / radius, 1)
                    
                    node.position.y = y - a * amount
                }
            }
            
            node.data["touched"] = false
        }
        if let torch = node.data["torch"] as? Bool {
            if let particles = node.encodable as? ParticleSystem {
                if let flicker = node.data["flicker"] as? Float {
                    let sc = 0.25 + Float(drand48() * 0.5)
                    let ss = 10 + Float(drand48() * 30)
                    let vy = 20 + Float(drand48() * 30)
                    var p = Particle()
                    
                    p.startPosition = Vec3(
                        -5 + Float(drand48() * 10),
                        -5 + Float(drand48() * 10),
                        -5 + Float(drand48() * 10)
                         )
                    p.velocity = Vec3(0, vy, 0)
                    p.startColor = Vec4(sc, sc, sc, 1)
                    p.endColor = Vec4(0, 0, 0, 1)
                    p.startSize = Vec2(ss, ss)
                    p.endSize = Vec2(0.1, 0.1)
                    p.lifeSpan = 0.5 + Float(drand48() * 1.5)
                    
                    particles.emit(particle: p)
                    
                    if let baseRadius = node.data["baseRadius"] as? Float {
                        node.lightRadius = baseRadius + sinf(gameView.totalTime * 7) * flicker
                    }
                }
            }
        }
        for i in (0..<node.childCount) {
            update(gameView: gameView, node: node[i], inDesign: inDesign)
        }
    }
}
