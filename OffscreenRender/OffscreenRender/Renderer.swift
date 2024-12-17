
import Foundation
import MetalKit
import Metal
import simd

struct Vertex {
    var pixelPosition: SIMD2<Float>
    var textureCoordinate: SIMD2<Float>
}


struct OffscreenVertex {
    var position: SIMD4<Float>
    var color: SIMD4<Float>
}


@MainActor
class Renderer: NSObject {
    unowned var mtkView: MTKView
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var drawablePipelineState: MTLRenderPipelineState!
    private var offscreenPipelineState: MTLRenderPipelineState!
    var offscreenTexture: MTLTexture!
    var offscreenRenderPassDescriptor: MTLRenderPassDescriptor!
    
    var viewPortSize: vector_int2 = .zero
    
    init(mtkView: MTKView) {
        self.mtkView = mtkView
        super.init()

        device = mtkView.device
        commandQueue = device.makeCommandQueue()
        
        let textureDescriptor = createOffscreenTetureDescriptor()
        offscreenTexture = device.makeTexture(descriptor: textureDescriptor)
        
        offscreenRenderPassDescriptor = MTLRenderPassDescriptor()
        offscreenRenderPassDescriptor.colorAttachments[0].texture = offscreenTexture
        offscreenRenderPassDescriptor.colorAttachments[0].loadAction = .clear
        offscreenRenderPassDescriptor.colorAttachments[0].storeAction = .store
        offscreenRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.5, green: 1.0, blue: 1.0, alpha: 1.0)
        
        let library = device.makeDefaultLibrary()
        // Drawable pineline
        let drawablePipelineDescriptor = MTLRenderPipelineDescriptor()
        drawablePipelineDescriptor.label = "Drawable Render Pinepline"
        drawablePipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertexShader")
        drawablePipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragmentShader")
        drawablePipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        do {
            drawablePipelineState = try device.makeRenderPipelineState(descriptor: drawablePipelineDescriptor)
        } catch {
            fatalError("fail to create pipelineState")
        }
        
        // Offscreen pipeline
        let offscreenPipelineDescriptor = MTLRenderPipelineDescriptor()
        offscreenPipelineDescriptor.label = "Offscreen Render Pinepline"
        offscreenPipelineDescriptor.vertexFunction = library?.makeFunction(name: "offscreenVertexShader")
        offscreenPipelineDescriptor.fragmentFunction = library?.makeFunction(name: "offscreenFragmentShader")
        offscreenPipelineDescriptor.colorAttachments[0].pixelFormat = offscreenTexture.pixelFormat
        do {
            offscreenPipelineState = try device.makeRenderPipelineState(descriptor: offscreenPipelineDescriptor)
        } catch {
            fatalError("fail to create offscreen pipelineState")
        }

    }
    
    //
    func createOffscreenTetureDescriptor() -> MTLTextureDescriptor {
        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = .type2D
        descriptor.width = 512
        descriptor.height = 512
        descriptor.pixelFormat = .rgba8Unorm
        descriptor.usage = [.renderTarget, .shaderRead]
        return descriptor
    }
    
}


extension Renderer: MTKViewDelegate {
    func draw(in view: MTKView) {
        let commanderBuffer = commandQueue.makeCommandBuffer()
        // Offscreen Render Pass
        offscreenRender(commanderBuffer: commanderBuffer)
        
        
        // Drawable Render Pass
        guard let renderPassDesriptor = view.currentRenderPassDescriptor else {
            return
        }
        let commanderEncoder = commanderBuffer?.makeRenderCommandEncoder(descriptor: renderPassDesriptor)
        commanderEncoder?.setRenderPipelineState(drawablePipelineState)
        if let offscreenTexture {
            let vertices = [
                // 左上角
                Vertex(pixelPosition: [-256,  256], textureCoordinate: [0.0, 0.0]),
                // 左下角
                Vertex(pixelPosition: [-256, -256], textureCoordinate: [0.0, 1.0]),
                // 右下角
                Vertex(pixelPosition: [ 256, -256], textureCoordinate: [1.0, 1.0]),
                // 左上角
                Vertex(pixelPosition: [-256,  256], textureCoordinate: [0.0, 0.0]),
                // 右下角
                Vertex(pixelPosition: [ 256, -256], textureCoordinate: [1.0, 1.0]),
                // 右上角
                Vertex(pixelPosition: [ 256,  256], textureCoordinate: [1.0, 0.0]),
            ]
            
            let vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count)
            commanderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            commanderEncoder?.setVertexBytes(&viewPortSize, length: MemoryLayout<vector_int2>.stride, index: 1)
            commanderEncoder?.setFragmentTexture(offscreenTexture, index: 0)
            commanderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        }
 
        commanderEncoder?.endEncoding()
        
        guard let drawable = view.currentDrawable else {
            return
        }
        commanderBuffer?.present(drawable)
        commanderBuffer?.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewPortSize = vector_int2(x: Int32(size.width), y: Int32(size.height))
    }
    
    func offscreenRender(commanderBuffer: MTLCommandBuffer?) {
        let commanderEncoder = commanderBuffer?.makeRenderCommandEncoder(descriptor: offscreenRenderPassDescriptor)
        commanderEncoder?.setRenderPipelineState(offscreenPipelineState)
        let vertices = [
            //左下角
            OffscreenVertex(position: [-1.0, -1.0, 1.0, 1.0], color: [1.0, 0.0, 0.0, 1.0]),
            //正上方
            OffscreenVertex(position: [ 0.0,  1.0, 1.0, 1.0], color: [1.0, 0.5, 0.0, 1.0]),
            //右下角
            OffscreenVertex(position: [ 1.0, -1.0, 1.0, 1.0], color: [0.0, 1.0, 0.0, 1.0]),
        ]
        
        let vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<OffscreenVertex>.stride * vertices.count)
        commanderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        commanderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        
        commanderEncoder?.endEncoding()
    }
}
