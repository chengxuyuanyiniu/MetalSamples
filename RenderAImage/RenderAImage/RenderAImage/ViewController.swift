

import Cocoa
import MetalKit
import Metal
class ViewController: NSViewController {
    var render: Renderer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let mtkView = view as? MTKView else {
            fatalError("Please use the MTKView")
        }
        
        mtkView.device = MTLCreateSystemDefaultDevice()
        // 背景颜色
        mtkView.clearColor = MTLClearColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 1.0)
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = true
        
        render = Renderer(mtkView: mtkView)
        render.viewPortSize = vector_int2(x: Int32(view.frame.size.width), y: Int32(view.frame.size.height))
        mtkView.delegate = render
        
        Task.detached {
            let texture = await self.createTexture()
            await self.redraw(texture: texture)
        }
    }
    
    func redraw(texture: MTLTexture?) {
        render.texture = texture
        self.view.needsDisplay = true
    }
    
    nonisolated func createTexture() async -> MTLTexture? {
        let device = MTLCreateSystemDefaultDevice()!
        let loader = MTKTextureLoader(device: device)
        guard let url = Bundle.main.url(forResource: "lena_color", withExtension: "png") else {
            return nil
        }
        let texture = try? await loader.newTexture(URL: url)
        return texture
    }
    
}

