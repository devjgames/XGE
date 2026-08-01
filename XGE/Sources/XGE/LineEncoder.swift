//
//  LineEncoder.swift
//  XGE
//
//  Created by Douglas McNamara on 2/5/26.
//

import Foundation
import Metal
import MetalKit

@MainActor
public class LineEncoder {
    
    private var _vertices:[Vertex] = []
    private var _vertexBuffer:MTLBuffer?
    private var _depthState:MTLDepthStencilState?
    private var _renderPipelineState:MTLRenderPipelineState?
    private var _vertexCount:Int = 0
    
    public init() {
        
        _renderPipelineState = GameView.instance!.renderPipeline(blendEnabled: false, alphaBlend: true)
        _depthState = GameView.instance?.depthState(depthTestEnabled: true, depthWriteEnabled: true)
    }
    
    public func pushLine(p1:Vec3, p2:Vec3, c1:Vec4, c2:Vec4) {
        var v = Vertex()
        
        v.position = p1
        v.color = c1
        _vertices.append(v)
        
        v.position = p2
        v.color = c2
        _vertices.append(v)
    }
    
    public func buffer() {
        if _vertices.isEmpty {
            return
        }
        
        let length = MemoryLayout<Vertex>.stride * _vertices.count
        
        _vertexCount = _vertices.count
        
        var create = _vertexBuffer == nil
        
        if !create {
            create = length > _vertexBuffer!.length
        }
        
        if create {
            Log.instance.put("creating line encoder vertex buffer ...")
            _vertexBuffer = GameView.instance!.device!.makeBuffer(length: length + 6000 * MemoryLayout<Vertex>.stride, options: .storageModeManaged)
            _vertices.removeAll(keepingCapacity: true)
        }
        
        memmove(_vertexBuffer!.contents(), _vertices, length)
        _vertexBuffer!.didModifyRange(0..<length)
        
        let commandBuffer = GameView.instance!.commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeBlitCommandEncoder()!
        
        encoder.synchronize(resource: _vertexBuffer!)
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        _vertices.removeAll(keepingCapacity: true)
    }
    
    public func encode(encoder:MTLRenderCommandEncoder) {
        if let vertexBuffer = _vertexBuffer {
            if _vertexCount != 0 {
                encoder.setRenderPipelineState(_renderPipelineState!)
                encoder.setDepthStencilState(_depthState!)
                
                var lights:[Light] = []
                
                for _ in (0..<MaxLights) {
                    lights.append(Light())
                }
                
                encoder.setFragmentBytes(lights, length: MemoryLayout<Light>.stride * MaxLights, index: 1)
                
                var vertexData = VertexData()
                
                vertexData.projection = GameView.instance!.scene.projection
                vertexData.view = GameView.instance!.scene.view
                vertexData.model = Mat4.identity()
                vertexData.modelIT = Mat4.identity()
                vertexData.warpEnabled = 0
                
                encoder.setVertexBytes(&vertexData, length: MemoryLayout<VertexData>.stride, index: 1)
                
                var fragmentData = FragmentData()
                
                encoder.setFragmentBytes(&fragmentData, length: MemoryLayout<FragmentData>.stride, index: 0)
                encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
                
                encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: _vertexCount)
            }
        }
    }
}
