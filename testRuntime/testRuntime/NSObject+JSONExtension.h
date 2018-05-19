//
//  NSObject+JSONExtension.h
//  testRuntime
//
//  Created by Lyman Li on 2018/3/20.
//  Copyright © 2018年 Lyman Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (JSONExtension)

// 通过字典来初始化模型
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

// 解档所有属性
- (void)initAllPropertiesWithCoder:(NSCoder *)coder;

// 归档所有属性
- (void)encodeAllPropertiesWithCoder:(NSCoder *)coder;

@end
