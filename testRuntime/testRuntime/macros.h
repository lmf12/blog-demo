//
//  macros.h
//  testRuntime
//
//  Created by Lyman Li on 2018/3/19.
//  Copyright © 2018年 Lyman Li. All rights reserved.
//

/**
 *  Method swizzling
 */
#define SwizzleMethod(class, originalSelector, swizzledSelector) {              \
    Method originalMethod = class_getInstanceMethod(class, (originalSelector)); \
    Method swizzledMethod = class_getInstanceMethod(class, (swizzledSelector)); \
    if (!class_addMethod((class),                                               \
                         (originalSelector),                                    \
                         method_getImplementation(swizzledMethod),              \
                         method_getTypeEncoding(swizzledMethod))) {             \
        method_exchangeImplementations(originalMethod, swizzledMethod);         \
    } else {                                                                    \
        class_replaceMethod((class),                                            \
                            (swizzledSelector),                                 \
                            method_getImplementation(originalMethod),           \
                            method_getTypeEncoding(originalMethod));            \
    }                                                                           \
}   
