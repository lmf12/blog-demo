
#include <metal_stdlib>

using namespace metal;

kernel void test_preprocess(texture2d<half, access::read> inputTexture [[texture(0)]],
                            device half4 *dst [[buffer(0)]],
                            ushort2 gid [[thread_position_in_grid]]) {
    int width = inputTexture.get_width();
    int height = inputTexture.get_height();
    if (any(gid >= ushort2(width, height))) {
        return;
    }

    const half4 in = inputTexture.read(uint2(gid));  // 这里读出来是 0 ~ 1，所以下面不用再除以 255，只需要转到 -1 ~ 1
    auto out = dst + (int)gid.y * width + (int)gid.x;
    
    *out = half4(in.x * 2 - 1,
                 in.y * 2 - 1,
                 in.z * 2 - 1,
                 0.0);
}

kernel void test_postprocess(texture2d<half, access::write> outputTexture [[texture(0)]],
                             const device half4 *src0 [[buffer(0)]],
                             uint2 gid [[thread_position_in_grid]]) {
    int width = outputTexture.get_width();
    int height = outputTexture.get_height();
    if (any(gid >= uint2(width, height))) {
        return;
    }
        
    half4 in = src0[(int)gid.y * width + (int)gid.x];
    in.x = (in.x + 1) / 2;
    in.y = (in.y + 1) / 2;
    in.z = (in.z + 1) / 2;
    in.w = 1;
    outputTexture.write(in, uint2(gid));
}
