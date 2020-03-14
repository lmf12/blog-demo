//
//  MFShaderHelper.h
//  MFWobbleViewDemo
//
//  Created by Lyman Li on 2019/4/18.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MFShaderHelper : NSObject

/**
 将一个顶点着色器和一个片段着色器挂载到一个着色器程序上，并返回程序的 id
 
 @param shaderName 着色器名称，顶点着色器应该命名为 shaderName.vsh ，片段着色器应该命名为 shaderName.fsh
 @return 着色器程序的 ID
 */
+ (GLuint)programWithShaderName:(NSString *)shaderName;

// 通过一张图片来创建纹理
+ (GLuint)createTextureWithImage:(UIImage *)image;

@end
