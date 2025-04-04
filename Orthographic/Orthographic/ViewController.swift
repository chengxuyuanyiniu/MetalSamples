

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
        render = Renderer(mtkView: mtkView)
        render.mtkView(mtkView, drawableSizeWillChange: self.view.frame.size)
        mtkView.delegate = render
        
        render.texture = createTexture(fileName: "nezha")
        
        startTimer()
    }
    
    func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [self] timer in
            updateRotation()
        }
    }
    func updateRotation() {
        render.rotationAngle += 1.0
        if render.rotationAngle >= 360 {
            render.rotationAngle -= 360
        }
        
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
}


