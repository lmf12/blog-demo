//
//  ViewController.m
//  testOpenGLESRender
//
//  Created by Lyman on 2019/2/21.
//  Copyright © 2019 Lyman Li. All rights reserved.
//

#import "GLKitViewController.h"
#import "GLSLViewController.h"

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)actionOpenGLKit:(id)sender {
    [self.navigationController pushViewController:[[GLKitViewController alloc] init]
                                         animated:YES];
}

- (IBAction)actionOpenGLSL:(id)sender {
    [self.navigationController pushViewController:[[GLSLViewController alloc] init]
                                         animated:YES];
}


@end
