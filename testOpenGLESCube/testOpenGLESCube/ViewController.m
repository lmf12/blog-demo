//
//  ViewController.m
//  testOpenGLESCube
//
//  Created by Lyman Li on 2019/3/23.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import "PlaneViewController.h"
#import "CubeViewController.h"

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)actionPlane:(id)sender {
    PlaneViewController *vc = [[PlaneViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)actionCube:(id)sender {
    CubeViewController *vc = [[CubeViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
