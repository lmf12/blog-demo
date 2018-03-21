//
//  UIViewController+Tag.h
//  testRuntime
//
//  Created by Lyman Li on 2018/3/21.
//  Copyright © 2018年 Lyman Li. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (Tag)

// 这里添加属性的 getter 和 setter 方法

- (void)setTag:(NSString *)tag;

- (NSString *)tag;

@end
