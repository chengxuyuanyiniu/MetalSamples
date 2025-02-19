import Metal

class Calculator {
    private var device: MTLDevice!
    private var computePS: MTLComputePipelineState!
    private var bufferA: MTLBuffer!
    private var bufferB: MTLBuffer!
    private var bufferC: MTLBuffer!
    private var commandQueue: MTLCommandQueue!
    private static let arrayLength = 1024
    init() {
        device = MTLCreateSystemDefaultDevice()
        if device == nil {
            fatalError("Can't create device")
        }
        guard let defaultLibrary = device.makeDefaultLibrary() else {
            fatalError("Can't make default library")
        }
        guard let addFunction = defaultLibrary.makeFunction(name: "add_arrays") else {
            fatalError("Can't make add_arrays function")
        }
        // Create a compute pipeline state
        computePS = try? device.makeComputePipelineState(function: addFunction)
        if computePS == nil {
            fatalError("Can't make compute pipeline")
        }
        commandQueue = device.makeCommandQueue()
        if commandQueue == nil {
            fatalError("Can't make command queue")
        }
    }
    
    func generateData() {
        let count = Self.arrayLength // 数组大小
        var A = (0..<count).map { Float($0) }
        var B = (0..<count).map { Float($0 * 2) }
        
        // 创建 Metal 设备缓冲区
        bufferA = device.makeBuffer(bytes: &A, length: MemoryLayout<Float>.size * count, options: .storageModeShared)!
        bufferB = device.makeBuffer(bytes: &B, length: MemoryLayout<Float>.size * count, options: .storageModeShared)!
        bufferC = device.makeBuffer(length: MemoryLayout<Float>.size * count, options: .storageModeShared)

    }
    
    func calculateOnGPU() {
        let commandBuffer = commandQueue.makeCommandBuffer()
        assert(commandBuffer != nil)
        let computeEncoder = commandBuffer?.makeComputeCommandEncoder()
        computeEncoder?.setComputePipelineState(computePS)
        assert(computeEncoder != nil)
        computeEncoder?.setBuffer(bufferA, offset: 0, index: 0)
        computeEncoder?.setBuffer(bufferB, offset: 0, index: 1)
        computeEncoder?.setBuffer(bufferC, offset: 0, index: 2)
        let threadsPerGrid = MTLSize(width: Self.arrayLength, height: 1, depth: 1)
        var threadsPerThreadgroup = computePS.maxTotalThreadsPerThreadgroup
        if threadsPerThreadgroup > Self.arrayLength {
            threadsPerThreadgroup = Self.arrayLength
        }
        computeEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: MTLSize(width: threadsPerThreadgroup, height: 1, depth: 1))
        computeEncoder?.endEncoding()
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        
        verifyResults()
    }
    
    func verifyResults() {
        let arrayA = bufferA.contents().bindMemory(to: Float.self, capacity: Self.arrayLength)
        let arrayB = bufferB.contents().bindMemory(to: Float.self, capacity: Self.arrayLength)
        let arrayC = bufferC.contents().bindMemory(to: Float.self, capacity: Self.arrayLength)
        for i in 0..<Self.arrayLength {
            if arrayA[i] + arrayB[i] != arrayC[i] {
                assert(false, "Compute error!")
            }
        }
    }
    
}
