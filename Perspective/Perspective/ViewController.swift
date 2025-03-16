

import Cocoa
import MetalKit

class ViewController: NSViewController {
    var render: Renderer!

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let mtkView = view as? MTKView else {
            fatalError("Please use the MTKView")
        }
        // Do any additional setup after loading the view.
        mtkView.device = MTLCreateSystemDefaultDevice()
        // 背景颜色
        mtkView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        mtkView.enableSetNeedsDisplay = true
        render = Renderer(mtkView: mtkView)
        render.mtkView(mtkView, drawableSizeWillChange: self.view.frame.size)
        mtkView.delegate = render
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }



}

