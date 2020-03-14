//
//  MFPixelBufferHelper.m
//  MFPanoramaPlayerDemo
//
//  Created by Lyman Li on 2020/1/25.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import "MFShaderHelper.h"

#import "MFPixelBufferHelper.h"

@import OpenGLES;

@interface MFPixelBufferHelper ()

@property (nonatomic, strong) EAGLContext *context;

@property (nonatomic, assign) GLuint yuvConversionProgram;
@property (nonatomic, assign) GLuint normalProgram;
@property (nonatomic, assign) CVOpenGLESTextureCacheRef textureCache;

@property (nonatomic, assign) GLuint VBO;

@property (nonatomic, assign) CVOpenGLESTextureRef luminanceTexture;
@property (nonatomic, assign) CVOpenGLESTextureRef chrominanceTexture;
@property (nonatomic, assign) CVOpenGLESTextureRef renderTexture;

@end

@implementation MFPixelBufferHelper

- (void)dealloc {
    if (_luminanceTexture) {
        CFRelease(_luminanceTexture);
    }
    if (_chrominanceTexture) {
        CFRelease(_chrominanceTexture);
    }
    if (_renderTexture) {
        CFRelease(_renderTexture);
    }
    if (_textureCache) {
        CFRelease(_textureCache);
    }
    if (_yuvConversionProgram) {
        glDeleteProgram(_yuvConversionProgram);
    }
    if (_VBO) {
        glDeleteBuffers(1, &_VBO);
    }
}

- (instancetype)initWithContext:(EAGLContext *)context {
    self = [super init];
    if (self) {
        _context = context;
        [self setupYUVConversionProgram];
        [self setupNormalProgram];
        [self setupVBO];
    }
    return self;
}

#pragma mark - Accessors

- (CVOpenGLESTextureCacheRef)textureCache {
    if (!_textureCache) {
        EAGLContext *context = self.context;
        CVReturn status = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, context, nil, &_textureCache);
        if (status != kCVReturnSuccess) {
            NSLog(@"Can't create textureCache");
        }
    }
    return _textureCache;
}

- (void)setLuminanceTexture:(CVOpenGLESTextureRef)luminanceTexture {
    if (_luminanceTexture &&
        luminanceTexture &&
        CFEqual(luminanceTexture, _luminanceTexture)) {
        return;
    }
    if (luminanceTexture) {
        CFRetain(luminanceTexture);
    }
    if (_luminanceTexture) {
        CFRelease(_luminanceTexture);
    }
    _luminanceTexture = luminanceTexture;
}

- (void)setChrominanceTexture:(CVOpenGLESTextureRef)chrominanceTexture {
    if (_chrominanceTexture &&
        chrominanceTexture &&
        CFEqual(chrominanceTexture, _chrominanceTexture)) {
        return;
    }
    if (chrominanceTexture) {
        CFRetain(chrominanceTexture);
    }
    if (_chrominanceTexture) {
        CFRelease(_chrominanceTexture);
    }
    _chrominanceTexture = chrominanceTexture;
}

- (void)setRenderTexture:(CVOpenGLESTextureRef)renderTexture {
    if (_renderTexture &&
        renderTexture &&
        CFEqual(renderTexture, _renderTexture)) {
        return;
    }
    if (renderTexture) {
        CFRetain(renderTexture);
    }
    if (_renderTexture) {
        CFRelease(_renderTexture);
    }
    _renderTexture = renderTexture;
}

#pragma mark - Public

- (CVPixelBufferRef)createPixelBufferWithSize:(CGSize)size {
    CVPixelBufferRef pixelBuffer;
    NSDictionary *pixelBufferAttributes = @{(id)kCVPixelBufferIOSurfacePropertiesKey: @{}};
    CVReturn status = CVPixelBufferCreate(nil,
                                          size.width,
                                          size.height,
                                          kCVPixelFormatType_32BGRA,
                                          (__bridge CFDictionaryRef _Nullable)(pixelBufferAttributes),
                                          &pixelBuffer);
    if (status != kCVReturnSuccess) {
        NSLog(@"Can't create pixelbuffer");
    }
    return pixelBuffer;
}

