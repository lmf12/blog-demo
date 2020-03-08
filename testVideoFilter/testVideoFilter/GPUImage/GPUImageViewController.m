//
//  GPUImageViewController.m
//  testVideoFilter
//
//  Created by Lyman Li on 2020/3/8.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import <GPUImage/GPUImage.h>
#import <Masonry.h>

#import "GPUImageViewController.h"

@interface GPUImageViewController ()

@property (nonatomic, strong) GPUImageView *imageView;
@property (nonatomic, strong) GPUImageMovie *movie;

@end

@implementation GPUImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self commonInit];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.movie startProcessing];
}

#pragma mark - Private

- (void)commonInit {
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupImageView];
    [self setupMovie];
    
    GPUImageSmoothToonFilter *filter = [[GPUImageSmoothToonFilter alloc] init]; // 添加滤镜
    [self.movie addTarget:filter];
    [filter addTarget:self.imageView];
}

- (void)setupImageView {
    self.imageView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 80, self.view.frame.size.width, self.view.frame.size.width)];
    [self.view addSubview:self.imageView];
}

- (void)setupMovie {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"sample" ofType:@"mp4"];
    NSURL *url = [NSURL fileURLWithPath:path];
    self.movie = [[GPUImageMovie alloc] initWithURL:url];
}

@end
