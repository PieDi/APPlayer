//
//  APPlayer.m
//  APPlayer
//
//  Created by lyc on 2017/9/8.
//  Copyright © 2017年 PieDi. All rights reserved.
//

#import "APPlayer.h"
#import "AppDelegate.h"


#define kHalfWidth self.frame.size.width * 0.5
#define kHalfHeight self.frame.size.height * 0.5
#define WS(weakSelf) __weak __typeof(&*self)weakSelf = self


static void *PlayViewCMTimeValue = &PlayViewCMTimeValue;

static void *PlayViewStatusObservationContext = &PlayViewStatusObservationContext;

@interface APPlayer ()<UIGestureRecognizerDelegate>


@property (nonatomic, assign)CGPoint firstPoint;
@property (nonatomic, assign)CGPoint secondPoint;
@property (nonatomic, retain)NSDateFormatter *dateFormatter;
//视频进度条的单击事件
@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (nonatomic, assign) CGPoint originalPoint;
@property (nonatomic, assign) BOOL isDragingSlider;//是否点击了按钮的响应事件
@property (nonatomic, strong) NSTimer  *mTimer;

/**
 * 亮度的进度条
 */
@property (nonatomic, retain) UISlider       *lightSlider;

@property (nonatomic,retain ) UISlider       *volumeSlider;

@property (nonatomic, assign) CMTime PauseTime;


@end

@implementation APPlayer{
    UISlider *systemSlider;
    UIWindow *mainWindow;
}

-(AVPlayerItem *)getPlayItemWithURLString:(NSString *)urlString{
    
    if ([urlString rangeOfString:@"http"].location!=NSNotFound) {
        AVPlayerItem *playerItem=[AVPlayerItem playerItemWithURL:[NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet] ]]];
        return playerItem;
    }else{
        AVAsset *movieAsset  = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:urlString] options:nil];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
        return playerItem;
    }
}

/**
 *  alloc init的初始化方法
 */
- (instancetype)init{
    self = [super init];
    if (self){
        [self initAPPlayer];
    }
    return self;
}
/**
 *  storyboard、xib的初始化方法
 */
- (void)awakeFromNib
{
    [super awakeFromNib];
    [self initAPPlayer];
}

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self initAPPlayer];
    }
    return self;
}
/**
 *  初始化WMPlayer的控件，添加手势，添加通知，添加kvo等
 */
-(void)initAPPlayer{
    
    mainWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    mainWindow.backgroundColor = [UIColor clearColor];
    
    self.backgroundColor = [UIColor blackColor];
    
    self.currentItem = [self getPlayItemWithURLString:self.URLString];
    //AVPlayer
    self.player = [AVPlayer playerWithPlayerItem:self.currentItem];
    if([[UIDevice currentDevice] systemVersion].intValue>=10){
        //      增加下面这行可以解决ios10兼容性问题了
        self.player.automaticallyWaitsToMinimizeStalling = NO;
    }
    
    //AVPlayerLayer
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = self.layer.bounds;
    [self.layer addSublayer:_playerLayer];
    
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    //bottomView
    self.bottomView = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetHeight(self.frame)-40, CGRectGetWidth(self.frame), 40)];
    self.bottomView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.54];
    [self addSubview:self.bottomView];
    
    self.playOrPauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playOrPauseBtn.frame = CGRectMake(0, 0, 40, 40);
    [self.playOrPauseBtn addTarget:self action:@selector(PlayOrPause:) forControlEvents:UIControlEventTouchUpInside];
    [self.playOrPauseBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    [self.playOrPauseBtn setImage:[UIImage imageNamed:@"play"] forState:UIControlStateSelected];
    [self.bottomView addSubview:self.playOrPauseBtn];
    
    
    self.playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playBtn.frame = CGRectMake(0, 0, 61, 61);
    [self.playBtn addTarget:self action:@selector(PlayOrPause:) forControlEvents:UIControlEventTouchUpInside];
    [self.playBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    [self.playBtn setImage:[UIImage imageNamed:@"play"] forState:UIControlStateSelected];
    self.playBtn.center = CGPointMake(CGRectGetWidth(self.frame)/2, CGRectGetHeight(self.frame)/2);
    [self addSubview:self.playBtn];
 
    
    
    //创建亮度的进度条
    self.lightSlider = [[UISlider alloc]initWithFrame:CGRectMake(CGRectGetWidth(self.frame)-20, 0, 20, CGRectGetHeight(self.frame))];
    self.lightSlider.hidden = YES;
    self.lightSlider.minimumValue = 0;
    self.lightSlider.maximumValue = 1;
    //     进度条的值等于当前系统亮度的值,范围都是0~1
    self.lightSlider.value = [UIScreen mainScreen].brightness;
//    [self addSubview:self.lightSlider];
    
    
    
    self.volumeSlider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, 20, CGRectGetHeight(self.frame))];
    self.volumeSlider.tag = 1000;
    self.volumeSlider.minimumValue = systemSlider.minimumValue;
    self.volumeSlider.maximumValue = systemSlider.maximumValue;
    self.volumeSlider.value = systemSlider.value;
    [self.volumeSlider addTarget:self action:@selector(updateSystemVolumeValue:) forControlEvents:UIControlEventValueChanged];
