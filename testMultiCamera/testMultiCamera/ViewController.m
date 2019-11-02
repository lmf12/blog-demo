//
//  ViewController.m
//  testMultiCamera
//
//  Created by Lyman Li on 2019/11/2.
//  Copyright © 2019 Lyman Li. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) NSArray *devices;
@property (nonatomic, strong) NSArray <AVCaptureInput *>*inputs;
@property (nonatomic, strong) NSArray *connections;
@property (nonatomic, strong) AVCaptureMultiCamSession *session;

@property (nonatomic, assign) NSInteger closedIndex;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.closedIndex = 3;
    [self initSession];
    [self initDevices];

    [self initInputs];
    [self initLayersAndConnections];
    
    [self initTap];

    [self refeshCamera];

    [self.session startRunning];
}

- (AVCaptureDeviceInput *)inputWithCaptureDevice:(AVCaptureDevice *)device {
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:NULL];
    return input;
}

- (void)initSession {
    self.session = [[AVCaptureMultiCamSession alloc] init];
}

- (void)initDevices {
    NSArray *back = @[AVCaptureDeviceTypeBuiltInTelephotoCamera,
                      AVCaptureDeviceTypeBuiltInWideAngleCamera,
                      AVCaptureDeviceTypeBuiltInUltraWideCamera];
    AVCaptureDeviceDiscoverySession *backDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:back mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    
    NSArray *front = @[AVCaptureDeviceTypeBuiltInWideAngleCamera];
    AVCaptureDeviceDiscoverySession *frontDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:front mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
    
    NSMutableArray *mutArr = [backDiscoverySession.devices mutableCopy];
    [mutArr addObjectsFromArray:frontDiscoverySession.devices];
    
    self.devices = [mutArr copy];
}

- (void)initInputs {
    AVCaptureInput *input1 = [self inputWithCaptureDevice:self.devices[0]];
    AVCaptureInput *input2 = [self inputWithCaptureDevice:self.devices[1]];
    AVCaptureInput *input3 = [self inputWithCaptureDevice:self.devices[2]];
    AVCaptureInput *input4 = [self inputWithCaptureDevice:self.devices[3]];
    
    self.inputs = @[input1, input2, input3, input4];
}

- (void)initLayersAndConnections {
    int width = self.view.frame.size.width / 2;
    int height = self.view.frame.size.height / 2;
    
    AVCaptureVideoPreviewLayer *previewLayer1 = [[AVCaptureVideoPreviewLayer alloc] initWithSessionWithNoConnection:self.session];
    previewLayer1.frame = CGRectMake(0, 0, width, height);
    previewLayer1.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:previewLayer1];
    
    AVCaptureVideoPreviewLayer *previewLayer2 = [[AVCaptureVideoPreviewLayer alloc] initWithSessionWithNoConnection:self.session];
    previewLayer2.frame = CGRectMake(width, 0, width, height);
    previewLayer2.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:previewLayer2];
    
    AVCaptureVideoPreviewLayer *previewLayer3 = [[AVCaptureVideoPreviewLayer alloc] initWithSessionWithNoConnection:self.session];
    previewLayer3.frame = CGRectMake(0, height, width, height);
    previewLayer3.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:previewLayer3];
    
    AVCaptureVideoPreviewLayer *previewLayer4 = [[AVCaptureVideoPreviewLayer alloc] initWithSessionWithNoConnection:self.session];
    previewLayer4.frame = CGRectMake(width, height, width, height);
    previewLayer4.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:previewLayer4];
    
    
    AVCaptureConnection *c1 = [AVCaptureConnection connectionWithInputPort:self.inputs[0].ports.firstObject videoPreviewLayer:previewLayer1];
    AVCaptureConnection *c2 = [AVCaptureConnection connectionWithInputPort:self.inputs[1].ports.firstObject videoPreviewLayer:previewLayer2];
    AVCaptureConnection *c3 = [AVCaptureConnection connectionWithInputPort:self.inputs[2].ports.firstObject videoPreviewLayer:previewLayer3];
    AVCaptureConnection *c4 = [AVCaptureConnection connectionWithInputPort:self.inputs[3].ports.firstObject videoPreviewLayer:previewLayer4];
    self.connections = @[c1, c2, c3, c4];
}

- (void)refreshInputs {
    AVCaptureInput *input = self.inputs[self.closedIndex];
    NSArray *addedInputs = [self.session inputs];
    if (addedInputs.count > 0 && ![addedInputs containsObject:input]) {
        return;
    }
    
    [self.session beginConfiguration];
    if (addedInputs.count > 0) {
        for (AVCaptureInput *input in addedInputs) {
            [self.session removeInput:input];
        }
    }
    for (AVCaptureInput *input in self.inputs) {
        if ([self.inputs indexOfObject:input] == self.closedIndex) {
            continue;
        }
        if ([self.session canAddInput:input]) {
            [self.session addInputWithNoConnections:input];
        }
    }
    [self.session commitConfiguration];
}

- (void)refreshConnections {
    AVCaptureConnection *connection = self.connections[self.closedIndex];
    NSArray *addedConnections = [self.session connections];
    if (addedConnections.count > 0 && ![addedConnections containsObject:connection]) {
        return;
    }

    [self.session beginConfiguration];
    if (addedConnections.count > 0) {
        for (AVCaptureConnection *connection in addedConnections) {
            [self.session removeConnection:connection];
        }
    }
    for (AVCaptureConnection *connection in self.connections) {
        if ([self.connections indexOfObject:connection] == self.closedIndex) {
            continue;
        }
        if ([self.session canAddConnection:connection]) {
            [self.session addConnection:connection];
        }
    }
    [self.session commitConfiguration];
}

- (void)initTap {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self.view addGestureRecognizer:tap];
}

- (void)refeshCamera {
    [self refreshInputs];
    [self refreshConnections];
}

- (void)tapAction:(UITapGestureRecognizer *)tap {
    CGPoint point = [tap locationInView:self.view];
    CGSize size = self.view.frame.size;
    if (point.x < size.width / 2 && point.y < size.height / 2) {
        self.closedIndex = 0;
    } else if (point.x >= size.width / 2 && point.y < size.height / 2) {
        self.closedIndex = 1;
    } else if (point.x < size.width / 2 && point.y >= size.height / 2) {
        self.closedIndex = 2;
    } else {
        self.closedIndex = 3;
    }
    
    [self refeshCamera];
}
@end
