
import Foundation
import MetalKit
import Metal
import simd

struct Vertex {
    var position: SIMD3<Float>
    var textureCoordinate: SIMD2<Float>
}


@MainActor
class Renderer: NSObject {
    unowned var mtkView: MTKView
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var depthState: MTLDepthStencilState!
    var texture1: MTLTexture!
    var texture2: MTLTexture!
    var topLeftDepth: Float = 1.0
    var topRightDepth: Float = 1.0
    var bottomLeftDepth: Float = 1.0
    var bottomRightDepth: Float = 1.0

    var viewPortSize: vector_int2 = .zero
    
    init(mtkView: MTKView) {
        self.mtkView = mtkView
        device = mtkView.device
        commandQueue = device.makeCommandQueue()
        
        mtkView.depthStencilPixelFormat = .depth32Float
        mtkView.clearDepth = 1.0
        
        // background color
        mtkView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1)
        let library = device.makeDefaultLibrary()
        let vertextFunc = library?.makeFunction(name: "vertexShader")
        let fragmentFunc = library?.makeFunction(name: "fragmentShader")
        
        // Create render pipeline
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertextFunc
        pipelineDescriptor.fragmentFunction = fragmentFunc
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("fail to create pipelineState")
        }
        
        // Create depth test pipeline
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .lessEqual
        depthDescriptor.isDepthWriteEnabled = true
        depthState = device.makeDepthStencilState(descriptor: depthDescriptor)
        assert(depthState != nil)
        super.init()
    }
    
}


extension Renderer: MTKViewDelegate {
    func draw(in view: MTKView) {
        guard let renderPassDesriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        let commanderBuffer = commandQueue.makeCommandBuffer()
        let commanderEncoder = commanderBuffer?.makeRenderCommandEncoder(descriptor: renderPassDesriptor)
        commanderEncoder?.setRenderPipelineState(pipelineState)
        commanderEncoder?.setDepthStencilState(depthState)
        
        commanderEncoder?.setVertexBytes(&viewPortSize, length: MemoryLayout<vector_int2>.stride, index: 1)
        if let texture1 {
            let vertices = [
                // 左上角
                Vertex(position: [-256,  256, 0.5], textureCoordinate: [0.0, 0.0]),
                // 左下角
                Vertex(position: [-256, -256, 0.5], textureCoordinate: [0.0, 1.0]),
                // 右下角
                Vertex(position: [ 256, -256, 0.5], textureCoordinate: [1.0, 1.0]),
                // 左上角
                Vertex(position: [-256,  256, 0.5], textureCoordinate: [0.0, 0.0]),
                // 右下角
                Vertex(position: [ 256, -256, 0.5], textureCoordinate: [1.0, 1.0]),
                // 右上角
                Vertex(position: [ 256,  256, 0.5], textureCoordinate: [1.0, 0.0]),
            ]
            
            let vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count)
            commanderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            
            commanderEncoder?.setFragmentTexture(texture1, index: 0)
            commanderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        }
        
        if let texture2 {
            let vertices = [
                // 左上角
                Vertex(position: [-256,  256, topLeftDepth], textureCoordinate: [0.0, 0.0]),
                // 左下角
                Vertex(position: [-256, -256, bottomLeftDepth], textureCoordinate: [0.0, 1.0]),
                // 右下角
                Vertex(position: [ 256, -256, bottomRightDepth], textureCoordinate: [1.0, 1.0]),
                // 左上角
                Vertex(position: [-256,  256, topLeftDepth], textureCoordinate: [0.0, 0.0]),
                // 右下角
                Vertex(position: [ 256, -256, bottomRightDepth], textureCoordinate: [1.0, 1.0]),
                // 右上角
                Vertex(position: [ 256,  256, topRightDepth], textureCoordinate: [1.0, 0.0]),
            ]
            
            let vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count)
            commanderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            
            commanderEncoder?.setFragmentTexture(texture2, index: 0)
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
}
