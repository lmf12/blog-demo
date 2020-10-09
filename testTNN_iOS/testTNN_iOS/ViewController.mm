//
//  ViewController.m
//  testTNN_iOS
//
//  Created by Lyman Li on 2020/10/4.
//

#import <MetalKit/MetalKit.h>
#import <tnn/tnn.h>

#import "UIImage+Resize.h"

#import "ViewController.h"

using namespace std;
using namespace TNN_NS;

@interface ViewController ()

@property (nonatomic, assign) TNN *network;
@property (nonatomic, assign) shared_ptr<Instance> networkInstance;

@property (nonatomic, strong) UIImage *originImage;
@property (nonatomic, strong) UIImage *resultImage;
@property (nonatomic, strong) UIImageView *resultImageView;

@property (nonatomic, strong) id<MTLLibrary> library;

@end

@implementation ViewController

- (void)dealloc {
    [self releaseNetwork];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self commonInit];
}

#pragma mark - Private

- (void)commonInit {
    [self setupUI];
    [self setupTNN];
    [self updateUI];
}

/// 释放网络
- (void)releaseNetwork {
    if (_network) {
        delete _network;
        _network = nullptr;
    }
    _networkInstance = nullptr;
}

#pragma mark - UI

/// 初始化UI
- (void)setupUI {
    int randomNum = arc4random() % 5 + 1;
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"image%d.jpg", randomNum]];
    CGFloat imageWidth = self.view.frame.size.width / 2;
    UIImageView *originImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 150, imageWidth, imageWidth * image.size.height / image.size.width)];
    self.resultImageView = [[UIImageView alloc] initWithFrame:CGRectMake(imageWidth, 150, imageWidth, imageWidth * image.size.height / image.size.width)];
    
    [self.view addSubview:originImageView];
    [self.view addSubview:self.resultImageView];
    
    originImageView.image = image;
    self.originImage = image;
}

/// 刷新UI，将结果显示
- (void)updateUI {
    self.resultImageView.image = self.resultImage;
}

#pragma mark - TNN

/// 初始化 TNN 流程
- (void)setupTNN {
    [self decodeModel];
    [self bulidNetwork];
    [self preprocess];
    [self process];
    [self postprocess];
}

/// 模型解析
- (void)decodeModel {
    self.network = new TNN();
    
    // 获取模型路径
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"G_8_GRAY2RGB_256" ofType:@"tnnmodel"];
    NSString *protoPath = [[NSBundle mainBundle] pathForResource:@"G_8_GRAY2RGB_256" ofType:@"tnnproto"];
    
    // 读取模型数据
    string protoContent = [NSString stringWithContentsOfFile:protoPath
                                                    encoding:NSUTF8StringEncoding
                                                       error:nil].UTF8String;
    NSData *modelData = [NSData dataWithContentsOfFile:modelPath];
    string modelContent = [modelData length] > 0 ? string((const char *)[modelData bytes], [modelData length]) : "";
    
    if (protoContent.size() <= 0 || modelContent.size() <= 0) {
        NSLog(@"Error: proto or model path is invalid");
        return;
    }
    
    // 创建模型配置
    ModelConfig modelConfig;
    modelConfig.model_type = MODEL_TYPE_TNN; // 指定模型类型
    modelConfig.params = {protoContent, modelContent};
    
    // 解析
    Status status = self.network->Init(modelConfig);
    
    if (status != TNN_OK) {
        NSLog(@"Error: tnn init failed");
        return;
    }
}

/// 构建网络
- (void)bulidNetwork {
    // 获取默认 metallib 路径
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"tnn" ofType:@"bundle"];
    NSString *libPath = [bundlePath stringByAppendingPathComponent:@"tnn.metallib"];
    
    // 读取自定义 metallib
    NSString *customLibPath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"metallib"];
    self.library = [MTLCreateSystemDefaultDevice() newLibraryWithFile:customLibPath
                                                                error:NULL];
    
    // 创建网络实例
    Status status;
    NetworkConfig networkConfig;
    networkConfig.device_type = DEVICE_METAL;  // 使用 metal
    networkConfig.library_path = {libPath.UTF8String};
    self.networkInstance = self.network->CreateInst(networkConfig, status);
    
    if (status != TNN_OK) {
        NSLog(@"Error: create instance failed");
        return;
    }
}

