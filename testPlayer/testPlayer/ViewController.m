//
//  ViewController.m
//  testPlayer
//
//  Created by Lyman Li on 2018/3/7.
//  Copyright © 2018年 Lyman Li. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) UIView *playerView;
@property (nonatomic, strong) NSMutableArray *urlList;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) NSTimeInterval currentDuration;

@property (weak, nonatomic) IBOutlet UISlider *viewVideoProgress;

@end

@implementation ViewController

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    
    // 这步很重要，当ViewController销毁时，要将Command的Target移除
    [self removeCommandCenterTargets];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 添加监听
    [self addObservers];
    
    // 开启远程控制
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self createRemoteCommandCenter];
    
    // 初始化数据
    [self initData];
    self.currentIndex = 0;
    
    // 初始化播放器和视图
    self.player = [[AVPlayer alloc] init];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerView = [[UIView alloc] init];
    
    // 添加视图
    [self.view addSubview:self.playerView];
    [_playerView.layer insertSublayer:_playerLayer atIndex:0];
    
    // 监听播放进度
    __weak ViewController * weakSelf = self;
    [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, NSEC_PER_SEC)
                                              queue:NULL
                                         usingBlock:^(CMTime time) {
                                             
                                             [weakSelf updateProgressView];
                                         }];

    // 进度条添加位置改变监听
    [_viewVideoProgress addTarget:self
                           action:@selector(videoProgressDidChanged:)
                 forControlEvents:UIControlEventValueChanged];
    
    
    // 播放视频
    [self playWithUrl:_urlList[_currentIndex]];
}

// 添加App退到后台和进入前台的监听
- (void)addObservers {
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(removePlayerOnPlayerLayer)
                   name:UIApplicationDidEnterBackgroundNotification
                 object:nil];
    [center addObserver:self
               selector:@selector(resetPlayerToPlayerLayer)
                   name:UIApplicationWillEnterForegroundNotification
                 object:nil];

}

// 初始化URL列表
- (void)initData {
    
    NSArray *videoUrlList = @[@"https://lymanli-1258009115.cos.ap-guangzhou.myqcloud.com/video/sample/sample-video1.mp4",
                              @"https://lymanli-1258009115.cos.ap-guangzhou.myqcloud.com/video/sample/sample-video2.mp4"];
    self.urlList = [[NSMutableArray alloc] init];
    
    for (NSString *urlString in videoUrlList) {
        NSURL *url = [NSURL URLWithString:urlString];
        [_urlList addObject:url];
    }
}

// 播放URL
- (void)playWithUrl:(NSURL *)url {
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
    
    CGFloat width = self.view.bounds.size.width;
    CGFloat scale = [self videoScale:url];

    if (!isnan(scale)) {
        _playerView.frame = CGRectMake(0, 0, width, width * scale);
        _playerLayer.frame = _playerView.bounds;
    }
    
    [_player replaceCurrentItemWithPlayerItem:playerItem];
    
    [self playVideo];
}

// 获取视频宽高比
- (CGFloat)videoScale:(NSURL *)URL{
    
    if (!URL) {
        return 0.0f;
    }

    AVURLAsset *asset = [AVURLAsset assetWithURL:URL];
    
    NSArray *array = asset.tracks;
    CGSize videoSize = CGSizeZero;
    for (AVAssetTrack *track in array) {
        if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
            videoSize = track.naturalSize;
        }
    }
    
    return videoSize.height / videoSize.width;
}

// 更新进度条进度
- (void)updateProgressView {
    
    self.currentDuration = CMTimeGetSeconds(_player.currentItem.duration);
    
    CGFloat progress = CMTimeGetSeconds(_player.currentItem.currentTime) / _currentDuration;
    
// 可以通过监听playerItem结束的通知来切换歌曲
// 当结束时需要移除对当前playerItem的监听，然后添加下一个playerItem的监听
// 这里直接通过判断进度条是否完成，来切换歌曲
//
// 监听播放通知的写法如下：
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(playerItemDidReachEnd:)
//                                                 name:AVPlayerItemDidPlayToEndTimeNotification
//                                               object:self.playerItem];

    if (progress == 1.0f) {
        [self playNextVideo];
    } else {
        [_viewVideoProgress setValue:progress];
    }
}

// 拖动进度条监听
- (void)videoProgressDidChanged:(UISlider *)sender {
    
    if (sender.value == 1.0f) {
        [self playNextVideo];
        return;
    }
    
    NSTimeInterval duration = CMTimeGetSeconds(_player.currentItem.duration);
    [self seekToTime:duration * sender.value];
}

#pragma mark - 播放器控制

// 播放视频
- (void)playVideo {
 
    if (!_player) {
        return;
    }
    
    [_player play];
    
    [self updateLockScreenInfo];
}

// 暂停视频
- (void)pauseVideo {
    
    if (!_player) {
        return;
    }
    
    [_player pause];
    
    [self updateLockScreenInfo];
}

// 播放下一个视频
- (void)playNextVideo {
    
    self.currentIndex = (_currentIndex + 1 >= [_urlList count]) ? 0 : _currentIndex + 1;
    [self playWithUrl:_urlList[_currentIndex]];
}

// 播放上一个视频
- (void)playPreviousVideo {
    
    self.currentIndex = (_currentIndex - 1 < 0) ? [_urlList count] - 1 : _currentIndex - 1;
    [self playWithUrl:_urlList[_currentIndex]];
}

