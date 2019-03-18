//
//  ObjectViewController.m
//  testOpenGLESLoadOBJ
//
//  Created by Lyman Li on 2019/3/17.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import <GLKit/GLKit.h>

#import "WavefrontOBJTool.h"

#import "ObjectViewController.h"

@interface ObjectViewController () <GLKViewDelegate>

@property (nonatomic, strong) GLKView *glkView;
@property (nonatomic, strong) GLKBaseEffect *baseEffect;

@property (nonatomic, assign) SenceVertex *vertices;
@property (nonatomic, assign) NSInteger vertexCount;

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSInteger angle;

@end

@implementation ObjectViewController

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
    
    [self.displayLink invalidate];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.angle = 0;
    self.view.backgroundColor = [UIColor whiteColor];
    [self commonInit];
    
    // 显示loading
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [indicatorView startAnimating];
    indicatorView.center = self.view.center;
    [self.view addSubview:indicatorView];
    
    // 加载模型数据
    WavefrontOBJTool *tool = [[WavefrontOBJTool alloc] init];
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/model/IronMan.obj"];
    __weak ObjectViewController *weakSelf = self;
    [tool loadDataFromObj:path completion:^(SenceVertex *vertexs, NSInteger count) {
        // 如果页面已经退出，释放数据
        if (!weakSelf) {
            free(vertexs);
        }
        
        // 隐藏loading
        dispatch_async(dispatch_get_main_queue(), ^{
            [indicatorView removeFromSuperview];
        });
        
        // 数值赋值
        weakSelf.vertices = vertexs;
        weakSelf.vertexCount = count;
        
        // 开始渲染和定时旋转
        weakSelf.displayLink = [CADisplayLink displayLinkWithTarget:weakSelf selector:@selector(update)];
        [weakSelf.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }];
}

- (void)commonInit {
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    CGRect frame = CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width);
    self.glkView = [[GLKView alloc] initWithFrame:frame context:context];
    self.glkView.backgroundColor = [UIColor clearColor];
    self.glkView.delegate = self;
    
    self.glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
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
    
    self.baseEffect.light0.enabled = YES;
    self.baseEffect.light0.diffuseColor = GLKVector4Make(1, 1, 1, 1);
    self.baseEffect.light0.position = GLKVector4Make(-0.5, -0.5, 1, 1);
    
    // 场景平移和缩放
    GLKMatrix4 matrix = GLKMatrix4MakeTranslation(0, -0.7, 0);
    matrix = GLKMatrix4Scale(matrix, 0.006, 0.006, 0.006);
    self.baseEffect.transform.projectionMatrix = matrix;
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.baseEffect prepareToDraw];
    
    glEnable(GL_DEPTH_TEST);
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    GLsizeiptr bufferSizeBytes = sizeof(SenceVertex) * self.vertexCount;
    glBufferData(GL_ARRAY_BUFFER, bufferSizeBytes, self.vertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, positionCoord));
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, textureCoord));
    
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, normal));
    
    glDrawArrays(GL_TRIANGLES, 0, (int)self.vertexCount);
    
    glDeleteBuffers(1, &vertexBuffer);
    vertexBuffer = 0;
}

#pragma mark - update

- (void)update {
    self.angle = (self.angle + 5) % 360;
    self.baseEffect.transform.modelviewMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(self.angle), 0, 1, 0);
    [self.glkView display];
}

@end
