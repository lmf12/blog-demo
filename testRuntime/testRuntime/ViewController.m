//
//  ViewController.m
//  testRuntime
//
//  Created by Lyman Li on 2018/3/17.
//  Copyright © 2018年 Lyman Li. All rights reserved.
//

#import <objc/runtime.h>
#import "ObjectA.h"
#import "NSObject+JSONExtension.h"
#import "UIViewController+Tag.h"

#import "ViewController.h"

@interface ViewController () <UITextViewDelegate> {
    
    NSString *testIvar;    // 用来测试的成员变量
}

@property (nonatomic, assign) NSInteger testProperty;    // 用来测试的属性

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self test];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)test {

    [self testSEL];
    [self testCmd:@(5)];
    [self testCategroy];
    [self testPrintIvarList];
    [self testPrintMethodList];
    [self testPrintPropertyList];
    [self testPrintProtocolList];
    [self testDictionaryToModel];
    [self testCoder];
}

// 测试 SEL 指针
- (void)testSEL {
    
    SEL sel = @selector(viewDidLoad);
    NSLog(@"%s", sel);
}

// 测试 _cmd 隐藏参数
- (void)testCmd:(NSNumber *)num {
    
    NSLog(@"%ld", (long)num.integerValue);
    
    num = [NSNumber numberWithInteger:num.integerValue-1];
    
    if (num.integerValue > 0) {
        [self performSelector:_cmd withObject:num];
    }
}

// 测试 categroy
- (void)testCategroy {
    
    self.tag = @"TAG";
    NSLog(@"%@", self.tag);
}

// 测试 打印属性列表
- (void)testPrintPropertyList {
    unsigned int count;
    
    objc_property_t *propertyList = class_copyPropertyList([self class], &count);
    for (unsigned int i=0; i<count; i++) {
        const char *propertyName = property_getName(propertyList[i]);
        NSLog(@"property----="">%@", [NSString stringWithUTF8String:propertyName]);
    }
    
    free(propertyList);
}

// 测试 打印方法列表
- (void)testPrintMethodList {
    unsigned int count;
    
    Method *methodList = class_copyMethodList([self class], &count);
    for (unsigned int i=0; i<count; i++) {
        Method method = methodList[i];
        NSLog(@"method----="">%@", NSStringFromSelector(method_getName(method)));
    }
    
    free(methodList);
}

// 测试 打印成员变量列表
- (void)testPrintIvarList {
    unsigned int count;
    
    Ivar *ivarList = class_copyIvarList([self class], &count);
    for (unsigned int i=0; i<count; i++) {
        Ivar myIvar = ivarList[i];
        const char *ivarName = ivar_getName(myIvar);
        NSLog(@"ivar----="">%@", [NSString stringWithUTF8String:ivarName]);
    }
    
    free(ivarList);
}

// 测试 打印协议列表
- (void)testPrintProtocolList {
    unsigned int count;
    
    __unsafe_unretained Protocol **protocolList = class_copyProtocolList([self class], &count);
    for (unsigned int i=0; i<count; i++) {
        Protocol *myProtocal = protocolList[i];
        const char *protocolName = protocol_getName(myProtocal);
        NSLog(@"protocol----="">%@", [NSString stringWithUTF8String:protocolName]);
    }
    
    free(protocolList);
}

// 测试 字典转数组
- (void)testDictionaryToModel {
    
    NSDictionary *info = @{@"title": @"标题", @"count": @(1), @"test": @"hello"};
    ObjectA *objectA = [[ObjectA alloc] initWithDictionary:info];
    NSLog(@"%@", objectA.title);
    NSLog(@"%ld", (long)objectA.count);
}

// 测试 归解档
- (void)testCoder {
    
    NSDictionary *info = @{@"title": @"标题11", @"count": @(11)};
    NSString *path = [NSString stringWithFormat:@"%@/objectA.plist", NSHomeDirectory()];
    
    // 归档
    ObjectA *objectA = [[ObjectA alloc] initWithDictionary:info];
    [NSKeyedArchiver archiveRootObject:objectA toFile:path];
    
    // 解档
    ObjectA *objectB = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    NSLog(@"%@", objectB.title);
    NSLog(@"%ld", (long)objectB.count);
}

// 测试 AOP添加按钮点击上报（具体实现看 UIButton+Swizzling）
- (IBAction)onClick:(id)sender {
    
    NSLog(@"ViewController：onClick");
}

@end