// 拖动到某个时间
- (void)seekToTime:(NSTimeInterval)time {
    
    CMTime duration = _player.currentItem.duration;
    CMTime currentTime = CMTimeMakeWithSeconds(time, duration.timescale);
    
    [_player seekToTime:currentTime completionHandler:^(BOOL finished) {
        // 同步锁屏界面进度
        [self updateLockScreenInfo];
    }];
}

#pragma mark - 视频后台播放的关键步骤

- (void)removePlayerOnPlayerLayer {
    
    _playerLayer.player = nil;
}

- (void)resetPlayerToPlayerLayer {
    
    _playerLayer.player = _player;
}

#pragma mark - 视频锁屏界面控制

// 更新锁屏界面信息
- (void)updateLockScreenInfo {
    
    if (!_player) {
        return;
    }
    
    // 1.获取锁屏中心
    MPNowPlayingInfoCenter *playingInfoCenter = [MPNowPlayingInfoCenter defaultCenter];
    // 初始化一个存放音乐信息的字典
    NSMutableDictionary *playingInfoDict = [NSMutableDictionary dictionary];
    
    // 2、设置歌曲名
    [playingInfoDict setObject:[NSString stringWithFormat:@"歌曲%ld", (long)_currentIndex + 1]
                        forKey:MPMediaItemPropertyTitle];
    [playingInfoDict setObject:[NSString stringWithFormat:@"专辑%ld", (long)_currentIndex + 1]
                        forKey:MPMediaItemPropertyAlbumTitle];
    
    
    // 3、设置封面的图片
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"cover%ld.jpg", (long)_currentIndex + 1]];
    if (image) {
        MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:image];
        [playingInfoDict setObject:artwork forKey:MPMediaItemPropertyArtwork];
    }
    
    // 4、设置歌曲的时长和已经消耗的时间
    NSNumber *playbackDuration = @(CMTimeGetSeconds(_player.currentItem.duration));
    NSNumber *elapsedPlaybackTime = @(CMTimeGetSeconds(_player.currentItem.currentTime));

    if (!playbackDuration || !elapsedPlaybackTime) {
        return;
    }
    [playingInfoDict setObject:playbackDuration
                        forKey:MPMediaItemPropertyPlaybackDuration];
    [playingInfoDict setObject:elapsedPlaybackTime
                        forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [playingInfoDict setObject:@(_player.rate) forKey:MPNowPlayingInfoPropertyPlaybackRate];
    
    //音乐信息赋值给获取锁屏中心的nowPlayingInfo属性
    playingInfoCenter.nowPlayingInfo = playingInfoDict;
}

// 添加远程控制
- (void)createRemoteCommandCenter {
    
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    
    MPRemoteCommand *pauseCommand = [commandCenter pauseCommand];
    [pauseCommand setEnabled:YES];
    [pauseCommand addTarget:self action:@selector(remotePauseEvent)];
    
    MPRemoteCommand *playCommand = [commandCenter playCommand];
    [playCommand setEnabled:YES];
    [playCommand addTarget:self action:@selector(remotePlayEvent)];
    
    MPRemoteCommand *nextCommand = [commandCenter nextTrackCommand];
    [nextCommand setEnabled:YES];
    [nextCommand addTarget:self action:@selector(remoteNextEvent)];
    
    MPRemoteCommand *previousCommand = [commandCenter previousTrackCommand];
    [previousCommand setEnabled:YES];
    [previousCommand addTarget:self action:@selector(remotePreviousEvent)];
    
    if (@available(iOS 9.1, *)) {
        MPRemoteCommand *changePlaybackPositionCommand = [commandCenter changePlaybackPositionCommand];
        [changePlaybackPositionCommand setEnabled:YES];
        [changePlaybackPositionCommand addTarget:self action:@selector(remoteChangePlaybackPosition:)];
    }
}

- (void)remotePlayEvent {

    [self playVideo];
}

- (void)remotePauseEvent {
    
    [self pauseVideo];
}

- (void)remoteNextEvent {
    
    [self playNextVideo];
}

- (void)remotePreviousEvent {
    
    [self playPreviousVideo];
}

- (void)remoteChangePlaybackPosition:(MPRemoteCommandEvent *)event {
    
    MPChangePlaybackPositionCommandEvent * playbackPositionEvent = (MPChangePlaybackPositionCommandEvent *)event;
    [self seekToTime:playbackPositionEvent.positionTime];
}

- (void)removeCommandCenterTargets
{
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    [[commandCenter playCommand] removeTarget:self];
    [[commandCenter pauseCommand] removeTarget:self];
    [[commandCenter nextTrackCommand] removeTarget:self];
    [[commandCenter previousTrackCommand] removeTarget:self];
    
    if (@available(iOS 9.1, *)) {
        [commandCenter.changePlaybackPositionCommand removeTarget:self];
    }
}


#pragma mark - 按钮点击事件

- (IBAction)onBtnPlayClick:(id)sender {
    
    [self playVideo];
}

- (IBAction)onBtnPauseClick:(id)sender {

    [self pauseVideo];
}

- (IBAction)onBtnNextClick:(id)sender {
    
    [self playNextVideo];
}

- (IBAction)onBtnPreviousClick:(id)sender {
    
    [self playPreviousVideo];
}

#pragma mark - setter

- (void)setCurrentDuration:(NSTimeInterval)currentDuration {
    
    if (_currentDuration == currentDuration) {
        return;
    }
    
    _currentDuration = currentDuration;
    [self updateLockScreenInfo];
}

@end
