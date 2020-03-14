//
//  CustomFilter.m
//  testVideoFilter
//
//  Created by Lyman Li on 2020/3/8.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import <GPUImage.h>

#import "MFPixelBufferHelper.h"

#import "CustomFilter.h"

@import OpenGLES;

@interface CustomFilter ()

@property (nonatomic, assign) CVPixelBufferRef resultPixelBuffer;
@property (nonatomic, strong) MFPixelBufferHelper *pixelBufferHelper;
@property (nonatomic, strong) CIContext *context;

@end

@implementation CustomFilter

- (void)dealloc {
    if (_pixelBuffer) {
        CVPixelBufferRelease(_pixelBuffer);
    }
    if (_resultPixelBuffer) {
        CVPixelBufferRelease(_resultPixelBuffer);
    }
}

#pragma mark - Accessors

- (void)setPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (_pixelBuffer &&
        pixelBuffer &&
        CFEqual(pixelBuffer, _pixelBuffer)) {
        return;
    }
    if (pixelBuffer) {
        CVPixelBufferRetain(pixelBuffer);
    }
    if (_pixelBuffer) {
        CVPixelBufferRelease(_pixelBuffer);
    }
    _pixelBuffer = pixelBuffer;
}

- (void)setResultPixelBuffer:(CVPixelBufferRef)resultPixelBuffer {
    if (_resultPixelBuffer &&
        resultPixelBuffer &&
        CFEqual(resultPixelBuffer, _resultPixelBuffer)) {
        return;
    }
    if (resultPixelBuffer) {
        CVPixelBufferRetain(resultPixelBuffer);
    }
    if (_resultPixelBuffer) {
        CVPixelBufferRelease(_resultPixelBuffer);
    }
    _resultPixelBuffer = resultPixelBuffer;
}

- (MFPixelBufferHelper *)pixelBufferHelper {
    if (!_pixelBufferHelper) {
        EAGLContext *context = [[GPUImageContext sharedImageProcessingContext] context];
        _pixelBufferHelper = [[MFPixelBufferHelper alloc] initWithContext:context];
    }
    return _pixelBufferHelper;
}

- (CIContext *)context {
    if (!_context) {
        _context = [[CIContext alloc] init];
    }
    return _context;
}

#pragma mark - Public

- (CVPixelBufferRef)outputPixelBuffer {
    if (!self.pixelBuffer) {
        return nil;
    }
    [self startRendering];
    return self.resultPixelBuffer;
}

#pragma mark - Private

/// 开始渲染视频图像
- (void)startRendering {
    // 可以对比下两种渲染方式
    CVPixelBufferRef pixelBuffer = [self renderByGPUImage:self.pixelBuffer];  // GPUImage
//    CVPixelBufferRef pixelBuffer = [self renderByCIImage:self.pixelBuffer];  // CIImage
    self.resultPixelBuffer = pixelBuffer;
    CVPixelBufferRelease(pixelBuffer);
}

// 用 GPUImage 加滤镜
- (CVPixelBufferRef)renderByGPUImage:(CVPixelBufferRef)pixelBuffer {
    CVPixelBufferRetain(pixelBuffer);
    
    __block CVPixelBufferRef output = nil;
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        
        GLuint textureID = [self.pixelBufferHelper convertYUVPixelBufferToTexture:pixelBuffer];
        CGSize size = CGSizeMake(CVPixelBufferGetWidth(pixelBuffer),
                                 CVPixelBufferGetHeight(pixelBuffer));
        
        [GPUImageContext setActiveShaderProgram:nil];
        GPUImageTextureInput *textureInput = [[GPUImageTextureInput alloc] initWithTexture:textureID size:size];
        GPUImageSmoothToonFilter *filter = [[GPUImageSmoothToonFilter alloc] init];
        [textureInput addTarget:filter];
        GPUImageTextureOutput *textureOutput = [[GPUImageTextureOutput alloc] init];
        [filter addTarget:textureOutput];
        [textureInput processTextureWithFrameTime:kCMTimeZero];
        
        output = [self.pixelBufferHelper convertTextureToPixelBuffer:textureOutput.texture
                                                         textureSize:size];
        
        [textureOutput doneWithTexture];
        
        glDeleteTextures(1, &textureID);
    });
    CVPixelBufferRelease(pixelBuffer);
    
    return output;
}

// 用 CIImage 加滤镜
- (CVPixelBufferRef)renderByCIImage:(CVPixelBufferRef)pixelBuffer {
    CVPixelBufferRetain(pixelBuffer);
    
    CGSize size = CGSizeMake(CVPixelBufferGetWidth(pixelBuffer),
                             CVPixelBufferGetHeight(pixelBuffer));
    CIImage *image = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer];
    // 加一层淡黄色滤镜
    CIImage *filterImage = [CIImage imageWithColor:[CIColor colorWithRed:255.0 / 255
                                                                   green:245.0 / 255
                                                                    blue:215.0 / 255
                                                                   alpha:0.1]];
    image = [filterImage imageByCompositingOverImage:image];
    
    CVPixelBufferRef output = [self.pixelBufferHelper createPixelBufferWithSize:size];
    [self.context render:image toCVPixelBuffer:output];
    
    CVPixelBufferRelease(pixelBuffer);
    return output;
}

@end
