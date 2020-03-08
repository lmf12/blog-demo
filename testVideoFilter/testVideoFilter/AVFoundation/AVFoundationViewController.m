//
//  AVFoundationViewController.m
//  testVideoFilter
//
//  Created by Lyman Li on 2020/3/8.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <Masonry.h>

#import "CustomVideoCompositing.h"
#import "CustomVideoCompositionInstruction.h"
#import "AVFoundationViewController.h"

@interface AVFoundationViewController ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVMutableVideoComposition *videoComposition;

@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *exportButton;

@end

@implementation AVFoundationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self commonInit];
}

#pragma mark - Private

- (void)commonInit {
    [self setupUI];
    [self setupPlayer];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupPlayButton];
    [self setupExportButton];
}

- (void)setupPlayButton {
    self.playButton = [[UIButton alloc] init];
    [self.view addSubview:self.playButton];
    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(50, 50));
        make.centerX.equalTo(self.view).multipliedBy(0.5);
        make.top.equalTo(self.view).offset(self.view.frame.size.width + 120);
    }];
    [self configButton:self.playButton];
    [self.playButton setTitle:@"播放" forState:UIControlStateNormal];
    [self.playButton setTitle:@"暂停" forState:UIControlStateSelected];
    [self.playButton addTarget:self
                        action:@selector(playAction:)
              forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupExportButton {
    self.exportButton = [[UIButton alloc] init];
    [self.view addSubview:self.exportButton];
    [self.exportButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(50, 50));
        make.centerX.equalTo(self.view).multipliedBy(1.5);
        make.top.equalTo(self.view).offset(self.view.frame.size.width + 120);
    }];
    [self configButton:self.exportButton];
    [self.exportButton setTitle:@"导出" forState:UIControlStateNormal];
    [self.exportButton addTarget:self
                          action:@selector(exportAction:)
                forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupPlayer {
    // asset
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"sample" withExtension:@"mp4"];
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    
    // videoComposition
    self.videoComposition = [self createVideoCompositionWithAsset:asset];
    self.videoComposition.customVideoCompositorClass = [CustomVideoCompositing class];
    
    // playerItem
    self.playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
    self.playerItem.videoComposition = self.videoComposition;

    // player
    self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
    
    // playerLayer
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = CGRectMake(0,
                                        80,
                                        self.view.frame.size.width,
                                        self.view.frame.size.width);
    [self.view.layer addSublayer:self.playerLayer];
}

- (AVMutableVideoComposition *)createVideoCompositionWithAsset:(AVAsset *)asset {
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoCompositionWithPropertiesOfAsset:asset];
    NSArray *instructions = videoComposition.instructions;
    NSMutableArray *newInstructions = [NSMutableArray array];
    for (AVVideoCompositionInstruction *instruction in instructions) {
        NSArray *layerInstructions = instruction.layerInstructions;
        // TrackIDs
        NSMutableArray *trackIDs = [NSMutableArray array];
        for (AVVideoCompositionLayerInstruction *layerInstruction in layerInstructions) {
            [trackIDs addObject:@(layerInstruction.trackID)];
        }
        CustomVideoCompositionInstruction *newInstruction = [[CustomVideoCompositionInstruction alloc] initWithSourceTrackIDs:trackIDs timeRange:instruction.timeRange];
        newInstruction.layerInstructions = instruction.layerInstructions;
        [newInstructions addObject:newInstruction];
    }
    videoComposition.instructions = newInstructions;
    return videoComposition;
}

- (void)configButton:(UIButton *)button {
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.tintColor = [UIColor clearColor];
    [button.titleLabel setFont:[UIFont systemFontOfSize:14]];
    [button setBackgroundColor:[UIColor blackColor]];
    button.layer.cornerRadius = 5;
    button.layer.masksToBounds = YES;
}

#pragma mark - Action

- (void)playAction:(UIButton *)button {
    button.selected = !button.selected;
    if (button.selected) {
        [self.player play];
    } else {
        [self.player pause];
    }
}

- (void)exportAction:(UIButton *)button {
    
}

@end