//    [self addSubview:self.volumeSlider];
    
    
    //slider
    self.progressSlider = [[UISlider alloc]initWithFrame:CGRectMake(45, 0, CGRectGetWidth(self.bottomView.frame)-90, 40)];
    self.progressSlider.minimumValue = 0.0;
    [self.progressSlider setThumbImage:[UIImage imageNamed:@"dot"] ?: [UIImage imageNamed:@"dot"]  forState:UIControlStateNormal];
    self.progressSlider.minimumTrackTintColor = [UIColor colorWithRed:255/255.0 green:189/255.0 blue:23/255.0 alpha:1.0];
    self.progressSlider.value = 0.0;//指定初始值
    //进度条的拖拽事件
    [self.progressSlider addTarget:self action:@selector(stratDragSlide:)  forControlEvents:UIControlEventValueChanged];
    
    //给进度条添加单击手势
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionTapGesture:)];
    self.tap.delegate = self;
    [self.progressSlider addGestureRecognizer:self.tap];
    
    [self.bottomView addSubview:self.progressSlider];
    
    //_fullScreenBtn
    self.fullScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.fullScreenBtn.frame = CGRectMake(CGRectGetWidth(self.bottomView.frame)-40, 0, 40, 40);
    [self.fullScreenBtn addTarget:self action:@selector(fullScreenAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.fullScreenBtn setImage:[UIImage imageNamed:@"fullscreen"] ?: [UIImage imageNamed:@"fullscreen"] forState:UIControlStateNormal];
    [self.fullScreenBtn setImage:[UIImage imageNamed:@"nonfullscreen"] ?: [UIImage imageNamed:@"nonfullscreen"] forState:UIControlStateSelected];
    [self.bottomView addSubview:self.fullScreenBtn];
    
    //timeLabel
    self.timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(45, 20, CGRectGetWidth(self.bottomView.frame)-90, 20)];
    self.timeLabel.textAlignment = NSTextAlignmentRight;
    self.timeLabel.textColor = [UIColor whiteColor];
    self.timeLabel.backgroundColor = [UIColor clearColor];
    self.timeLabel.font = [UIFont systemFontOfSize:11];
    [self.bottomView addSubview:self.timeLabel];
    
    
    [self bringSubviewToFront:self.bottomView];
    
    if (!self.closeBtn) {
        self.closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.closeBtn.frame = CGRectMake(5, 5, 30, 30);
        //    _closeBtn.showsTouchWhenHighlighted = YES;
        [self.closeBtn addTarget:self action:@selector(colseTheVideo:) forControlEvents:UIControlEventTouchUpInside];
        [self.closeBtn setImage:[UIImage imageNamed:@"ba_back"] ?: [UIImage imageNamed:@"ba_back"] forState:UIControlStateNormal];
        [self.closeBtn setImage:[UIImage imageNamed:@"ba_back"] ?: [UIImage imageNamed:@"ba_back"] forState:UIControlStateSelected];
        self.closeBtn.layer.cornerRadius = 30/2;
        [self addSubview:self.closeBtn];
        
    }
    
    // 单击的 Recognizer
    UITapGestureRecognizer* singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap)];
    singleTap.numberOfTapsRequired = 1; // 单击
    [self addGestureRecognizer:singleTap];
    
    
    [self.currentItem addObserver:self
                       forKeyPath:@"status"
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          context:PlayViewStatusObservationContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appwillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(updateOrientation:)
                                                name:UIDeviceOrientationDidChangeNotification object:nil];
    
    
    
    [self initTimer];
    
}





