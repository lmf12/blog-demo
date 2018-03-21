//
//  UIViewController+Tag.m
//  testRuntime
//
//  Created by Lyman Li on 2018/3/21.
//  Copyright © 2018年 Lyman Li. All rights reserved.
//

#import <objc/runtime.h>

#import "UIViewController+Tag.h"

static void *tag = &tag;

// 这里测试在分类中，利用 Runtime 来添加一个属性

@implementation UIViewController (Tag)

- (void)setTag:(NSString *)t {
    
    objc_setAssociatedObject(self, &tag, t, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)tag {
    
    return objc_getAssociatedObject(self, &tag);
}

@end
