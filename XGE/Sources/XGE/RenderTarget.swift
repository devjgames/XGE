//
//  RenderTarget.swift
//  XGE
//
//  Created by Douglas McNamara on 8/11/26.
//

import Foundation
import Metal

@MainActor
public class RenderTarget {
    
    private var renderPassDescriptor:MTLRenderPassDescriptor?
    
    public init(w:Int, h:Int) throws {
        renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor!.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        renderPassDescriptor!.colorAttachments[0].storeAction = .store
        renderPassDescriptor!.colorAttachments[0].loadAction = .clear
        renderPassDescriptor!.depthAttachment.clearDepth = 1
        renderPassDescriptor!.depthAttachment.storeAction = .store
        renderPassDescriptor!.depthAttachment.loadAction = .clear
        
        let colorDescriptor = MTLTextureDescriptor()
        
        colorDescriptor.textureType = .type2D
        colorDescriptor.width = w
        colorDescriptor.height = h
        colorDescriptor.pixelFormat = GameView.instance!.colorPixelFormat
        colorDescriptor.usage = [ .shaderRead, .shaderWrite, .renderTarget ]
        
        renderPassDescriptor!.colorAttachments[0].texture = GameView.instance!.device!.makeTexture(descriptor: colorDescriptor)
        
        let depthTextureDescriptor = MTLTextureDescriptor()
        
        depthTextureDescriptor.textureType = .type2D
        depthTextureDescriptor.width = w
        depthTextureDescriptor.height = h
        depthTextureDescriptor.pixelFormat = GameView.instance!.depthStencilPixelFormat
        depthTextureDescriptor.usage = [ .shaderWrite, .shaderRead, .renderTarget ]
        
        renderPassDescriptor!.depthAttachment.texture = GameView.instance!.device!.makeTexture(descriptor: depthTextureDescriptor)
    }
    
    public var descriptor:MTLRenderPassDescriptor {
        get { renderPassDescriptor! }
    }
}
