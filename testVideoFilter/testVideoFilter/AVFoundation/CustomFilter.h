//
//  CustomFilter.h
//  testVideoFilter
//
//  Created by Lyman Li on 2020/3/8.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomFilter : NSObject

@property (nonatomic, assign) CVPixelBufferRef pixelBuffer;

- (CVPixelBufferRef)outputPixelBuffer;

@end

NS_ASSUME_NONNULL_END
