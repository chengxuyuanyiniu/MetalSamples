
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
    private var computePipelineState: MTLComputePipelineState!
    var offscreenRenderPassDescriptor: MTLRenderPassDescriptor!
    var computePassDescriptor: MTLComputePassDescriptor!
    var inputTexture: MTLTexture!
    var outputTexture: MTLTexture!

    var viewPortSize: vector_int2 = .zero
    
    init(mtkView: MTKView) {
        self.mtkView = mtkView
        super.init()

        device = mtkView.device
        commandQueue = device.makeCommandQueue()
        
    
       
        
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
        
        // Compute pipeline
        guard let kernelFunction = library?.makeFunction(name: "grayscaleKernel") else {
            fatalError("fail to load kernel function - grayscaleKernel")
        }
        do {
            computePipelineState = try device.makeComputePipelineState(function: kernelFunction)
        } catch {
            fatalError("fail to create compute pipelineState")
        }
        
        inputTexture = createInputTexture()
        
        let outputTextureDescriptor = createOutputTextureDescriptor(inputTexture: inputTexture)
        outputTexture = device.makeTexture(descriptor: outputTextureDescriptor)
        
    }
    
    private func createInputTexture() -> MTLTexture? {
        let device = MTLCreateSystemDefaultDevice()!
        let loader = MTKTextureLoader(device: device)
        guard let url = Bundle.main.url(forResource: "lena_color", withExtension: "png") else {
            return nil
        }
        let texture = try? loader.newTexture(URL: url)
        return texture
    }
    
    func createOutputTextureDescriptor(inputTexture: MTLTexture) -> MTLTextureDescriptor {
        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = .type2D
        descriptor.width = inputTexture.width
        descriptor.height = inputTexture.height
        descriptor.pixelFormat = inputTexture.pixelFormat
        // shaderWrite -> compute pass, shaderRead -> render pass
        descriptor.usage = [.shaderWrite, .shaderRead]
        return descriptor
    }
    
    var threadsPerThreadgroup: MTLSize {
        let w = computePipelineState?.threadExecutionWidth ?? 0
        let h = (computePipelineState?.maxTotalThreadsPerThreadgroup ?? 0) / w
        return MTLSize(width: w, height: h, depth: 1)
    }
}


extension Renderer: MTKViewDelegate {
    func draw(in view: MTKView) {
        let commanderBuffer = commandQueue.makeCommandBuffer()
        // Compute Pass - Process the input image
        let computeEncoder = commanderBuffer?.makeComputeCommandEncoder()
        
        computeEncoder?.setComputePipelineState(computePipelineState)
        computeEncoder?.setTexture(inputTexture, index: 0)
        computeEncoder?.setTexture(outputTexture, index: 1)
        let threadsPerGrid = MTLSize(width: inputTexture.width, height: inputTexture.height, depth: 1)
        computeEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        computeEncoder?.endEncoding()
        
        // Drawable Render Pass
        guard let renderPassDesriptor = view.currentRenderPassDescriptor else {
            return
        }
        let commanderEncoder = commanderBuffer?.makeRenderCommandEncoder(descriptor: renderPassDesriptor)
        commanderEncoder?.setRenderPipelineState(drawablePipelineState)
        if let outputTexture {
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
            commanderEncoder?.setFragmentTexture(outputTexture, index: 0)
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
