//
//  OGViewController0.m
//  testOpenGL
//
//  Created by Lyman Li on 2018/3/22.
//  Copyright © 2018年 Lyman Li. All rights reserved.
//

#import "OGGLView0.h"

#import "OGViewController0.h"

@interface OGViewController0 ()

@end

@implementation OGViewController0

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    OGGLView0 *view = [[OGGLView0 alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.view.bounds))];

    [self.view addSubview:view];
}


@end
