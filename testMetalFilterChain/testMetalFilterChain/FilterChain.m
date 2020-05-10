//
//  FilterChain.m
//  testMetalFilterChain
//
//  Created by Lyman Li on 2020/5/10.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import "FilterChain.h"

@interface FilterChain ()

@property (nonatomic, strong) NSMutableArray *filters;

@end

@implementation FilterChain

- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

#pragma mark - Public

- (id<MTLTexture>)applyEffectWithTexture:(id<MTLTexture>)texture {
    id <MTLTexture> result = texture;
    for (Filter *filter in self.filters) {
        result = [filter applyEffectWithTexture:result];
    }
    return result;
}

- (void)addFilter:(Filter *)filter {
    [self.filters addObject:filter];
}

- (void)removeAllFilter {
    [self.filters removeAllObjects];
}

#pragma mark - Private

- (void)commonInit {
    self.filters = [[NSMutableArray alloc] init];
}

@end
