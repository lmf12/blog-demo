//
//  UIImage+Resize.m
//  testTNN_iOS
//
//  Created by Lyman Li on 2020/10/6.
//

#import "UIImage+Resize.h"

@implementation UIImage (Resize)

- (UIImage *)resizeWithSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    UIImage *resized = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resized;
}

@end