- (void)appDidEnterBackground:(NSNotification*)note
{
    NSLog(@"appDidEnterBackground");
    [self.durationTimer setFireDate:[NSDate date]];
    
    [self.player pause];
    self.playOrPauseBtn.selected = YES;
    self.playBtn.hidden = NO;
    self.playBtn.selected = YES;
}

- (void)appWillEnterForeground:(NSNotification*)note
{
    [self.durationTimer setFireDate:[NSDate date]];
    
    if (self.isPause) {
        [self.player pause];
        self.playOrPauseBtn.selected = YES;
        self.playBtn.hidden = NO;
        self.playBtn.selected = YES;
    }else{
        [self.player play];
        self.playOrPauseBtn.selected = NO;
        self.playBtn.hidden = YES;
        self.playBtn.selected = NO;
    }
}
- (void)appwillResignActive:(NSNotification *)note
{
}
- (void)appBecomeActive:(NSNotification *)note
{
    
}

//视频进度条的点击事件
- (void)actionTapGesture:(UITapGestureRecognizer *)sender {
    WS(weakSelf);
    CGPoint touchPoint = [sender locationInView:self.progressSlider];
    CGFloat value = (self.progressSlider.maximumValue - self.progressSlider.minimumValue) * (touchPoint.x / self.progressSlider.frame.size.width );
    [self.progressSlider setValue:value animated:YES];
    [self.player seekToTime:CMTimeMakeWithSeconds(self.progressSlider.value, 1.0 * NSEC_PER_SEC) completionHandler:^(BOOL finished) {
        
        
        if (weakSelf.isPause) {
            [weakSelf.player pause];
            weakSelf.playOrPauseBtn.selected = YES;
            weakSelf.playBtn.hidden = NO;
        }else{
            [weakSelf.player play];
            weakSelf.playOrPauseBtn.selected = NO;
            weakSelf.playBtn.hidden = YES;
        }
        
    }];
}

- (void)updateSystemVolumeValue:(UISlider *)slider{
    systemSlider.value = slider.value;
}
-(void)layoutSubviews{
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
}
#pragma mark
#pragma mark - fullScreenAction
-(void)fullScreenAction:(UIButton *)sender{
    sender.selected = !sender.selected;
    //用通知的形式把点击全屏的时间发送到app的任何地方，方便处理其他逻辑
    [[NSNotificationCenter defaultCenter] postNotificationName:APPlayerFullScreenButtonClickedNotification object:sender];
    if (sender.selected) {
        
        if ([UIDevice currentDevice].orientation == UIDeviceOrientationPortrait)
        {
//            [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationPortrait] forKey:@"orientation"];//这句话是防止手动先把设备置为横屏,导致下面的语句失效.
            [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationLandscapeLeft] forKey:@"orientation"];
            
            
            
            AppDelegate *mDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            NSLog(@"看看 变化  %@",NSStringFromCGRect(mDelegate.window.frame));
            
            
        }
        [self toFullScreenWithInterfaceOrientation:UIInterfaceOrientationLandscapeRight];
    }else{
        
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationPortrait] forKey:@"orientation"];
        [self toSmallScreen];
    }
}