- (GLuint)convertYUVPixelBufferToTexture:(CVPixelBufferRef)pixelBuffer {
    if (!pixelBuffer) {
        return 0;
    }
    
    CGSize textureSize = CGSizeMake(CVPixelBufferGetWidth(pixelBuffer),
                                    CVPixelBufferGetHeight(pixelBuffer));

    [EAGLContext setCurrentContext:self.context];
    
    GLuint frameBuffer;
    GLuint textureID;
    
    // FBO
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    
    // texture
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, textureSize.width, textureSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureID, 0);
    
    glViewport(0, 0, textureSize.width, textureSize.height);
    
    // program
    glUseProgram(self.yuvConversionProgram);
    
    // texture
    CVOpenGLESTextureRef luminanceTextureRef = nil;
    CVOpenGLESTextureRef chrominanceTextureRef = nil;

    CVReturn status = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                   self.textureCache,
                                                                   pixelBuffer,
                                                                   nil,
                                                                   GL_TEXTURE_2D,
                                                                   GL_LUMINANCE,
                                                                   textureSize.width,
                                                                   textureSize.height,
                                                                   GL_LUMINANCE,
                                                                   GL_UNSIGNED_BYTE,
                                                                   0,
                                                                   &luminanceTextureRef);
    if (status != kCVReturnSuccess) {
        NSLog(@"Can't create luminanceTexture");
    }
    
    status = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                          self.textureCache,
                                                          pixelBuffer,
                                                          nil,
                                                          GL_TEXTURE_2D,
                                                          GL_LUMINANCE_ALPHA,
                                                          textureSize.width / 2,
                                                          textureSize.height / 2,
                                                          GL_LUMINANCE_ALPHA,
                                                          GL_UNSIGNED_BYTE,
                                                          1,
                                                          &chrominanceTextureRef);
    
    if (status != kCVReturnSuccess) {
        NSLog(@"Can't create chrominanceTexture");
    }
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(luminanceTextureRef));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glUniform1i(glGetUniformLocation(self.yuvConversionProgram, "luminanceTexture"), 0);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(chrominanceTextureRef));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glUniform1i(glGetUniformLocation(self.yuvConversionProgram, "chrominanceTexture"), 1);
    
    GLfloat kXDXPreViewColorConversion601FullRange[] = {
        1.0,    1.0,    1.0,
        0.0,    -0.343, 1.765,
        1.4,    -0.711, 0.0,
    };
    
    GLuint yuvConversionMatrixUniform = glGetUniformLocation(self.yuvConversionProgram, "colorConversionMatrix");
    glUniformMatrix3fv(yuvConversionMatrixUniform, 1, GL_FALSE, kXDXPreViewColorConversion601FullRange);
    
    // VBO
    glBindBuffer(GL_ARRAY_BUFFER, self.VBO);
    
    GLuint positionSlot = glGetAttribLocation(self.yuvConversionProgram, "position");
    glEnableVertexAttribArray(positionSlot);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)0);
    
    GLuint textureSlot = glGetAttribLocation(self.yuvConversionProgram, "inputTextureCoordinate");
    glEnableVertexAttribArray(textureSlot);
    glVertexAttribPointer(textureSlot, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(3* sizeof(float)));
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDeleteFramebuffers(1, &frameBuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    glFlush();
    
    self.luminanceTexture = luminanceTextureRef;
    self.chrominanceTexture = chrominanceTextureRef;
    
    CFRelease(luminanceTextureRef);
    CFRelease(chrominanceTextureRef);
    
    return textureID;
}

- (GLuint)convertRGBPixelBufferToTexture:(CVPixelBufferRef)pixelBuffer {
    if (!pixelBuffer) {
        return 0;
    }
    
    CGSize textureSize = CGSizeMake(CVPixelBufferGetWidth(pixelBuffer),
                                    CVPixelBufferGetHeight(pixelBuffer));
    CVOpenGLESTextureRef texture = nil;
    
    CVReturn status = CVOpenGLESTextureCacheCreateTextureFromImage(nil,
                                                                   self.textureCache,
                                                                   pixelBuffer,
                                                                   nil,
                                                                   GL_TEXTURE_2D,
                                                                   GL_RGBA,
                                                                   textureSize.width,
                                                                   textureSize.height,
                                                                   GL_BGRA,
                                                                   GL_UNSIGNED_BYTE,
                                                                   0,
                                                                   &texture);
    
    if (status != kCVReturnSuccess) {
        NSLog(@"Can't create texture");
    }
    
    self.renderTexture = texture;
    CFRelease(texture);
    return CVOpenGLESTextureGetName(texture);
}

- (CVPixelBufferRef)convertTextureToPixelBuffer:(GLuint)texture
                                    textureSize:(CGSize)textureSize {
    [EAGLContext setCurrentContext:self.context];
    
    CVPixelBufferRef pixelBuffer = [self createPixelBufferWithSize:textureSize];
    GLuint targetTextureID = [self convertRGBPixelBufferToTexture:pixelBuffer];
    
    GLuint frameBuffer;
    
    // FBO
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    
    // texture
    glBindTexture(GL_TEXTURE_2D, targetTextureID);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, textureSize.width, textureSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, targetTextureID, 0);
    
    glViewport(0, 0, textureSize.width, textureSize.height);
    
    // program
    glUseProgram(self.normalProgram);
    
    // texture
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glUniform1i(glGetUniformLocation(self.normalProgram, "renderTexture"), 0);
    
    // VBO
    glBindBuffer(GL_ARRAY_BUFFER, self.VBO);
    
    GLuint positionSlot = glGetAttribLocation(self.normalProgram, "position");
    glEnableVertexAttribArray(positionSlot);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)0);
    
    GLuint textureSlot = glGetAttribLocation(self.normalProgram, "inputTextureCoordinate");
    glEnableVertexAttribArray(textureSlot);
    glVertexAttribPointer(textureSlot, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(3* sizeof(float)));
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDeleteFramebuffers(1, &frameBuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    glFlush();
    
    return pixelBuffer;
}

#pragma mark - Private

- (void)setupYUVConversionProgram {
    self.yuvConversionProgram = [MFShaderHelper programWithShaderName:@"YUVConversion"];
}

- (void)setupNormalProgram {
    self.normalProgram = [MFShaderHelper programWithShaderName:@"Normal"];
}

- (void)setupVBO {
    float vertices[] = {
        -1.0f, -1.0f, 0.0f, 0.0f, 0.0f,
        -1.0f, 1.0f, 0.0f, 0.0f, 1.0f,
        1.0f, -1.0f, 0.0f, 1.0f, 0.0f,
        1.0f, 1.0f, 0.0f, 1.0f, 1.0f,
    };
    
    glGenBuffers(1, &_VBO);
    glBindBuffer(GL_ARRAY_BUFFER, _VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
}

@end
