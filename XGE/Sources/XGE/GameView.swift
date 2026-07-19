//
//  GameView.swift
//  XGE
//
//  Created by Douglas McNamara on 8/28/25.
//

import Cocoa
import Metal
import MetalKit

@MainActor
open class GameView : MTKView {
    
    public static let keyCount:Int = 500
    public static let buttonCount:Int = 2
    public static var inDesign = true
    
    private static var _instance : GameView?
    private var trackingArea: NSTrackingArea?
    
    public static var instance : GameView? {
        get { _instance }
    }
    
    private var _commandQueue:MTLCommandQueue?
    private var _library:MTLLibrary?
    private var _assets:AssetManager?
    private var _keyState:[Bool] = []
    private var _buttonState:[Bool] = [ false, false ]
    private var _mouseX:Float = 0
    private var _mouseY:Float = 0
    private var _deltaX:Float = 0
    private var _deltaY:Float = 0
    private var _lastX:Float = 0
    private var _lastY:Float = 0
    private var _lastTime:Double = 0
    private var _totalTime:Double = 0
    private var _elapsedTime:Double = 0
    private var _seconds:Double = 0
    private var _frames:Int = 0
    private var _fps:Int = 0
    private var _continuousMouseEnabled = false
    private var _scene :Scene?
    private var _depthStates:[String:MTLDepthStencilState] = [:]
    private var _renderStates:[String:MTLRenderPipelineState] = [:]
    