#pragma mark 关闭播放器，在这里我们修改为返回
-(void)colseTheVideo:(UIButton *)sender{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:APPlayerBackNotification object:sender];
    
}
- (double)duration{
    AVPlayerItem *playerItem = self.player.currentItem;
    if (playerItem.status == AVPlayerItemStatusReadyToPlay){
        return CMTimeGetSeconds([[playerItem asset] duration]);
    }
    else{
        return 0.f;
    }
}

- (double)currentTime{
    if (self.player) {
        return CMTimeGetSeconds([[self player] currentTime]);
        
    }else{
        return 0.0;
    }
}

- (void)setCurrentTime:(double)time{
    [[self player] seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
}
#pragma mark
#pragma mark - PlayOrPause
- (void)PlayOrPause:(UIButton *)sender{
    
    if (self.durationTimer != nil) {
        
        [self.durationTimer invalidate];
        self.durationTimer = nil;
        self.durationTimer = [NSTimer timerWithTimeInterval:0.2 target:self selector:@selector(finishedPlay:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.durationTimer forMode:NSDefaultRunLoopMode];
    }
    
    if (self.player.rate != 1.f) {
        if ([self currentTime] == [self duration])
            [self setCurrentTime:0.f];
        sender.selected = NO;
        self.playOrPauseBtn.selected = NO;
        self.playBtn.hidden = YES;
        [self.player play];
        self.isPause = NO;
    } else {
        sender.selected = YES;
        self.playOrPauseBtn.selected = YES;
        self.playBtn.selected = YES;
        self.playBtn.hidden = NO;
        [self.player pause];
        self.isPause = YES;
    }
    
}
-(void)play{
    [self PlayOrPause:self.playOrPauseBtn];
}
-(void)pause{
    [self PlayOrPause:self.playOrPauseBtn];
}
#pragma mark - 单击手势方法
- (void)handleSingleTap{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:APPlayerSingleTapNotification object:nil];
    [self.autoDismissTimer invalidate];
    self.autoDismissTimer = nil;
    self.autoDismissTimer = [NSTimer timerWithTimeInterval:3.0 target:self selector:@selector(autoDismissBottomView:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.autoDismissTimer forMode:NSDefaultRunLoopMode];
    WS(weakSelf);
    [UIView animateWithDuration:0.5 animations:^{
        if (weakSelf.bottomView.alpha == 0.0) {
            weakSelf.bottomView.alpha = 1.0;
            weakSelf.closeBtn.alpha = 1.0;
            weakSelf.playBtn.alpha = 1.0;
        }else{
            weakSelf.bottomView.alpha = 0.0;
            weakSelf.closeBtn.alpha = 0.0;
            weakSelf.playBtn.alpha = 0.0;
        }
    } completion:^(BOOL finish){
        
    }];
}
#pragma mark
#pragma mark - 双击手势方法
//- (void)handleDoubleTap{
//    [[NSNotificationCenter defaultCenter] postNotificationName:WMPlayerDoubleTapNotification object:nil];
//    if (self.player.rate != 1.f) {
//        if ([self currentTime] == self.duration)
//            [self setCurrentTime:0.f];
//        [self.player play];
//        self.playOrPauseBtn.selected = NO;
//    } else {
//        [self.player pause];
//        self.playOrPauseBtn.selected = YES;
//    }
//}

/**
 *  重写videoURLStr的setter方法，处理自己的逻辑，
 */
#pragma mark
#pragma mark - 设置播放的视频
- (void)setURLString:(NSString *)URLString{
    _URLString = URLString;
    if (self.currentItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_currentItem];
        [self.currentItem removeObserver:self forKeyPath:@"status"];
        //        [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    }
    
    self.currentItem = [self getPlayItemWithURLString:URLString];
    [self.currentItem addObserver:self
                       forKeyPath:@"status"
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          context:PlayViewStatusObservationContext];
    
    [self.player replaceCurrentItemWithPlayerItem:self.currentItem];
    
}

#pragma mark- 开始点击sidle
- (void)stratDragSlide:(UISlider *)slider{
    
    [self.player pause];
    [self.mTimer invalidate];
    self.timeLabel.text = [NSString stringWithFormat:@"%@/%@",[self convertTime:slider.value],[self convertTime:[self.progressSlider maximumValue]]];
    self.mTimer = [NSTimer timerWithTimeInterval:0.5f
                                          target:self
                                        selector:@selector(updateProgress:)
                                        userInfo:slider
                                         repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:self.mTimer forMode:NSDefaultRunLoopMode];
}

#pragma mark - 播放进度
- (void)updateProgress:(NSTimer *)aTimer{
    
    UISlider *aSlider = (UISlider *)[aTimer userInfo];
    
    WS(weakSelf);
    [self.player seekToTime:CMTimeMakeWithSeconds(aSlider.value, 1 * NSEC_PER_SEC) completionHandler:^(BOOL finished) {
        if (weakSelf.isPause) {
            [weakSelf.player pause];
            weakSelf.playOrPauseBtn.selected = YES;
            weakSelf.playBtn.hidden = NO;
        }else{
            [weakSelf.player play];
            weakSelf.playOrPauseBtn.selected = NO;
            weakSelf.playBtn.hidden = YES;
        }
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    /* AVPlayerItem "status" property value observer. */
    if (context == PlayViewStatusObservationContext)
    {
        
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        AVPlayerItem *playItem = (AVPlayerItem *)object;
        NSError *error = playItem.error;
        
        
        switch (status)
        {
                /* Indicates that the status of the player is not yet known because
                 it has not tried to load new media resources for playback */
                
            case AVPlayerStatusUnknown:
            {
                if (error && error.code == -1009) {
                    
                    // 播放中失去连接
                    [[NSNotificationCenter defaultCenter]postNotificationName:APPlayerLostConnectNotification object:self.currentItem];
                }
                if (error) {
                    [[NSNotificationCenter defaultCenter]postNotificationName:APPlayerFailPlayNotification object:self.currentItem];
                }
                break;
            }
                
            case AVPlayerStatusReadyToPlay:
            {
                
                /* Once the AVPlayerItem becomes ready to play, i.e.
                 [playerItem status] == AVPlayerItemStatusReadyToPlay,
                 its duration can be fetched from the item. */
                if (CMTimeGetSeconds(self.player.currentItem.duration)) {
                    
                    double _x = CMTimeGetSeconds(self.player.currentItem.duration);
                    if (!isnan(_x)) {
                        self.progressSlider.maximumValue = CMTimeGetSeconds(self.player.currentItem.duration);
                    }
                }
                
                [self initTimer];
                if (self.durationTimer==nil) {
                    
                    self.durationTimer = [NSTimer timerWithTimeInterval:0.2 target:self selector:@selector(finishedPlay:) userInfo:nil repeats:YES];
                    [[NSRunLoop currentRunLoop] addTimer:self.durationTimer forMode:NSDefaultRunLoopMode];
                }
                
                //5s dismiss bottomView
                if (self.autoDismissTimer==nil) {
                    self.autoDismissTimer = [NSTimer timerWithTimeInterval:3.0 target:self selector:@selector(autoDismissBottomView:) userInfo:nil repeats:YES];
                    [[NSRunLoop currentRunLoop] addTimer:self.autoDismissTimer forMode:NSDefaultRunLoopMode];
                }
                break;
            }
                
            case AVPlayerStatusFailed:
            {
                NSLog(@"播放失败");
                if (error && error.code == -1009) {
                    // 播放中失去连接
                    [[NSNotificationCenter defaultCenter]postNotificationName:APPlayerLostConnectNotification object:self.currentItem];
                }else{
                    /* 视频播放失败 */
                    [[NSNotificationCenter defaultCenter]postNotificationName:APPlayerFailPlayNotification object:self.currentItem];
                }
                break;
            }
        }
    }
    
}
#pragma mark
#pragma mark finishedPlay
- (void)finishedPlay:(NSTimer *)timer{
    if (self.currentTime == self.duration&&self.player.rate==.0f) {
        //        self.playOrPauseBtn.selected = YES;
        //        self.playBtn.selected = YES;
        //        self.playBtn.hidden = NO;
        [self.durationTimer invalidate];
        self.durationTimer = nil;
    }
}
#pragma mark
#pragma mark autoDismissBottomView
-(void)autoDismissBottomView:(NSTimer *)timer{
    
    WS(weakSelf);
    if (self.player.rate==.0f&&self.currentTime != self.duration) {//暂停状态
        
    }else if(self.player.rate==1.0f){
        if (self.bottomView.alpha==1.0) {
            [UIView animateWithDuration:0.5 animations:^{
                weakSelf.bottomView.alpha = 0.0;
                weakSelf.closeBtn.alpha = 0.0;
                weakSelf.playBtn.alpha = 0.0;
                
            } completion:^(BOOL finish){
                
            }];
        }
    }
}
#pragma  maik - 定时器
-(void)initTimer{
    double interval = .1f;
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration))
    {
        return;
    }
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration))
    {
        CGFloat width = CGRectGetWidth([self.progressSlider bounds]);
        interval = 0.1f * duration / width;
    }
    __weak typeof(self) weakSelf = self;
    [weakSelf.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)  queue:NULL /* If you pass NULL, the main queue is used. */ usingBlock:^(CMTime time){
        [weakSelf syncScrubber];
    }];
    
}
- (void)syncScrubber{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)){
        self.progressSlider.minimumValue = 0.0;
        return;
    }
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)){
        float minValue = [self.progressSlider minimumValue];
        float maxValue = [self.progressSlider maximumValue];
        double time = CMTimeGetSeconds([self.currentItem currentTime]);
        self.timeLabel.text = [NSString stringWithFormat:@"%@/%@",[self convertTime:time],[self convertTime:duration]];
        
    
        if (self.isDragingSlider==YES) {//拖拽slider中，不更新slider的值
            
        }else if(self.isDragingSlider==NO){
            
            [self.progressSlider setValue:(maxValue - minValue) * time / duration + minValue];
        }
    }
}
/**
 *  跳到某个时间点播放
 *
 *  @param time 时间点、时刻
 */
