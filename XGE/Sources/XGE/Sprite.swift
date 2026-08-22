//
//  Sprite.swift
//  XGE
//
//  Created by Douglas McNamara on 9/11/25.
//

import Foundation
import simd
import Metal
import MetalKit

@MainActor
public class Sprite {
    
    private var _renderPipeline:MTLRenderPipelineState?
    private var _depthState:MTLDepthStencilState?
    private var _vertexBuffer:[MTLBuffer?] = []
    private var _textures:[MTLTexture] = []
    private var _vertices:[[Vertex]] = []
    private var _vertexCount:[Int] = []
    private var _texture:MTLTexture?
    private let _light:[Light] = [Light].init(repeating: Light(), count: 1)
    private var _top:Int = -1
    
    public init(texture: MTLTexture) {
        _texture = texture
        _renderPipeline = GameView.instance!.renderPipeline(blendEnabled: true, alphaBlend: true)
        _depthState = GameView.instance!.depthState(depthTestEnabled: false, depthWriteEnabled: false)
    }
    
    public var texture:MTLTexture {
        get { _texture! }
    }
    
    public func push(_ texture: MTLTexture, _ sx: Int, _ sy: Int, _ sw: Int, _ sh: Int, _ dx: Int, _ dy: Int, _ dw: Int, _ dh: Int, _ color1: Vec4, _ color2: Vec4, _ flip:Bool) {
        var push = _textures.isEmpty
        
        if !push {
            push = _textures.last! !== texture
        }
        if push {
            _textures.append(texture)
            _top += 1
            if _top >= _vertexBuffer.count {
                _vertexBuffer.append(nil)
                _vertices.append([])
                _vertexCount.append(0)
            }
        }
        if let texture = _textures.last {
            let tw:Float = Float(texture.width)
            let th:Float = Float(texture.height)
            let sx1:Float = Float(sx) / tw
            var sy1:Float = Float(sy) / th
            let sx2:Float = Float(sx + sw) / tw
            var sy2:Float = Float(sy + sh) / th
            let dx1:Float = Float(dx)
            let dy1:Float = Float(dy)
            let dx2:Float = Float(dx + dw)
            let dy2:Float = Float(dy + dh)
            var vertex = Vertex()
            
            if flip {
                let tmp = sy1
                
                sy1 = sy2
                sy2 = tmp
            }
            
            vertex.position = Vec3(dx1, dy1, 0)
            vertex.textureCoordinate = Vec2(sx1, sy1)
            vertex.color = color1
            _vertices[_top].append(vertex)
            
            vertex.position = Vec3(dx1, dy2, 0)
            vertex.textureCoordinate = Vec2(sx1, sy2)
            vertex.color = color2
            _vertices[_top].append(vertex)
            
            vertex.position = Vec3(dx2, dy2, 0)
            vertex.color = color2
            vertex.textureCoordinate = Vec2(sx2, sy2)
            _vertices[_top].append(vertex)
            
            vertex.position = Vec3(dx2, dy2, 0)
            vertex.textureCoordinate = Vec2(sx2, sy2)
            vertex.color = color2
            _vertices[_top].append(vertex)
            
            vertex.position = Vec3(dx2, dy1, 0)
            vertex.textureCoordinate = Vec2(sx2, sy1)
            vertex.color = color1
            _vertices[_top].append(vertex)
            
            vertex.position = Vec3(dx1, dy1, 0)
            vertex.textureCoordinate = Vec2(sx1, sy1)
            vertex.color = color1
            _vertices[_top].append(vertex)
        }
    }
    
    public func push(_ text:String, _ scale:Int, _ cols:Int, _ charW:Int, _ charH:Int, _ lineSpacing: Int, _ x:Int, _ y:Int, _ color1:Vec4, _ color2:Vec4) {
        if(cols < 1) {
            return
        }
        if let texture = _texture {
            let s:NSString = text as NSString
            let l:Int = s.length
            var p = x
            var py = y
            
            for i in (0..<l) {
                let c = s.character(at: i)
                
                if s.substring(with: NSRange(location: i, length: 1)) == "\n" {
                    p = x
                    py = py + charH * scale + lineSpacing * scale
                } else if c >= 32 {
                    let j = c - 32
                    let c = Int(j % UInt16(cols))
                    let r = Int(j / UInt16(cols))
                    
                    push(texture, c * charW, r * charH, charW, charH, p, py, charW * scale, charH * scale, color1, color2, false)
                    p += charW * scale
                }
            }
        }
    }
    
    public func buffer() {
        for i in (0..<_textures.count) {
            let count = _vertices[i].count
            
            if _vertexCount[i] < count {
                Log.instance.put("creating sprite vertex buffer ...")
                _vertexCount[i] = count
#if os(macOS)
                _vertexBuffer[i] = GameView.instance!.device!.makeBuffer(length: _vertexCount[i] * MemoryLayout<Vertex>.stride, options: .storageModeManaged)
#else
                _vertexBuffer[i] = GameView.instance!.device!.makeBuffer(length: _vertexCount[i] * MemoryLayout<Vertex>.stride, options: .storageModeShared)
#endif
            }
            memmove(_vertexBuffer[i]!.contents(), &_vertices[i], count * MemoryLayout<Vertex>.stride)
            
#if os(macOS)
            _vertexBuffer[i]!.didModifyRange((0..<count * MemoryLayout<Vertex>.stride))
            
            let commandBuffer = GameView.instance!.commandQueue.makeCommandBuffer()!
            let encoder = commandBuffer.makeBlitCommandEncoder()!
            
            encoder.synchronize(resource: _vertexBuffer[i]!)
            encoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
#endif
        }
    }
    
    public func encode(encoder:MTLRenderCommandEncoder) {
        for i in (0..<_textures.count) {
            var vertexData = VertexData()
            var fragmentData = FragmentData()
            
            vertexData.projection = Mat4.ortho(0,
                                               Float(GameView.instance!.drawableSize.width),
                                               Float(GameView.instance!.drawableSize.height),
                                               0, -1, 1)
            fragmentData.textureEnabled = 1
            
            encoder.setCullMode(.none)
            encoder.setRenderPipelineState(_renderPipeline!)
            encoder.setDepthStencilState(_depthState!)
            encoder.setVertexBuffer(_vertexBuffer[i]!, offset: 0, index: 0)
            encoder.setVertexBytes(&vertexData, length: MemoryLayout<VertexData>.stride, index: 1)
            encoder.setFragmentBytes(&fragmentData, length: MemoryLayout<FragmentData>.stride, index: 0)
            encoder.setFragmentBytes(_light, length: MemoryLayout<Light>.stride, index: 1)
            encoder.setFragmentTexture(_textures[i], index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: _vertices[i].count)
            
            _vertices[i].removeAll(keepingCapacity: true)
        }
        _textures.removeAll()
        _top = -1
    }
}