    public override init(frame frameRect: CGRect, device: (any MTLDevice)?) {
        super.init(frame: frameRect, device: device)
        
        setup()
    }
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)
        
        device = MTLCreateSystemDefaultDevice()
        
        setup()
    }
    
    public func renderPipeline(blendEnabled:Bool, alphaBlend:Bool) -> MTLRenderPipelineState? {
        let key = "\(blendEnabled):\(alphaBlend)"
        
        if _renderStates[key] == nil {
            let descriptor = MTLRenderPipelineDescriptor()
            
            Log.instance.put("creating render pipeline ...")
            
            descriptor.vertexFunction = library.makeFunction(name: "vertexShader")
            descriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
            descriptor.colorAttachments[0].pixelFormat = GameView.instance!.colorPixelFormat
            descriptor.colorAttachments[0].isBlendingEnabled = blendEnabled
            descriptor.depthAttachmentPixelFormat = GameView.instance!.depthStencilPixelFormat
            if blendEnabled {
                descriptor.colorAttachments[0].alphaBlendOperation = .add
                if alphaBlend {
                    descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
                    descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
                    descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
                    descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
                } else {
                    descriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
                    descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
                    descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
                    descriptor.colorAttachments[0].sourceRGBBlendFactor = .one
                }
            }
            do {
                _renderStates[key] = try GameView.instance!.device!.makeRenderPipelineState(descriptor: descriptor)
            } catch {
                Log.instance.put(error)
            }
        }
        if let renderState = _renderStates[key] {
            return renderState
        }
        return nil
    }
    
    public func depthState(depthTestEnabled:Bool, depthWriteEnabled:Bool) -> MTLDepthStencilState? {
        let key = "\(depthTestEnabled):\(depthWriteEnabled)"
        
        if _depthStates[key] == nil {
            let descritor = MTLDepthStencilDescriptor()
            
            Log.instance.put("creating depth state ...")
            
            descritor.isDepthWriteEnabled = depthWriteEnabled
            descritor.depthCompareFunction = (depthTestEnabled) ? .less : .always
            
            _depthStates[key] = GameView.instance!.device!.makeDepthStencilState(descriptor: descritor)
        }
        if let depthState = _depthStates[key] {
            return depthState
        }
        return nil
    }
    
    open override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        
        let newTrackingArea = NSTrackingArea(
            rect:self.bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeInActiveApp],
            owner: self,
            userInfo: nil
            )
        
        self.addTrackingArea(newTrackingArea)
        self.trackingArea = newTrackingArea
    }
    
    private func setup() {
        wantsLayer = true
        
        preferredFramesPerSecond = 60
        colorPixelFormat = .bgra8Unorm
        depthStencilPixelFormat = .depth32Float
        clearDepth = 1.0
        drawableSize = frame.size
        layer!.magnificationFilter = .nearest
        layer!.minificationFilter = .nearest
        
        if !Log.hasInstance {
            _ = Log()
        }
        
        _commandQueue = device!.makeCommandQueue()
        
        do {
            _library = try device!.makeDefaultLibrary(bundle: Bundle.module)
        } catch {
            Log.instance.put(error)
        }
        _assets = AssetManager()
        
        for _ in (0..<GameView.keyCount) {
            _keyState.append(false)
        }
        
        resetTimer()
        
        GameView._instance = self
        
        AssetManager.registerAssetLoader(type: "png", assetLoader: TextureLoader())
        AssetManager.registerAssetLoader(type: "wav", assetLoader: SoundLoader())
        AssetManager.registerAssetLoader(type: "kfm", assetLoader: KFMeshLoader())
        AssetManager.registerAssetLoader(type: "obj", assetLoader: MeshLoader())
        
        _scene = Scene()
    }
    
    public func activate() {
        GameView._instance = self
    }
    
    public override var preferredDrawableSize: CGSize {
        get { frame.size }
    }
    
    public var scene : Scene {
        get { _scene! }
    }
    
    public override var canBecomeKeyView: Bool {
        get { true }
    }
    
    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
    
    public override var acceptsFirstResponder: Bool {
        get { true }
    }
    
    public var continuousMouseEnabled:Bool {
        get { _continuousMouseEnabled }
        set {
            if _continuousMouseEnabled != newValue {
                _continuousMouseEnabled = newValue
                if _continuousMouseEnabled {
                    _deltaX = 0
                    _deltaY = 0
                    NSCursor.hide()
                } else {
                    NSCursor.unhide()
                }
            }
        }
    }
    
    public var commandQueue:MTLCommandQueue {
        get { _commandQueue! }
    }
    
    public var library:MTLLibrary {
        get { _library! }
    }
    
    public var assets:AssetManager {
        get { _assets! }
    }
    
    public var mouseX:Float {
        get { _mouseX }
    }
    
    public var mouseY:Float {
        get { _mouseY }
    }
    
    public var deltaX:Float {
        get { _deltaX }
    }
    
    public var deltaY:Float {
        get { _deltaY }
    }
    
    public func isButtonDown(button:Int) -> Bool {
        if button >= 0 && button < GameView.buttonCount {
            return _buttonState[button]
        }
        return false
    }
    
    public func isKeyDown(key:Int) -> Bool {
        if key >= 0 && key < GameView.keyCount {
            return _keyState[key]
        }
        return false
    }
    
    public override func keyDown(with event: NSEvent) {
        let code:Int=Int(event.keyCode)
        
        if code >= 0 && code < GameView.keyCount {
            _keyState[code] = true
        }
    }
    
    public override func keyUp(with event: NSEvent) {
        let code:Int=Int(event.keyCode)
        
        if code >= 0 && code < GameView.keyCount {
            _keyState[code] = false
        }
    }
    
    public override func mouseDown(with event: NSEvent) {
        _buttonState[0] = true
        
        if !_continuousMouseEnabled {
            down(locationInView(event: event))
        }
    }
    
    public override func mouseUp(with event: NSEvent) {
        _buttonState[0] = false
        
        if !_continuousMouseEnabled {
            up()
        }
    }
    
    public override func mouseDragged(with event: NSEvent) {
        if !_continuousMouseEnabled {
            record(locationInView(event: event))
        }
    }
    
    open override func mouseMoved(with event: NSEvent) {
        if !_continuousMouseEnabled {
            record(locationInView(event: event))
        }
    }
    
    public override func rightMouseDown(with event: NSEvent) {
        _buttonState[1] = true
        
        if !_continuousMouseEnabled {
            down(locationInView(event: event))
        }
    }
    
    public override func rightMouseUp(with event: NSEvent) {
        _buttonState[1] = false
        
        if !_continuousMouseEnabled {
            up()
        }
    }
    
    public override func rightMouseDragged(with event: NSEvent) {
        if !_continuousMouseEnabled {
            record(locationInView(event: event))
        }
    }
    
    private func locationInView(event: NSEvent) -> CGPoint {
        var pt = event.locationInWindow

        pt = self.convert(pt, from: nil)

        return pt
    }
    
    private func down(_ pt: CGPoint) {
        _mouseX = Float(pt.x)
        _mouseY = Float(pt.y)
        _lastX = _mouseX
        _lastY = _mouseY
        _deltaX = 0
        _deltaY = 0
    }
    
    private func up() {
        _lastX = 0
        _lastY = 0
        _deltaX = 0
        _deltaY = 0
    }
    
    private func record(_ pt: CGPoint) {
        _mouseX = Float(pt.x)
        _mouseY = Float(pt.y)
        _deltaX = _mouseX - _lastX
        _deltaY = _mouseY - _lastY
        _lastX = _mouseX
        _lastY = _mouseY
    }
    
    public var elapsedTime:Float {
        get { Float(_elapsedTime) }
    }
    
    public var totalTime:Float {
        get { Float(_totalTime) }
    }
    
    public var fps:Int {
        get { _fps }
    }
    
    public func resetTimer() {
        _lastTime = Double(DispatchTime.now().uptimeNanoseconds) / 1000000000.0
        _totalTime = 0
        _elapsedTime = 0
        _seconds = 0
        _frames = 0
        _fps = 0
    }
    
    public func newScene() {
        Log.instance.put("creating scene ...")
        scene.root.detachAll()
    
        _scene = Scene()
        _assets!.clear()
    }
    
    public func tick() {
        let now:Double = Double(DispatchTime.now().uptimeNanoseconds) / 1000000000.0
        
        _elapsedTime = now - _lastTime
        _lastTime = now
        _totalTime += _elapsedTime
        _seconds += _elapsedTime
        _frames += 1
        if _seconds >= 1 {
            _fps = _frames
            _frames = 0
            _seconds = 0
        }
        if _continuousMouseEnabled {
            let f = self.frame
            var p = CGPoint(x: Double(f.origin.x + f.width / 2), y: Double(f.origin.y + f.height / 2))
            
            p = self.convert(p, to: nil)
            p = self.window!.convertPoint(toScreen: p)
            
            p.y = NSScreen.main!.frame.height - p.y
            
            CGWarpMouseCursorPosition(p)
            
            let d = CGGetLastMouseDelta()
            
            _deltaX = Float(d.x)
            _deltaY = Float(d.y)
        } else {
            _deltaX = 0
            _deltaY = 0
        }
    }
}

