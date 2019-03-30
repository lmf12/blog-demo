//
//  FilterBar.h
//  testOpenGLESFilter
//
//  Created by Lyman Li on 2019/3/30.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FilterBar;

@protocol FilterBarDelegate <NSObject>

- (void)filterBar:(FilterBar *)filterBar didScrollToIndex:(NSUInteger)index;

@end

@interface FilterBar : UIView

@property (nonatomic, strong) NSArray <NSString *> *itemList;

@property (nonatomic, weak) id<FilterBarDelegate> delegate;

@end
