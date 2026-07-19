//
//  AssetManager.swift
//  XGE
//
//  Created by Douglas McNamara on 9/4/25.
//

import Foundation
import MetalKit
import Metal
import AVFoundation

@MainActor
public protocol AssetLoader {
    
    func load(url:URL) throws -> AnyObject?
}

@MainActor
public class TextureLoader : AssetLoader {

    
    private var _loader:MTKTextureLoader
    
    init() {
        _loader = MTKTextureLoader(device: GameView.instance!.device!)
    }
    
    public func load(url:URL) throws -> AnyObject? {
        try _loader.newTexture(URL: url, options: [ .SRGB: false, .allocateMipmaps: false, .generateMipmaps: false ])
    }
}

@MainActor
public class SoundLoader : AssetLoader {
    
    public func load(url: URL) throws -> AnyObject? {
        try AVAudioPlayer(contentsOf: url)
    }
}

@MainActor
public class AssetManager {
    
    @MainActor
    public static var rootURL:URL?=Bundle.main.resourceURL?.appendingPathComponent("Assets")
    
    @MainActor
    private static var _assetLoaders:[String:AssetLoader]=[:]
    
    public static func registerAssetLoader(type:String, assetLoader:AssetLoader) {
        _assetLoaders[type] = assetLoader
    }
    
    private var _assets:[String:AnyObject] = [:]
    
    public init() {
    }
    
    public func assetExists(path:String) -> Bool {
        let url = AssetManager.rootURL!.appendingPathComponent(path)
        
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    public func unload(path:String) {
        _assets.removeValue(forKey: path)
    }
    
    public func load(path:String) throws -> AnyObject? {
        if _assets[path] == nil {
            Log.instance.put("loading asset \(path) ...")
            
            let type = (path as NSString).pathExtension
            let assetLoader=AssetManager._assetLoaders[type]
            
            if assetLoader == nil {
                throw NSError(domain: "Asset loader '\(type)' not found", code: 0)
            }
            _assets[path] = try assetLoader!.load(url: AssetManager.rootURL!.appendingPathComponent(path))
        }
        return _assets[path]
    
    }
    
    public func clear() {
        for asset in _assets.values {
            if let sound = asset as? AVAudioPlayer {
                sound.stop()
            }
        }
        _assets.removeAll()
    }
}
