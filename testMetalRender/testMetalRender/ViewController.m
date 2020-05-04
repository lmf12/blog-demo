//
//  ViewController.m
//  testMetalRender
//
//  Created by Lyman Li on 2020/5/3.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import <MetalKit/MetalKit.h>

#import "ViewController.h"

typedef struct {
    vector_float4 position;
    vector_float4 texCoords;
} Vertex;

@interface ViewController () <MTKViewDelegate>

@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id <MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id <MTLBuffer> vertixBuffer;
@property (nonatomic, strong) id <MTLTexture> texture;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupMTKView];
    [self setupPipeline];
    [self setupVertex];
    [self setupTexture];
}

/// 初始化 MTKView
- (void)setupMTKView {
    self.mtkView = [[MTKView alloc] initWithFrame:CGRectMake(0,
                                                             100,
                                                             self.view.frame.size.width,
                                                             self.view.frame.size.width)
                                           device:MTLCreateSystemDefaultDevice()];
    self.mtkView.delegate = self;
    [self.view addSubview:self.mtkView];
}

/// 初始化渲染管线
- (void)setupPipeline {
    // 获取 library
    id <MTLLibrary> library = [self.mtkView.device newDefaultLibrary];
    // 读取着色器程序
    id <MTLFunction> vertexFunction = [library newFunctionWithName:@"vertexShader"];
    id <MTLFunction> fragmentFunction = [library newFunctionWithName:@"fragmentShader"];
    
    // 渲染管线描述
    MTLRenderPipelineDescriptor *descriptor = [[MTLRenderPipelineDescriptor alloc] init];
    descriptor.vertexFunction = vertexFunction;
    descriptor.fragmentFunction = fragmentFunction;
    descriptor.colorAttachments[0].pixelFormat = self.mtkView.colorPixelFormat;
    
    // 创建渲染管线
    self.pipelineState = [self.mtkView.device newRenderPipelineStateWithDescriptor:descriptor
                                                                             error:NULL];
    // 创建渲染指令队列
    self.commandQueue = [self.mtkView.device newCommandQueue];
}

/// 创建顶点数据
- (void)setupVertex {
    static const Vertex vertices[] = {
        {{-1.0, -1.0, 0.0, 1.0}, {0.0, 1.0}},
        {{-1.0, 1.0, 0.0, 1.0}, {0.0, 0.0}},
        {{1.0, -1.0, 0.0, 1.0}, {1.0, 1.0}},
        {{1.0, 1.0, 0.0, 1.0}, {1.0, 0.0}}
    };
    self.vertixBuffer = [self.mtkView.device newBufferWithBytes:vertices
                                                         length:sizeof(vertices)
                                                        options:MTLResourceStorageModeShared];
}

/// 初始化纹理
- (void)setupTexture {
    MTKTextureLoader *textureLoader = [[MTKTextureLoader alloc] initWithDevice:self.mtkView.device];
    UIImage *image = [UIImage imageNamed:@"sample.jpg"];
    NSDictionary *options = @{
        MTKTextureLoaderOptionSRGB : @NO
    };
    self.texture = [textureLoader newTextureWithCGImage:image.CGImage
                                                options:options
                                                  error:NULL];
}

#pragma mark - MTKViewDelegate

- (void)drawInMTKView:(MTKView *)view {
    id <MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    MTLRenderPassDescriptor *renderPassDescriptor = self.mtkView.currentRenderPassDescriptor;
    
    if (renderPassDescriptor) {
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        MTLViewport viewport = (MTLViewport){0.0, 0.0, self.mtkView.drawableSize.width, self.mtkView.drawableSize.height, -1.0, 1.0}; // -1.0 是 z 轴 near， 1.0 是 z 轴 far
        // 设置视口大小
        [renderEncoder setViewport:viewport];
        // 设置渲染管线
        [renderEncoder setRenderPipelineState:self.pipelineState];
        // 设置顶点缓存
        [renderEncoder setVertexBuffer:self.vertixBuffer
                                offset:0
                               atIndex:0];
        // 设置纹理
        [renderEncoder setFragmentTexture:self.texture
                                  atIndex:0];
        // 绘制命令
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip
                          vertexStart:0
                          vertexCount:4];
        
        [renderEncoder endEncoding];
        [commandBuffer presentDrawable:self.mtkView.currentDrawable];
    }
    [commandBuffer commit];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
}

@end