- (void)seekToTimeToPlay:(double)time{
    if (self.player) {
        
        if (time>[self duration]) {
            time = [self duration];
        }
        
        if (self.player.rate != 1.f) {
            //            if ([self currentTime] == [self duration])
            //                [self setCurrentTime:0.f];
            [self.player play];
        }else{
            
        }
        WS(weakSelf);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.currentItem seekToTime:CMTimeMakeWithSeconds(time, 1.0 * NSEC_PER_SEC)];
        });
        
    }
}
- (CMTime)playerItemDuration{
    AVPlayerItem *playerItem = [self.player currentItem];
    //    NSLog(@"%ld",playerItem.status);
    if (playerItem.status == AVPlayerItemStatusReadyToPlay){
        return([playerItem duration]);
    }
    return(kCMTimeInvalid);
}
- (NSString *)convertTime:(CGFloat)second{
    
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    if (second/3600 >= 1) {
        [[self dateFormatter] setDateFormat:@"HH:mm:ss"];
    } else {
        [[self dateFormatter] setDateFormat:@"mm:ss"];
    }
    NSString *newTime = [[self dateFormatter] stringFromDate:d];
    return newTime;
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    return _dateFormatter;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    for(UITouch *touch in event.allTouches) {
        self.firstPoint = [touch locationInView:self];
    }
    self.volumeSlider.value = systemSlider.value;
    //记录下第一个点的位置,用于moved方法判断用户是调节音量还是调节视频
    self.originalPoint = self.firstPoint;


    UISlider *volumeSlider = (UISlider *)[self viewWithTag:1000];
    volumeSlider.value = systemSlider.value;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    
    for(UITouch *touch in event.allTouches) {
        self.secondPoint = [touch locationInView:self];
    }

    //判断是左右滑动还是上下滑动
    CGFloat verValue =fabs(self.originalPoint.y - self.secondPoint.y);
    CGFloat horValue = fabs(self.originalPoint.x - self.secondPoint.x);

    //如果竖直方向的偏移量大于水平方向的偏移量,那么是调节音量或者亮度
    if (verValue > horValue) {//上下滑动

        //判断是全屏模式还是正常模式
        if (self.isFullscreen) {//全屏下

            //判断刚开始的点是左边还是右边,左边控制音量
            if (self.originalPoint.x <= kHalfHeight) {//全屏下:point在view的左边(控制音量)

                /* 手指上下移动的计算方式,根据y值,刚开始进度条在0位置,当手指向上移动600个点后,当手指向上移动N个点的距离后,
                 当前的进度条的值就是N/600,600随开发者任意调整,数值越大,那么进度条到大1这个峰值需要移动的距离也变大,反之越小 */
                systemSlider.value += (self.firstPoint.y - self.secondPoint.y)/600.0;
                self.volumeSlider.value = systemSlider.value;
            }else{//全屏下:point在view的右边(控制亮度)
                //右边调节屏幕亮度
                self.lightSlider.value += (self.firstPoint.y - self.secondPoint.y)/600.0;
                [[UIScreen mainScreen] setBrightness:self.lightSlider.value];

            }
        }else{//非全屏

            //判断刚开始的点是左边还是右边,左边控制音量
            if (self.originalPoint.x <= kHalfWidth) {//非全屏下:point在view的左边(控制音量)

                /* 手指上下移动的计算方式,根据y值,刚开始进度条在0位置,当手指向上移动600个点后,当手指向上移动N个点的距离后,
                 当前的进度条的值就是N/600,600随开发者任意调整,数值越大,那么进度条到大1这个峰值需要移动的距离也变大,反之越小 */
                systemSlider.value += (self.firstPoint.y - self.secondPoint.y)/600.0;
                self.volumeSlider.value = systemSlider.value;
            }else{//非全屏下:point在view的右边(控制亮度)
                //右边调节屏幕亮度
                self.lightSlider.value += (self.firstPoint.y - self.secondPoint.y)/600.0;
                [[UIScreen mainScreen] setBrightness:self.lightSlider.value];

            }
        }
    }

    
    
    
    
    self.firstPoint = self.secondPoint;


    systemSlider.value += (self.firstPoint.y - self.secondPoint.y)/500.0;
    UISlider *volumeSlider = (UISlider *)[self viewWithTag:1000];
    volumeSlider.value = systemSlider.value;
    self.firstPoint = self.secondPoint;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    self.firstPoint = self.secondPoint = CGPointZero;
}


