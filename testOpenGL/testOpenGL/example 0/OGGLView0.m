//
//  OGGLView0.m
//  testOpenGL
//
//  Created by Lyman Li on 2018/3/22.
//  Copyright © 2018年 Lyman Li. All rights reserved.
//

#import <OpenGLES/ES3/gl.h>

#import "OGGLView0.h"

@interface OGGLView0 ()

@property (nonatomic, strong) EAGLContext *context;

@end

@implementation OGGLView0

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
        [EAGLContext setCurrentContext:_context];
        
        [self test];
    }
    return self;
}

- (void)dealloc {
    
    if ([EAGLContext currentContext] == _context) {
        [EAGLContext setCurrentContext:nil];
    }
}

+ (Class)layerClass {
    
    return [CAEAGLLayer class];
}

- (void)test {
    
    [self testPrintInfo];
    [self testDrawBackground];
}

- (void)testPrintInfo {
    
    NSLog(@"厂家 = %s", glGetString(GL_VENDOR));
    NSLog(@"渲染器 = %s", glGetString(GL_RENDERER));
    NSLog(@"ES版本 = %s", glGetString(GL_VERSION));
    NSLog(@"拓展功能 = %s", glGetString(GL_EXTENSIONS));
}

- (void)testDrawBackground {
    
    GLuint renderBuffer;
    glGenRenderbuffers(1, &renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    
    GLuint frameBuffer;
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, frameBuffer);
    
    glClearColor(230 / 255.0, 222 / 255.0, 217 / 255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
