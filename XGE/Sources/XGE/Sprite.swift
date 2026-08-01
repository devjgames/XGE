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
    private var _vertexBuffer:MTLBuffer?
    private var _vertices:[Vertex] = []
    private var _vertexCount:Int = 0
    private var _texture:MTLTexture?
    private let _light:[Light] = [Light].init(repeating: Light(), count: 1)
    
    public init(texture: MTLTexture) {
        _texture = texture
        _renderPipeline = GameView.instance!.renderPipeline(blendEnabled: true, alphaBlend: true)
        _depthState = GameView.instance!.depthState(depthTestEnabled: false, depthWriteEnabled: false)
    }
    
    public func push(_ sx: Int, _ sy: Int, _ sw: Int, _ sh: Int, _ dx: Int, _ dy: Int, _ dw: Int, _ dh: Int, _ color: Vec4) {
        if let texture = _texture {
            let tw:Float = Float(texture.width)
            let th:Float = Float(texture.height)
            let sx1:Float = Float(sx) / tw
            let sy1:Float = Float(sy) / th
            let sx2:Float = Float(sx + sw) / tw
            let sy2:Float = Float(sy + sh) / th
            let dx1:Float = Float(dx)
            let dy1:Float = Float(dy)
            let dx2:Float = Float(dx + dw)
            let dy2:Float = Float(dy + dh)
            var vertex = Vertex()
            
            vertex.position = Vec3(dx1, dy1, 0)
            vertex.textureCoordinate = Vec2(sx1, sy1)
            vertex.color = color
            _vertices.append(vertex)
            
            vertex.position = Vec3(dx1, dy2, 0)
            vertex.textureCoordinate = Vec2(sx1, sy2)
            _vertices.append(vertex)
            
            vertex.position = Vec3(dx2, dy2, 0)
            vertex.textureCoordinate = Vec2(sx2, sy2)
            _vertices.append(vertex)
            
            vertex.position = Vec3(dx2, dy2, 0)
            vertex.textureCoordinate = Vec2(sx2, sy2)
            _vertices.append(vertex)
            
            vertex.position = Vec3(dx2, dy1, 0)
            vertex.textureCoordinate = Vec2(sx2, sy1)
            _vertices.append(vertex)
            
            vertex.position = Vec3(dx1, dy1, 0)
            vertex.textureCoordinate = Vec2(sx1, sy1)
            _vertices.append(vertex)
        }
    }
    
    public func push(_ text:String, _ cols:Int, _ charW:Int, _ charH:Int, _ lineSpacing: Int, _ x:Int, _ y:Int, _ color:Vec4) {
        if let _ = _texture {
            let s:NSString = text as NSString
            let l:Int = s.length
            var p = x
            var py = y
            
            for i in (0..<l) {
                let c = s.character(at: i)
                
                if s.substring(with: NSRange(location: i, length: 1)) == "\n" {
                    p = x
                    py = py + charH + lineSpacing
                } else if c >= 32 {
                    let j = c - 32
                    let c = Int(j % UInt16(cols))
                    let r = Int(j / UInt16(cols))
                    
                    push(c * charW, r * charH, charW, charH, p, py, charW, charH, color)
                    p += charW
                }
            }
        }
    }
    
    public func buffer() {
        let count = _vertices.count
        
        if !_vertices.isEmpty {
            if _vertexCount < count {
                Log.instance.put("creating sprite vertex buffer ...")
                _vertexCount = count
                _vertexBuffer = GameView.instance!.device!.makeBuffer(length: _vertexCount * MemoryLayout<Vertex>.stride, options: .storageModeManaged)
            }
            memmove(_vertexBuffer!.contents(), &_vertices, count * MemoryLayout<Vertex>.stride)
            _vertexBuffer!.didModifyRange((0..<count * MemoryLayout<Vertex>.stride))
            
            let commandBuffer = GameView.instance!.commandQueue.makeCommandBuffer()!
            let encoder = commandBuffer.makeBlitCommandEncoder()!
            
            encoder.synchronize(resource: _vertexBuffer!)
            encoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }
    
    public func encode(encoder:MTLRenderCommandEncoder) {
        if !_vertices.isEmpty {
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
            encoder.setVertexBuffer(_vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&vertexData, length: MemoryLayout<VertexData>.stride, index: 1)
            encoder.setFragmentBytes(&fragmentData, length: MemoryLayout<FragmentData>.stride, index: 0)
            encoder.setFragmentBytes(_light, length: MemoryLayout<Light>.stride, index: 1)
            encoder.setFragmentTexture(_texture, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: _vertices.count)
            
            _vertices.removeAll(keepingCapacity: true)
        }
    }
}