-(void)dealloc{
    
    NSLog(@"WMPlayer dealloc");
}


#pragma mark 小屏播放
-(void)toSmallScreen{
    
    AppDelegate *mDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    //放widow上
    WS(weakSelf);
    [self removeFromSuperview];
    self.backgroundColor = [UIColor blackColor];
    [UIView animateWithDuration:0.5f animations:^{
//        self.transform = CGAffineTransformIdentity;
        weakSelf.frame = CGRectMake(0, 64, kScreenWidth, 3*kScreenWidth/4);
        weakSelf.playerLayer.frame =  weakSelf.bounds;
        [mDelegate.window addSubview:weakSelf];
        weakSelf.bottomView.frame = CGRectMake(0, CGRectGetHeight(weakSelf.frame)-40, CGRectGetWidth(weakSelf.frame), 40);
        weakSelf.closeBtn.frame = CGRectMake(5, 5, 30, 30);
        weakSelf.playOrPauseBtn.frame = CGRectMake(0, 0, 40, 40);
        weakSelf.progressSlider.frame = CGRectMake(45, 0, CGRectGetWidth(weakSelf.bottomView.frame)-90, 40);
        weakSelf.fullScreenBtn.frame = CGRectMake(CGRectGetWidth(weakSelf.bottomView.frame)-40, 0, 40, 40);
        weakSelf.timeLabel.frame = CGRectMake(45, 20, CGRectGetWidth(weakSelf.bottomView.frame)-90, 20);
        weakSelf.playBtn.center = CGPointMake(CGRectGetWidth(weakSelf.frame)/2, CGRectGetHeight(weakSelf.frame)/2);
        
    }completion:^(BOOL finished) {
        weakSelf.isFullscreen = NO;
        weakSelf.fullScreenBtn.selected = NO;
        weakSelf.isSmallScreen = YES;
        [mDelegate.window bringSubviewToFront:weakSelf];
    }];
    
}

