

import Cocoa
import Metal
import MetalKit

class ViewController: NSViewController {
    var renderer: Renderer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let metalView = self.view as! MTKView
        // This may affect performance!
        metalView.framebufferOnly = false
        metalView.colorPixelFormat = MTLPixelFormat.rgba8Unorm
        metalView.device = MTLCreateSystemDefaultDevice()
        renderer = Renderer(mtkView: metalView)
        metalView.delegate = renderer
        
    }
    
    override func mouseDown(with event: NSEvent) {
        let bottomUpPixelPosition = view.convertToBacking(event.locationInWindow)
        let bottomDownPixelPosition = CGPoint(x: bottomUpPixelPosition.x, y: view.frame.size.height - bottomUpPixelPosition.y)
        let pixel = renderer.renderAndReadPixel(from: self.view as! MTKView, at: bottomDownPixelPosition)
        print(pixel ?? "Nothing")
        if let pixel {
            view.window?.title = "r:\(pixel.r) g:\(pixel.g) b:\(pixel.b) a:\(pixel.a)"
        }
    }
}

