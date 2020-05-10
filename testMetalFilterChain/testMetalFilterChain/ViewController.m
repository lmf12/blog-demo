//
//  ViewController.m
//  testMetalFilterChain
//
//  Created by Lyman Li on 2020/5/5.
//  Copyright © 2020 Lyman Li. All rights reserved.
//


#import <MetalKit/MetalKit.h>
#import <GLKit/GLKit.h>

#import "FilterChain.h"

#import "ViewController.h"

@interface ViewController () <MTKViewDelegate>

@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id <MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id <MTLBuffer> vertixBuffer;
@property (nonatomic, strong) id <MTLTexture> texture;

@property (nonatomic, strong) Filter *hatFilter;
@property (nonatomic, strong) Filter *glassesFilter;
@property (nonatomic, strong) Filter *maskFilter;

@property (nonatomic, strong) FilterChain *filterChain;

@property (weak, nonatomic) IBOutlet UIButton *hatButton;
@property (weak, nonatomic) IBOutlet UIButton *glassesButton;
@property (weak, nonatomic) IBOutlet UIButton *maskButton;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupMTKView];
    [self setupPipeline];
    [self setupVertex];
    [self setupTexture];
    [self setupHatFilter];
    [self setupGlassesFilter];
    [self setupMaskFilter];
    [self setupFilterChain];
    
    [self configButton:self.hatButton];
    [self configButton:self.glassesButton];
    [self configButton:self.maskButton];
    [self configButton:self.resetButton];
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
    id <MTLFunction> vertexFunction = [library newFunctionWithName:@"defaultVertexShader"];
    id <MTLFunction> fragmentFunction = [library newFunctionWithName:@"defaultFragmentShader"];
    
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

// 初始化滤镜链
- (void)setupFilterChain {
    self.filterChain = [[FilterChain alloc] init];
}

// 初始化帽子滤镜
- (void)setupHatFilter {
    self.hatFilter = [[Filter alloc] init];
    GLKMatrix4 matrix = GLKMatrix4Identity;
    matrix = GLKMatrix4Translate(matrix, 0.1, -0.2, 0);
    matrix = GLKMatrix4Scale(matrix, 0.6, 0.6, 1);
    
    self.hatFilter.matrix = [self matrixWithGLKMatrix:matrix];
    self.hatFilter.overlayImage = [UIImage imageNamed:@"hat.png"];
}

// 初始化眼镜滤镜
- (void)setupGlassesFilter {
    self.glassesFilter = [[Filter alloc] init];
    GLKMatrix4 matrix = GLKMatrix4Identity;
    matrix = GLKMatrix4RotateZ(matrix, -0.32);
    matrix = GLKMatrix4Translate(matrix, 0.08, 0.2, 0);
    matrix = GLKMatrix4Scale(matrix, 0.5, 0.5, 1);
    
    self.glassesFilter.matrix = [self matrixWithGLKMatrix:matrix];
    self.glassesFilter.overlayImage = [UIImage imageNamed:@"glasses.png"];
}

//  初始化口罩滤镜
- (void)setupMaskFilter {
    self.maskFilter = [[Filter alloc] init];
    GLKMatrix4 matrix = GLKMatrix4Identity;
    matrix = GLKMatrix4RotateZ(matrix, -0.32);
    matrix = GLKMatrix4Translate(matrix, 0.1, 0.35, 0);
    matrix = GLKMatrix4Scale(matrix, 0.5, 0.5, 1);
    
    self.maskFilter.matrix = [self matrixWithGLKMatrix:matrix];
    self.maskFilter.overlayImage = [UIImage imageNamed:@"mask.png"];
}

// 矩阵转换
- (matrix_float4x4)matrixWithGLKMatrix:(GLKMatrix4)matrix {
    matrix_float4x4 ret = (matrix_float4x4){
        simd_make_float4(matrix.m00, matrix.m01, matrix.m02, matrix.m03),
        simd_make_float4(matrix.m10, matrix.m11, matrix.m12, matrix.m13),
        simd_make_float4(matrix.m20, matrix.m21, matrix.m22, matrix.m23),
        simd_make_float4(matrix.m30, matrix.m31, matrix.m32, matrix.m33),
    };
    return ret;
}

// 配置按钮
- (void)configButton:(UIButton *)button {
    [button setBackgroundColor:[UIColor blackColor]];
    button.tintColor = [UIColor clearColor];
    button.layer.cornerRadius = 5.0;
    button.layer.masksToBounds = YES;
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor greenColor] forState:UIControlStateSelected];
}

#pragma mark - Action

- (IBAction)hatAction:(UIButton *)sender {
    if (sender.selected) {
        return;
    }
    sender.selected = YES;
    [self.filterChain addFilter:self.hatFilter];
}

- (IBAction)glassesAction:(UIButton *)sender {
    if (sender.selected) {
        return;
    }
    sender.selected = YES;
    [self.filterChain addFilter:self.glassesFilter];
}

- (IBAction)maskAction:(UIButton *)sender {
    if (sender.selected) {
        return;
    }
    sender.selected = YES;
    [self.filterChain addFilter:self.maskFilter];
}

- (IBAction)resetAction:(UIButton *)sender {
    self.hatButton.selected = NO;
    self.glassesButton.selected = NO;
    self.maskButton.selected = NO;
    
    [self.filterChain removeAllFilter];
}


#pragma mark - MTKViewDelegate

- (void)drawInMTKView:(MTKView *)view {
    // 添加滤镜
    id <MTLTexture> resultTexture = [self.filterChain applyEffectWithTexture:self.texture];
    
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
        [renderEncoder setFragmentTexture:resultTexture
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