// 全屏播放
-(void)toFullScreenWithInterfaceOrientation:(UIInterfaceOrientation )interfaceOrientation{
    
    [self removeFromSuperview];
    [self pause];
    self.backgroundColor = [UIColor blackColor];
    
    
    self.frame = CGRectMake(0, 0, kScreenWidth,kScreenHeight);
    self.playerLayer.frame = self.bounds;
    self.playBtn.center = CGPointMake(kScreenWidth/2, kScreenHeight/2);
    
    
    self.bottomView.frame = CGRectMake(0, kScreenHeight-40, kScreenWidth, 40);
    self.playOrPauseBtn.frame = CGRectMake(0, 0, 40, 40);
    self.progressSlider.frame = CGRectMake(45, 0, CGRectGetWidth(self.bottomView.frame)-90, 40);
    self.fullScreenBtn.frame = CGRectMake(CGRectGetWidth(self.bottomView.frame)-40, 0, 40, 40);
    self.timeLabel.frame = CGRectMake(45, 20, CGRectGetWidth(self.bottomView.frame)-90, 20);
    
    self.closeBtn.frame = CGRectMake(5, 5, 30, 30);
    
    [self play];
    AppDelegate *mDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [mDelegate.window addSubview:self];
    self.isFullscreen = YES;
    self.isSmallScreen = NO;
    [self bringSubviewToFront:self.bottomView];
    
}



