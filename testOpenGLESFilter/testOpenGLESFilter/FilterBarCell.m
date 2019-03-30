//
//  FilterBarCell.m
//  testOpenGLESFilter
//
//  Created by Lyman Li on 2019/3/30.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import "FilterBarCell.h"

@interface FilterBarCell ()

@property (nonatomic, strong) UILabel *label;

@end

@implementation FilterBarCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.label.frame = CGRectInset(self.label.frame, 10, 10);
}

- (void)commonInit {
    self.label = [[UILabel alloc] initWithFrame:self.bounds];
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.font = [UIFont boldSystemFontOfSize:15];
    self.label.layer.masksToBounds = YES;
    self.label.layer.cornerRadius = 15;
    [self addSubview:self.label];
}

- (void)setTitle:(NSString *)title {
    _title = title;
    self.label.text = title;
}

- (void)setIsSelect:(BOOL)isSelect {
    _isSelect = isSelect;
    self.label.backgroundColor = isSelect ? [UIColor blackColor] : [UIColor clearColor];
    self.label.textColor = isSelect ? [UIColor whiteColor] : [UIColor blackColor];
}

@end
