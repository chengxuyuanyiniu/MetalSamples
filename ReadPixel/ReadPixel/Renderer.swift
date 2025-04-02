
import Foundation
import MetalKit
import Metal
import simd

struct Vertext {
    var position: SIMD4<Float>
    var color: SIMD4<Float>
}

struct Pixel {
    let r: UInt8
    let g: UInt8
    let b: UInt8
    let a: UInt8
}

class Renderer: NSObject {
    unowned var mtkView: MTKView
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var isDrawForReadThisFrame = false
    
    init(mtkView: MTKView) {
        self.mtkView = mtkView
        device = mtkView.device
        commandQueue = device.makeCommandQueue()
        
        let library = device.makeDefaultLibrary()
        let vertextFunc = library?.makeFunction(name: "vertexShader")
        let fragmentFunc = library?.makeFunction(name: "fragmentShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertextFunc
        pipelineDescriptor.fragmentFunction = fragmentFunc
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("fail to create pipelineState")
        }
        
        super.init()
    }
    
    
    func renderAndReadPixel(from theView: MTKView, at pixelPosition: CGPoint) -> Pixel? {
        let commandBuffer = commandQueue.makeCommandBuffer()
        drawQuad(in: theView, with: commandBuffer)
        isDrawForReadThisFrame = false
        guard let readTexture = theView.currentDrawable?.texture else {
            return nil
        }
        // We only want to get the pixel of the click point.
        let region = CGRect(x: pixelPosition.x, y: pixelPosition.y, width: 1, height: 1)
        guard let pixelBuffer = readPixels(commandBuffer: commandBuffer, from: readTexture, at: region) else {
            return nil
        }
        let pixelPointer = pixelBuffer.contents().bindMemory(to: UInt8.self, capacity: 4)
        let r = pixelPointer[0]
        let g = pixelPointer[1]
        let b = pixelPointer[2]
        let a = pixelPointer[3]
        return Pixel(r: r, g: g, b: b, a: a)
    }
    
    func readPixels(commandBuffer: MTLCommandBuffer?, from texture: MTLTexture, at region: CGRect) -> MTLBuffer? {
        let sourceOrigin = MTLOrigin(x: Int(region.origin.x), y: Int(region.origin.y), z: 0)
        let sourceSize = MTLSize(width: Int(region.size.width), height: Int(region.size.height), depth: 1)
        let bytesPerPixel = 4
        let bytesPerRow = sourceSize.width * bytesPerPixel
        let bytesPerImage = sourceSize.height * bytesPerRow
        guard let readBuffer = texture.device.makeBuffer(length: bytesPerImage, options: .storageModeShared) else {
            return nil
        }
        let blitEncoder = commandBuffer?.makeBlitCommandEncoder()
        blitEncoder?.copy(from: texture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: sourceOrigin, sourceSize: sourceSize, to: readBuffer, destinationOffset: 0, destinationBytesPerRow: bytesPerRow, destinationBytesPerImage: bytesPerImage)
        blitEncoder?.endEncoding()
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        return readBuffer
    }
    
    func drawQuad(in view: MTKView, with commandBuffer: MTLCommandBuffer?) {
        guard let renderPassDesriptor = view.currentRenderPassDescriptor else {
            return
        }
        let commanderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDesriptor)
        commanderEncoder?.setRenderPipelineState(pipelineState)
        
        let vertices = [
            //top-left
            Vertext(position: [-1.0,  1.0, 1.0, 1.0], color: [1.0, 0.0, 1.0, 1.0]),
            //bottom-left
            Vertext(position: [-1.0, -1.0, 1.0, 1.0], color: [1.0, 0.0, 0.0, 1.0]),
            //bottom-right
            Vertext(position: [ 1.0, -1.0, 1.0, 1.0], color: [1.0, 1.0, 0.0, 1.0]),
            //top-left
            Vertext(position: [-1.0,  1.0, 1.0, 1.0], color: [1.0, 0.0, 1.0, 1.0]),
            //bottom-right
            Vertext(position: [ 1.0, -1.0, 1.0, 1.0], color: [1.0, 1.0, 0.0, 1.0]),
            //top-right
            Vertext(position: [ 1.0,  1.0, 1.0, 1.0], color: [0.0, 1.0, 0.0, 1.0]),
        ]
        
        let vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertext>.stride * vertices.count)
        commanderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        commanderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        
        commanderEncoder?.endEncoding()
    }
}


extension Renderer: MTKViewDelegate {
    func draw(in view: MTKView) {
        let commanderBuffer = commandQueue.makeCommandBuffer()
        if !isDrawForReadThisFrame {
            drawQuad(in: view, with: commanderBuffer)
        }
        guard let drawable = view.currentDrawable else {
            return
        }
        commanderBuffer?.present(drawable)
        commanderBuffer?.commit()
        isDrawForReadThisFrame = false
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}

