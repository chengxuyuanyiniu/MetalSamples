
import Foundation
import MetalKit
import Metal
import simd

struct Vertex {
    var pixelPosition: SIMD2<Float>
    var textureCoordinate: SIMD2<Float>
}

class Renderer: NSObject {
    unowned var mtkView: MTKView
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    var texture: MTLTexture!
    
    var viewPortSize: vector_int2 = .zero
    
    init(mtkView: MTKView) {
        self.mtkView = mtkView
        device = mtkView.device
        commandQueue = device.makeCommandQueue()
        
        let library = device.makeDefaultLibrary()
        let vertextFunc = library?.makeFunction(name: "vertexShader")
        let fragmentFunc = library?.makeFunction(name: "fragmentShader")
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertextFunc
        pipelineDescriptor.fragmentFunction = fragmentFunc
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("fail to create pipelineState")
        }

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
        commanderEncoder?.setFragmentTexture(texture, index: 0)
        commanderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
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