/// 预处理
- (void)preprocess {
    // inputBlobs
    BlobMap inputBlobs;
    Status status = self.networkInstance->GetAllInputBlobs(inputBlobs);
    if (status != TNN_OK) {
        NSLog(@"Error: get input blobs failed");
        return;
    }
    Blob *networkInput = inputBlobs.begin()->second;
    
    // 读取模型的输入宽高
    auto dims = networkInput->GetBlobDesc().dims;
    int width = dims[3];
    int height = dims[2];
    
    // 读取图片数据
    UIImage *image = self.originImage;
    image = [image resizeWithSize:CGSizeMake(width, height)];
    MTKTextureLoader *textureLoader = [[MTKTextureLoader alloc] initWithDevice:MTLCreateSystemDefaultDevice()];
    NSDictionary *options = @{
        MTKTextureLoaderOptionSRGB : @NO
    };
    id<MTLTexture> texture = [textureLoader newTextureWithCGImage:image.CGImage options:options error:NULL];
    
    /// 以下的步骤二选一，效果一致
    // 默认
//    [self defaultPreprocessWithInput:networkInput texture:texture];
    // 自定义
    [self customPreprocessWithInput:networkInput texture:texture];
}

/// 默认预处理
- (void)defaultPreprocessWithInput:(Blob *)networkInput
                           texture:(id<MTLTexture>)texture {
    Mat inputMat = {DEVICE_METAL, tnn::N8UC4, (__bridge void*)texture};
    shared_ptr<BlobConverter> preprocessor = make_shared<BlobConverter>(networkInput);
    
    id<MTLCommandQueue> commandQueue = [self fetchCommandQueue];
    MatConvertParam input_cvt_param;
    input_cvt_param.scale = {2.0 / 255, 2.0 / 255, 2.0 / 255, 0};
    input_cvt_param.bias  = {-1.0, -1.0, -1.0, 0};
    input_cvt_param.reverse_channel = true;
    preprocessor->ConvertFromMatAsync(inputMat, input_cvt_param, (__bridge void*)commandQueue);
}

/// 自定义预处理
- (void)customPreprocessWithInput:(Blob *)networkInput
                          texture:(id<MTLTexture>)texture {
    id<MTLCommandQueue> commandQueue = [self fetchCommandQueue];
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    [commandBuffer enqueue];
    
    id<MTLBuffer> blobBuffer = (__bridge id<MTLBuffer>)(void *)networkInput->GetHandle().base;
    NSUInteger blobOffset = (NSUInteger)networkInput->GetHandle().bytes_offset;
    
    id<MTLComputeCommandEncoder> encoder = [commandBuffer computeCommandEncoder];
    
    id<MTLComputePipelineState> pipelineState = [self computePipelineStateWithLibrary:self.library functionName:@"test_preprocess"];
    [encoder setComputePipelineState:pipelineState];
    [encoder setTexture:texture atIndex:0];
    [encoder setBuffer:blobBuffer offset:blobOffset atIndex:0];
    
    NSUInteger width = pipelineState.threadExecutionWidth;
    NSUInteger height = pipelineState.maxTotalThreadsPerThreadgroup / width;
    MTLSize groupThreads = {width, height, (NSUInteger)1};
    MTLSize groups = {((texture.width + width - 1) / width), ((texture.height + height - 1) / height), 1};
    [encoder dispatchThreadgroups:groups threadsPerThreadgroup:groupThreads];
    [encoder endEncoding];
    
    [commandBuffer commit];
    [commandBuffer waitUntilScheduled];
}

/// 执行网络
- (void)process {
    Status status = self.networkInstance->ForwardAsync([]{});
    if (status != TNN_OK) {
        NSLog(@"Error: network process failed");
        return;
    }
}

/// 后处理
- (void)postprocess {
    // outputBlobs
    BlobMap outputBlobs;
    Status status = self.networkInstance->GetAllOutputBlobs(outputBlobs);
    if (status != TNN_OK) {
        NSLog(@"Error: get output blobs failed");
        return;
    }
    Blob *networkOutput = outputBlobs.begin()->second;
    
    // 读取模型的输出宽高
    auto dims = networkOutput->GetBlobDesc().dims;
    int width = dims[3];
    int height = dims[2];
    
    // 创建输出纹理
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
    textureDescriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget;
    textureDescriptor.width = width;
    textureDescriptor.height = height;
    id<MTLTexture> resultTexture = [MTLCreateSystemDefaultDevice() newTextureWithDescriptor:textureDescriptor];
    
    /// 以下的步骤二选一，效果一致
    // 默认
//    [self defaultPostprocessWithOutput:networkOutput texture:resultTexture];
    // 自定义
    [self customPostprocessWithOutput:networkOutput texture:resultTexture];
    
    // 将结果保存
    self.resultImage = [self imageWithMTLTexture:resultTexture];
}

