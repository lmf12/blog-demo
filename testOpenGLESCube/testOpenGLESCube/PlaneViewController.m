//
//  PlaneViewController.m
//  testOpenGLESCube
//
//  Created by Lyman Li on 2019/3/23.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import <GLKit/GLKit.h>

#import "PlaneViewController.h"

/**
 这部分的代码是延自于之前 GLKit 渲染的例子，并删除了之前的注释，只在新加的代码处添加注释，
 方便阅读时能更容易抓住重点。如果对于其余的代码有疑问，可以到原处查看注释：https://github.com/lmf12/blog-demo/blob/master/testOpenGLESRender/testOpenGLESRender/GLKitViewController.m
 */
typedef struct {
    GLKVector3 positionCoord;
    GLKVector2 textureCoord;
    GLKVector3 normal; // 因为我们需要用到光线，在每个顶点增加了法线向量
} SenceVertex;

@interface PlaneViewController () <GLKViewDelegate>

@property (nonatomic, strong) GLKView *glkView;
@property (nonatomic, strong) GLKBaseEffect *baseEffect;

@property (nonatomic, assign) SenceVertex *vertices;

@property (nonatomic, strong) CADisplayLink *displayLink; // 用于定时刷新屏幕
@property (nonatomic, assign) NSInteger angle;  // 当前旋转的角度

@end

@implementation PlaneViewController

- (void)dealloc {
    if ([EAGLContext currentContext] == self.glkView.context) {
        [EAGLContext setCurrentContext:nil];
    }
    if (_vertices) {
        free(_vertices);
        _vertices = nil;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // 若是在 dealloc 中停止，会导致循环引用
    [self.displayLink invalidate];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self commonInit];
    
    // 设置初始角度
    self.angle = 0;
    
    // 定时旋转模型
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)commonInit {
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    self.vertices = malloc(sizeof(SenceVertex) * 4);
    // 下面给每一个顶点添加了相同的法线
    self.vertices[0] = (SenceVertex){{-0.5, 0.5, 0}, {0, 1}, {0, 0, 1}};
    self.vertices[1] = (SenceVertex){{-0.5, -0.5, 0}, {0, 0}, {0, 0, 1}};
    self.vertices[2] = (SenceVertex){{0.5, 0.5, 0}, {1, 1}, {0, 0, 1}};
    self.vertices[3] = (SenceVertex){{0.5, -0.5, 0}, {1, 0}, {0, 0, 1}};
    
    CGRect frame = CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width);
    self.glkView = [[GLKView alloc] initWithFrame:frame context:context];
    self.glkView.backgroundColor = [UIColor clearColor];
    self.glkView.delegate = self;
    
    [self.view addSubview:self.glkView];
    
    [EAGLContext setCurrentContext:self.glkView.context];
    
    NSString *imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"sample.jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    
    NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft : @(YES)};
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:[image CGImage]
                                                               options:options
                                                                 error:NULL];
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.texture2d0.name = textureInfo.name;
    self.baseEffect.texture2d0.target = textureInfo.target;
    
    // 使用灯光
    self.baseEffect.light0.enabled = YES;
    self.baseEffect.light0.diffuseColor = GLKVector4Make(1, 1, 1, 1); // 漫反射光
//    self.baseEffect.light0.ambientColor = GLKVector4Make(1, 1, 1, 1); // 环境光
//    self.baseEffect.light0.specularColor = GLKVector4Make(1, 1, 1, 1); // 镜面光
    self.baseEffect.light0.position = GLKVector4Make(-0.5, -0.5, 1, 1);
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.baseEffect prepareToDraw];
    
    // 因为这里要一直刷新屏幕，绘制之前先将渲染层清空
    glClear(GL_COLOR_BUFFER_BIT);
    
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    GLsizeiptr bufferSizeBytes = sizeof(SenceVertex) * 4;
    glBufferData(GL_ARRAY_BUFFER, bufferSizeBytes, self.vertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, positionCoord));
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, textureCoord));
    
    // 启用法线向量数据，并传入
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, normal));
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDeleteBuffers(1, &vertexBuffer);
    vertexBuffer = 0;
}

#pragma mark - update

- (void)update {
    self.angle = (self.angle + 5) % 360;
    // GLKMathDegreesToRadians 将角度转化为弧度
    self.baseEffect.transform.modelviewMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(self.angle), 0, 1, 0); // 旋转模型
//    self.baseEffect.transform.projectionMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(self.angle), 0, 1, 0); // 旋转场景
    [self.glkView display];
}

@end
