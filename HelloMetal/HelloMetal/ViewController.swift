
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
        mtkView.clearColor = MTLClearColor(red: 0.5, green: 1.0, blue: 1.0, alpha: 1.0)
        mtkView.enableSetNeedsDisplay = true
        
        render = Renderer(mtkView: mtkView)
        mtkView.delegate = render
    }
    
    
}