/// 默认后处理
- (void)defaultPostprocessWithOutput:(Blob *)networkOutput
                             texture:(id<MTLTexture>)texture {
    Mat outputMat = {DEVICE_METAL, tnn::N8UC4, (__bridge void*)texture};
    shared_ptr<BlobConverter> postprocessor = make_shared<BlobConverter>(networkOutput);
    
    id<MTLCommandQueue> commandQueue = [self fetchCommandQueue];
    MatConvertParam output_cvt_param;
    output_cvt_param.scale = {255 / 2.0, 255 / 2.0, 255 / 2.0, 0};
    output_cvt_param.bias  = {255 / 2.0, 255 / 2.0, 255 / 2.0, 255};
    output_cvt_param.reverse_channel = true;
    postprocessor->ConvertToMatAsync(outputMat, output_cvt_param, (__bridge void*)commandQueue);
}

/// 自定义后处理
- (void)customPostprocessWithOutput:(Blob *)networkOutput
                            texture:(id<MTLTexture>)texture {
    id<MTLCommandQueue> commandQueue = [self fetchCommandQueue];
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    [commandBuffer enqueue];
    
    id<MTLBuffer> blobBuffer = (__bridge id<MTLBuffer>)(void *)networkOutput->GetHandle().base;
    NSUInteger blobOffset = (NSUInteger)networkOutput->GetHandle().bytes_offset;
        
    id<MTLComputeCommandEncoder> encoder = [commandBuffer computeCommandEncoder];
    
    id<MTLComputePipelineState> pipelineState = [self computePipelineStateWithLibrary:self.library functionName:@"test_postprocess"];
    [encoder setComputePipelineState:pipelineState];
    [encoder setTexture:texture atIndex:0];
    [encoder setBuffer:blobBuffer offset:blobOffset atIndex:0];
    
    NSUInteger width = pipelineState.threadExecutionWidth;
    NSUInteger height = pipelineState.maxTotalThreadsPerThreadgroup / width;
    MTLSize groupThreads = {width, height, (NSUInteger)1};
    MTLSize groups = {((texture.width + width - 1) / width), ((texture.height + height - 1) / height), 1};
    [encoder dispatchThreadgroups:groups threadsPerThreadgroup:groupThreads];
    [encoder endEncoding];
    
    [commandBuffer commit];
    [commandBuffer waitUntilScheduled];
}

#pragma mark - Utils

/// 获取网络实例中的 CommandQueue
- (id<MTLCommandQueue>)fetchCommandQueue {
    void *command_queue_ptr = nullptr;
    Status status = self.networkInstance->GetCommandQueue(&command_queue_ptr);
    if (status != TNN_OK || !command_queue_ptr) {
        NSLog(@"Error: get command queue failed");
        return nil;
    }
    
    return (__bridge id<MTLCommandQueue>)command_queue_ptr;
}

/// Metal纹理 转 UIImage
- (UIImage *)imageWithMTLTexture:(id<MTLTexture>)texture {
    NSDictionary *option = @{
        kCIImageColorSpace : (__bridge id)CGColorSpaceCreateDeviceRGB(),
        kCIContextOutputPremultiplied : @YES,
        kCIContextUseSoftwareRenderer : @NO
    };
    CIImage *image = [CIImage imageWithMTLTexture:texture options:option];
    image = [image imageByApplyingTransform:CGAffineTransformMakeScale(1, -1)];
    
    CIContext *context = [[CIContext alloc] init];
    CGImageRef imageRef = [context createCGImage:image fromRect:image.extent];

    UIImage *uiimage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return uiimage;
}

/// 根据 library 和 functionName 获取 pipelineState
- (id<MTLComputePipelineState>)computePipelineStateWithLibrary:(id<MTLLibrary>)library functionName:(NSString *)functionName {
    id <MTLFunction> function = [library newFunctionWithName:functionName];
    return function ? [library.device newComputePipelineStateWithFunction:function error:nil] : nil;
}

@end
