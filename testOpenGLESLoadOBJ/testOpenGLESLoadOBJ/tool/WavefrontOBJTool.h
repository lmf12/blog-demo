//
//  WavefrontOBJTool.h
//  testOpenGLESLoadOBJ
//
//  Created by Lyman Li on 2019/3/17.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import <GLKit/GLKit.h>

#import <Foundation/Foundation.h>

typedef struct {
    GLKVector3 positionCoord;
    GLKVector2 textureCoord;
    GLKVector3 normal;
} SenceVertex;

@interface WavefrontOBJTool : NSObject

- (void)loadDataFromObj:(NSString *)filePath
             completion:(void (^)(SenceVertex *vertexs, NSInteger count))completion;

@end
