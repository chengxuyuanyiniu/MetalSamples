
import Foundation
import MetalKit
import Metal
import simd

struct Vertext {
    var position: SIMD4<Float>
    var color: SIMD4<Float>
}

struct Uniforms {
    var projectionMatrix: matrix_float4x4
    var rotationMatrix: matrix_float4x4
}

class Renderer: NSObject {
    unowned var mtkView: MTKView
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var aspectRatio: CGFloat = 0.0
    
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
    
    func createPerspectiveMatrix(fov: Float, aspectRatio: Float, nearPlane: Float, farPlane: Float) -> simd_float4x4 {
        let tanHalfFov = tan(fov / 2.0);

        var matrix = simd_float4x4(0.0);
        matrix[0][0] = 1.0 / (aspectRatio * tanHalfFov);
        matrix[1][1] = 1.0 / (tanHalfFov);
        matrix[2][2] = farPlane / (farPlane - nearPlane);
        matrix[2][3] = 1.0;
        matrix[3][2] = -(farPlane * nearPlane) / (farPlane - nearPlane);
        
        return matrix;
    }
    
    func rotateX(angle: Float) -> matrix_float4x4 {
        let cosA = cos(angle)
        let sinA = sin(angle)

        let P = vector_float4(1, 0, 0, 0)
        let Q = vector_float4(0, cosA, sinA, 0)
        let R = vector_float4(0, -sinA, cosA, 0)
        let S = vector_float4(0, 0, 0, 1)

        return matrix_float4x4(P, Q, R, S)
    }
    
}


extension Renderer: MTKViewDelegate {
    func draw(in view: MTKView) {
        guard let renderPassDesriptor = view.currentRenderPassDescriptor else {
            return
        }
        let commanderBuffer = commandQueue.makeCommandBuffer()
        let commanderEncoder = commanderBuffer?.makeRenderCommandEncoder(descriptor: renderPassDesriptor)
        commanderEncoder?.setRenderPipelineState(pipelineState)
        
        let vertices = [
            Vertext(position: [-50, -50, 500, 1.0], color: [1.0, 0.0, 0.0, 1.0]),
            Vertext(position: [-50,  50, 500, 1.0], color: [1.0, 0.0, 0.0, 1.0]),
            Vertext(position: [ 50, -50, 500, 1.0], color: [1.0, 0.0, 0.0, 1.0]),
            Vertext(position: [-50,  50, 500, 1.0], color: [1.0, 0.0, 0.0, 1.0]),
            Vertext(position: [ 50, -50, 500, 1.0], color: [1.0, 0.0, 0.0, 1.0]),
            Vertext(position: [ 50,  50, 500, 1.0], color: [1.0, 0.0, 0.0, 1.0]),
        ]
        
        let projectionMatrix = createPerspectiveMatrix(fov: 45 * .pi / 180, aspectRatio: Float(aspectRatio), nearPlane: 100, farPlane: 1000)
        let rotationMatrix = rotateX(angle: 0)
        var uniform = Uniforms(projectionMatrix: projectionMatrix, rotationMatrix: rotationMatrix)
        commanderEncoder?.setVertexBytes(&uniform, length: MemoryLayout<Uniforms>.stride, index: 1)
        
        let vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertext>.stride * vertices.count)
        commanderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        commanderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        
        commanderEncoder?.endEncoding()
        
        guard let drawable = view.currentDrawable else {
            return
        }
        commanderBuffer?.present(drawable)
        commanderBuffer?.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        aspectRatio = size.width / size.height
    }
}

