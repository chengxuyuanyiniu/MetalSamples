

import Cocoa
import MetalKit

class ViewController: NSViewController {
    var renderer: Renderer!

    override func viewDidLoad() {
        super.viewDidLoad()

        
        let metalView = view as! MTKView
        metalView.device = MTLCreateSystemDefaultDevice()
        metalView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        renderer = Renderer(mtkView: metalView)
        metalView.delegate = renderer
    }
}

