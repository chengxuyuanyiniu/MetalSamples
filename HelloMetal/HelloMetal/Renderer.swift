
import Foundation
import MetalKit
import Metal
class Renderer: NSObject {
    unowned var mtkView: MTKView
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    
    
    init(mtkView: MTKView) {
        self.mtkView = mtkView
        device = mtkView.device
        commandQueue = device.makeCommandQueue()
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
        commanderEncoder?.endEncoding()
        
        guard let drawable = view.currentDrawable else {
            return
        }
        commanderBuffer?.present(drawable)
        commanderBuffer?.commit()
        commanderBuffer?.waitUntilCompleted()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}
