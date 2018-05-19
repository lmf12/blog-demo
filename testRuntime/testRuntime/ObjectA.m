//
//  ObjectA.m
//  testRuntime
//
//  Created by Lyman Li on 2018/3/20.
//  Copyright © 2018年 Lyman Li. All rights reserved.
//

#import "NSObject+JSONExtension.h"

#import "ObjectA.h"

@interface ObjectA ()

@property (nonatomic, readwrite) NSString *title;
@property (nonatomic, readwrite) NSInteger count;

@end

@implementation ObjectA

- (id)initWithCoder:(NSCoder *)aDecoder{
    
    self = [super init];
    if (self) {
        // 调用封装好的自动归档方法
        [self initAllPropertiesWithCoder:aDecoder];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
    
    // 调用封装好的自动解档方法
    [self encodeAllPropertiesWithCoder:aCoder];
}

@end
