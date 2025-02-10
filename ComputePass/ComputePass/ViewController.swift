

import Cocoa
import MetalKit

class ViewController: NSViewController {
    var render: Renderer!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
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
    }
}

