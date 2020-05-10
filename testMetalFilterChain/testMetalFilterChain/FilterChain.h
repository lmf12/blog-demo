//
//  FilterChain.h
//  testMetalFilterChain
//
//  Created by Lyman Li on 2020/5/10.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import "Filter.h"

@interface FilterChain : NSObject

/// 应用多个滤镜效果
- (id <MTLTexture>)applyEffectWithTexture:(id <MTLTexture>)texture;

/// 移除所有滤镜
- (void)removeAllFilter;

/// 添加滤镜
- (void)addFilter:(Filter *)filter;

@end

