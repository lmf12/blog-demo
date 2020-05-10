//
//  Filter.h
//  testMetalFilterChain
//
//  Created by Lyman Li on 2020/5/5.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import "MetalTypes.h"
#import <MetalKit/MetalKit.h>

/// 这个滤镜用于添加一个贴纸
@interface Filter : NSObject

@property (nonatomic, strong) UIImage *overlayImage;  // 贴纸图片
@property (nonatomic, assign) matrix_float4x4 matrix;  // 贴纸的变换矩阵，用于调整位置

- (id <MTLTexture>)applyEffectWithTexture:(id <MTLTexture>)texture;

@end