-(void)updateOrientation:(NSNotification *)notifi{
    
    UIDevice *currentDevice = [UIDevice currentDevice];
    BOOL mYes = kScreenWidth > kScreenHeight; // 横屏
    if (currentDevice.orientation == UIDeviceOrientationLandscapeLeft || currentDevice.orientation == UIDeviceOrientationLandscapeRight || mYes) {
        [self toFullScreenWithInterfaceOrientation:UIInterfaceOrientationUnknown];
    }else{
        [self toSmallScreen];
    }
}






/**
 *  释放WMPlayer
 */
-(void)releaseAPPlayer{
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.currentItem removeObserver:self forKeyPath:@"status"];
    
    [self.player pause];
    [self.player.currentItem cancelPendingSeeks];
    [self.player.currentItem.asset cancelLoading];
    [self pause];
    //移除观察者
    [self.playerLayer removeFromSuperlayer];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
        obj = nil;
    }];
    [self removeFromSuperview];
    
    self.player = nil;
    self.currentItem = nil;
    //释放定时器，否侧不会调用WMPlayer中的dealloc方法
    [self.autoDismissTimer invalidate];
    self.autoDismissTimer = nil;
    [self.durationTimer invalidate];
    self.durationTimer = nil;
    [self.mTimer invalidate];
    self.mTimer = nil;
    
    self.playOrPauseBtn = nil;
    self.playBtn = nil;
    self.playerLayer = nil;
    
    
   

    NSLog(@" 播放器释放");
    
}






@end
