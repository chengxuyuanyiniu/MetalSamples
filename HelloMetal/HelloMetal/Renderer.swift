
import Foundation
import MetalKit
import Metal
import simd

struct Vertext {
    var position: SIMD4<Float>
    var color: SIMD4<Float>
}

class Renderer: NSObject {
    unowned var mtkView: MTKView
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    
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
            //左下角
            Vertext(position: [-1.0, -1.0, 1.0, 1.0], color: [1.0, 0.0, 0.0, 1.0]),
            //正上方
            Vertext(position: [ 0.0,  1.0, 1.0, 1.0], color: [1.0, 0.5, 0.0, 1.0]),
            //右下角
            Vertext(position: [ 1.0, -1.0, 1.0, 1.0], color: [0.0, 1.0, 0.0, 1.0]),
        ]
        
        let vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertext>.stride * vertices.count)
        commanderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        commanderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        
        commanderEncoder?.endEncoding()
        
        guard let drawable = view.currentDrawable else {
            return
        }
        commanderBuffer?.present(drawable)
        commanderBuffer?.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}
