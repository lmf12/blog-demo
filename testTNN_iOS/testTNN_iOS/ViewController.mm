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
    // 获取 metallib 路径
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"tnn" ofType:@"bundle"];
    NSString *libPath = [bundlePath stringByAppendingPathComponent:@"tnn.metallib"];
    
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
    
    Mat inputMat = {DEVICE_METAL, tnn::N8UC4, (__bridge void*)texture};
    shared_ptr<BlobConverter> preprocessor = make_shared<BlobConverter>(networkInput);
    
    id<MTLCommandQueue> commandQueue = [self fetchCommandQueue];
    MatConvertParam input_cvt_param;
    input_cvt_param.scale = {2.0 / 255, 2.0 / 255, 2.0 / 255, 0};
    input_cvt_param.bias  = {-1.0, -1.0, -1.0, 0};
    input_cvt_param.reverse_channel = true;
    preprocessor->ConvertFromMat(inputMat, input_cvt_param, (__bridge void*)commandQueue);
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
    
    Mat outputMat = {DEVICE_METAL, tnn::N8UC4, (__bridge void*)resultTexture};
    shared_ptr<BlobConverter> postprocessor = make_shared<BlobConverter>(networkOutput);
    
    id<MTLCommandQueue> commandQueue = [self fetchCommandQueue];
    MatConvertParam output_cvt_param;
    output_cvt_param.scale = {255 / 2.0, 255 / 2.0, 255 / 2.0, 0};
    output_cvt_param.bias  = {255 / 2.0, 255 / 2.0, 255 / 2.0, 255};
    output_cvt_param.reverse_channel = true;
    postprocessor->ConvertToMatAsync(outputMat, output_cvt_param, (__bridge void*)commandQueue);
    
    // 将结果保存
    self.resultImage = [self imageWithMTLTexture:resultTexture];
}

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

/// 释放网络
- (void)releaseNetwork {
    if (_network) {
        delete _network;
        _network = nullptr;
    }
    _networkInstance = nullptr;
}

@end
