//
//  GLKitViewController.m
//  testOpenGLESRender
//
//  Created by Lyman on 2019/2/21.
//  Copyright © 2019 Lyman Li. All rights reserved.
//

#import <GLKit/GLKit.h>

#import "GLKitViewController.h"

/**
 定义顶点类型
 */
typedef struct {
    GLKVector3 positionCoord; // (X, Y, Z)
    GLKVector2 textureCoord; // (U, V)
} SenceVertex;

@interface GLKitViewController () <GLKViewDelegate>

@property (nonatomic, strong) GLKView *glkView;
@property (nonatomic, strong) GLKBaseEffect *baseEffect;

@property (nonatomic, assign) SenceVertex *vertices; // 顶点数组

@end

@implementation GLKitViewController

- (void)dealloc {
    if ([EAGLContext currentContext] == self.glkView.context) {
        [EAGLContext setCurrentContext:nil];
    }
    // C语言风格的数组，需要手动释放
    if (_vertices) {
        free(_vertices);
        _vertices = nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self commonInit];
    // display 会触发 glkView:drawInRect: 方法，并在触发这个方法后，内部还会调用 presentRenderbuffer 来将绑定的渲染缓存呈现到屏幕上
    [self.glkView display];
}

- (void)commonInit {
    // 创建上下文，使用 2.0 版本
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    // 创建顶点数组
    self.vertices = malloc(sizeof(SenceVertex) * 4); // 4 个顶点
    
    self.vertices[0] = (SenceVertex){{-1, 1, 0}, {0, 1}}; // 左上角
    self.vertices[1] = (SenceVertex){{-1, -1, 0}, {0, 0}}; // 左下角
    self.vertices[2] = (SenceVertex){{1, 1, 0}, {1, 1}}; // 右上角
    self.vertices[3] = (SenceVertex){{1, -1, 0}, {1, 0}}; // 右下角
    
    // 初始化 GLKView
    CGRect frame = CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width); // 为了 OpenGL 坐标系不被拉伸，这里设置为正方形
    self.glkView = [[GLKView alloc] initWithFrame:frame context:context];
    self.glkView.backgroundColor = [UIColor clearColor];
    self.glkView.delegate = self;
    
    [self.view addSubview:self.glkView];
    
    // 设置 glkView 的上下文为当前上下文
    [EAGLContext setCurrentContext:self.glkView.context];
    
    // 通过 GLKTextureLoader 来加载纹理，并存放在 GLKBaseEffect 中
    NSString *imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"sample.jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath]; // 这里如果用 imageNamed 来读取图片，在反复加载纹理的时候，会出现倒置的错误

    NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft : @(YES)}; // 消除 UIKit 和 GLKit 的坐标差异，否则会上下颠倒
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:[image CGImage]
                                                               options:options
                                                                 error:NULL];
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.texture2d0.name = textureInfo.name;
    self.baseEffect.texture2d0.target = textureInfo.target;
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.baseEffect prepareToDraw];
    
    // 创建顶点缓存
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);  // 步骤一：生成
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);  // 步骤二：绑定
    GLsizeiptr bufferSizeBytes = sizeof(SenceVertex) * 4;
    glBufferData(GL_ARRAY_BUFFER, bufferSizeBytes, self.vertices, GL_STATIC_DRAW);  // 步骤三：缓存数据
    
    // 设置顶点数据
    glEnableVertexAttribArray(GLKVertexAttribPosition);  // 步骤四：启用或禁用
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, positionCoord));  // 步骤五：设置指针
    
    // 设置纹理数据
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);  // 步骤四：启用或禁用
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, textureCoord));  // 步骤五：设置指针
    
    // 开始绘制
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);  // 步骤六：绘图
    
    // 删除顶点缓存
    glDeleteBuffers(1, &vertexBuffer);  // 步骤七：删除
    vertexBuffer = 0;
}

@end
