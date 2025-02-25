

import Cocoa
import MetalKit

class ViewController: NSViewController {
    var render: Renderer!

    override func viewDidLoad() {
        super.viewDidLoad()

        let metalView = view as! MTKView
        
        metalView.device = MTLCreateSystemDefaultDevice()
        
        render = Renderer(mtkView: metalView)
        
        render.mtkView(metalView, drawableSizeWillChange: metalView.drawableSize)
        
        render.texture1 = createTexture(fileName: "aobing")
        
        render.texture2 = createTexture(fileName: "nezha")

        metalView.delegate = render
    }


    func createTexture(fileName: String) -> MTLTexture? {
        let device = MTLCreateSystemDefaultDevice()!
        let loader = MTKTextureLoader(device: device)
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "png") else {
            return nil
        }
        let texture = try? loader.newTexture(URL: url)
        return texture
    }
    
   
    @IBOutlet weak var topLeftLabel: NSTextField!
    
    @IBAction func onChangeTopLeftSlider(_ sender: NSSlider) {
        topLeftLabel.stringValue = "Top Left Depth: " + String(format: "%.2f", sender.floatValue / 100.0)
        render.topLeftDepth = sender.floatValue / 100.0
    }
    
    @IBOutlet weak var topRightLabel: NSTextField!
    
    @IBAction func onChangeTopRightSlider(_ sender: NSSlider) {
        topRightLabel.stringValue = "Top Right Depth: " + String(format: "%.2f", sender.floatValue / 100.0)
        render.topRightDepth = sender.floatValue / 100.0

    }
    
    @IBOutlet weak var bottomLeftLabel: NSTextField!
    
    @IBAction func onChangeBottomLeftSlider(_ sender: NSSlider) {
        bottomLeftLabel.stringValue = "Bottom Left Depth: " + String(format: "%.2f", sender.floatValue / 100.0)
        render.bottomLeftDepth = sender.floatValue / 100.0

    }
    
    @IBOutlet weak var bottomRightLabel: NSTextField!
    
    @IBAction func onChangeBottomRightSlider(_ sender: NSSlider) {
        bottomRightLabel.stringValue = "Bottom Right Depth: " + String(format: "%.2f", sender.floatValue / 100.0)
        render.bottomRightDepth = sender.floatValue / 100.0

    }
    
}

