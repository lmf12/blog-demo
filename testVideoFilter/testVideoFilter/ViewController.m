//
//  ViewController.m
//  testVideoFilter
//
//  Created by Lyman Li on 2020/3/8.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import "GPUImageViewController.h"
#import "AVFoundationViewController.h"

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)gpuImageAction:(id)sender {
    GPUImageViewController *vc = [[GPUImageViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)avFoundationAction:(id)sender {
    AVFoundationViewController *vc = [[AVFoundationViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
