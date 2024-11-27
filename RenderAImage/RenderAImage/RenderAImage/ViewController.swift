

import Cocoa
import MetalKit

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
        mtkView.enableSetNeedsDisplay = false
        
        render = Renderer(mtkView: mtkView)
        render.texture = createTexture(device: mtkView.device!)
        mtkView.delegate = render
        
      
    }
    
    func createTexture(device: MTLDevice) -> MTLTexture? {
        let loader = MTKTextureLoader(device: device)
        guard let url = Bundle.main.url(forResource: "lena_color", withExtension: "png") else {
            return nil
        }
        let texture = try? loader.newTexture(URL: url)
        return texture
    }
}

