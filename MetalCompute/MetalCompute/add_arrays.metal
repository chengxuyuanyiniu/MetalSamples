#include <metal_stdlib>
using namespace metal;

// 计算 kernel，使用 GPU 进行并行计算
kernel void add_arrays(device float* A [[buffer(0)]],  // 输入数组 A
                       device float* B [[buffer(1)]],  // 输入数组 B
                       device float* C [[buffer(2)]],  // 输出数组 C
                       uint id [[thread_position_in_grid]]) { // 线程索引
    C[id] = A[id] + B[id]; // 每个 GPU 线程计算一个元素
}
