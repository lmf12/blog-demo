//
//  ViewController.m
//  testOpenGLESLoadOBJ
//
//  Created by Lyman Li on 2019/3/17.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import "PlaneViewController.h"

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
    UIViewController *vc = [[PlaneViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)actionCube:(id)sender {
}

- (IBAction)actionObject:(id)sender {
}

@end
