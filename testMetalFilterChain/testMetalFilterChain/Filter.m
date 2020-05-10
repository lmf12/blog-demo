//
//  Filter.m
//  testMetalFilterChain
//
//  Created by Lyman Li on 2020/5/5.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import "Filter.h"

@interface Filter ()

@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id <MTLBuffer> vertixBuffer;
@property (nonatomic, strong) id <MTLTexture> targetTexture;
@property (nonatomic, strong) MTLRenderPassDescriptor *renderPassDescriptor;

@property (nonatomic, strong) id <MTLTexture> overlayTexture;
@property (nonatomic, assign) Constants constans;

@property (nonatomic, assign) CVPixelBufferRef renderTarget;

@end

@implementation Filter

- (void)dealloc {
    if (_renderTarget) {
        CVPixelBufferRelease(_renderTarget);
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

#pragma mark - Public

- (id <MTLTexture>)applyEffectWithTexture:(id <MTLTexture>)texture {
    // 构建常量结构体，存入矩阵
    // 在 shader 中，本来矩阵是用于对顶点坐标的变换，
    // 但是这里用来对d贴纸纹理坐标变换，所以需要先求逆
    Constants constants;
    constants.matrix = matrix_invert(self.matrix);
    
    [self setupOverlayTexture];
    [self setupTargetTextureWithSize:CGSizeMake(texture.width, texture.height)];
    
    id <MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    MTLRenderPassDescriptor *renderPassDescriptor = self.renderPassDescriptor;
    
    renderPassDescriptor.colorAttachments[0].texture = self.targetTexture;
    id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    MTLViewport viewport = (MTLViewport){0.0, 0.0, texture.width, texture.height, -1.0, 1.0};
    [renderEncoder setViewport:viewport];
    [renderEncoder setRenderPipelineState:self.pipelineState];
    [renderEncoder setVertexBuffer:self.vertixBuffer
                            offset:0
                           atIndex:0];
    [renderEncoder setVertexBytes:&constants length:sizeof(Constants) atIndex:1];
    [renderEncoder setFragmentTexture:texture
                              atIndex:0];
    [renderEncoder setFragmentTexture:self.overlayTexture
                              atIndex:1];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip
                      vertexStart:0
                      vertexCount:4];
    
    [renderEncoder endEncoding];
    [commandBuffer commit];
    
    return self.targetTexture;
}

#pragma mark - Private

- (void)commonInit {
    self.matrix = matrix_identity_float4x4;
    
    [self setupDevice];
    [self setupPipeline];
    [self setupVertex];
    [self setupRenderPassDescriptor];
}

// 初始化设备
- (void)setupDevice {
    self.device = MTLCreateSystemDefaultDevice();
}

// 初始化渲染管线
- (void)setupPipeline {
    id <MTLLibrary> library = [self.device newDefaultLibrary];
    id <MTLFunction> vertexFunction = [library newFunctionWithName:@"overlayVertexShader"];
    id <MTLFunction> fragmentFunction = [library newFunctionWithName:@"overlayFragmentShader"];
    
    MTLRenderPipelineDescriptor *descriptor = [[MTLRenderPipelineDescriptor alloc] init];
    descriptor.vertexFunction = vertexFunction;
    descriptor.fragmentFunction = fragmentFunction;
    descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    self.pipelineState = [self.device newRenderPipelineStateWithDescriptor:descriptor
                                                                     error:NULL];
    self.commandQueue = [self.device newCommandQueue];
}

// 初始化顶点缓存
- (void)setupVertex {
    static const Vertex vertices[] = {
        {{-1.0, -1.0, 0.0, 1.0}, {0.0, 1.0}},
        {{-1.0, 1.0, 0.0, 1.0}, {0.0, 0.0}},
        {{1.0, -1.0, 0.0, 1.0}, {1.0, 1.0}},
        {{1.0, 1.0, 0.0, 1.0}, {1.0, 0.0}}
    };
    self.vertixBuffer = [self.device newBufferWithBytes:vertices
                                                 length:sizeof(vertices)
                                                options:MTLResourceStorageModeShared];
}

// 初始化渲染描述
- (void)setupRenderPassDescriptor {
    self.renderPassDescriptor = [MTLRenderPassDescriptor new];
    self.renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0);
    self.renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    self.renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
}

/// 初始化贴纸纹理
- (void)setupOverlayTexture {
    MTKTextureLoader *textureLoader = [[MTKTextureLoader alloc] initWithDevice:self.device];
    NSDictionary *options = @{
        MTKTextureLoaderOptionSRGB : @NO
    };
    self.overlayTexture = [textureLoader newTextureWithCGImage:self.overlayImage.CGImage
                                                       options:options
                                                         error:NULL];
}

/// 初始化目标纹理
- (void)setupTargetTextureWithSize:(CGSize)size {
    CVMetalTextureCacheRef textureCache;
    CVReturn status = CVMetalTextureCacheCreate(kCFAllocatorDefault,
                                                nil,
                                                self.device,
                                                nil,
                                                &textureCache);
    if (status != kCVReturnSuccess) {
        NSLog(@"texture cache create fail");
        return;
    }
    
    CFDictionaryRef dictionary;
    CFMutableDictionaryRef attrs;
    dictionary = CFDictionaryCreate(kCFAllocatorDefault,
                                    nil,
                                    nil,
                                    0,
                                    &kCFTypeDictionaryKeyCallBacks,
                                    &kCFTypeDictionaryValueCallBacks);
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                      1,
                                      &kCFTypeDictionaryKeyCallBacks,
                                      &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(attrs,
                         kCVPixelBufferIOSurfacePropertiesKey,
                         dictionary);
    
    if (!self.renderTarget) {
        CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height,
                            kCVPixelFormatType_32BGRA,
                            attrs,
                            &_renderTarget);
    }
    
    size_t width = CVPixelBufferGetWidthOfPlane(self.renderTarget, 0);
    size_t height = CVPixelBufferGetHeightOfPlane(self.renderTarget, 0);
    MTLPixelFormat pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    CVMetalTextureRef texture = nil;
    status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       textureCache,
                                                       self.renderTarget,
                                                       nil,
                                                       pixelFormat,
                                                       width,
                                                       height,
                                                       0,
                                                       &texture);
    if(status == kCVReturnSuccess) {
        self.targetTexture = CVMetalTextureGetTexture(texture);
        CFRelease(texture);
    } else {
        NSLog(@"render target create fail");
    }
    
    CFRelease(textureCache);
    CFRelease(attrs);
    CFRelease(dictionary);
}

@end
