//
//  UIViewController+Swizzling.m
//  testRuntime
//
//  Created by Lyman Li on 2018/3/19.
//  Copyright © 2018年 Lyman Li. All rights reserved.
//

#import <objc/runtime.h>
#import "macros.h"
#import "RSSwizzle.h"

#import "UIViewController+Swizzling.h"

// 这里是测试父类和子类同时进行方法交换的情况，同时测试自定义宏 SwizzleMethod ，和 RSSwizzle

@implementation UIViewController (Swizzling)

+ (void)load {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
       
        SwizzleMethod([self class], @selector(viewWillAppear:), @selector(AA_viewWillAppear:));
        
        // 注释掉上面的 SwizzleMethod ，使用下面更优雅安全的 RSSwizzleInstanceMethod
//        RSSwizzleInstanceMethod([self class], @selector(viewWillAppear:), RSSWReturnType(void), RSSWArguments(BOOL animated), RSSWReplacement({
//
//            NSLog(@"UIViewController");
//
//            RSSWCallOriginal(animated);
//
//        }), RSSwizzleModeAlways, NULL);
        
    });
}

- (void)AA_viewWillAppear:(BOOL)animated {
    
    NSLog(@"UIViewController");
    
    [self AA_viewWillAppear:animated];
}

@end
