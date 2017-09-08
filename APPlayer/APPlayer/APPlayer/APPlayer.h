//
//  APPlayer.h
//  APPlayer
//
//  Created by lyc on 2017/9/8.
//  Copyright © 2017年 PieDi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>


/**
 *  全屏按钮被点击的通知
 */
#define APPlayerFullScreenButtonClickedNotification @"APPlayerFullScreenButtonClickedNotification"
/**
 *  关闭播放器的通知
 */
#define APPlayerClosedNotification @"APPlayerClosedNotification"

/* 播放器返回的通知 */

#define APPlayerBackNotification @"APPlayerBackNotification"

/**
 *  播放完成的通知
 */
#define APPlayerFinishedPlayNotification @"APPlayerFinishedPlayNotification"
/**
 *  单击播放器view的通知
 */
#define APPlayerSingleTapNotification @"APPlayerSingleTapNotification"
/**
 *  双击播放器view的通知
 */
#define APPlayerDoubleTapNotification @"APPlayerDoubleTapNotification"

/* 视频播放失败 */
#define APPlayerFailPlayNotification @"APPlayerFailPlayNotification"

/*  播放失去网络连接 */
#define APPlayerLostConnectNotification @"APPlayerLostConnectNotification"

#define kScreenWidth          [[UIScreen mainScreen] bounds].size.width
#define kScreenHeight         [[UIScreen mainScreen] bounds].size.height

// 播放器的几种状态
typedef NS_ENUM(NSInteger, APPlayerState) {
    APPlayerStateFailed,     // 播放失败
    APPlayerStateBuffering,  // 缓冲中
    APPlayerStatePlaying,    // 播放中
    APPlayerStateStopped,    // 停止播放
    APPlayerStatePause       // 暂停播放
};

@interface APPlayer : UIView


/**
 *  播放器player
 */
@property (nonatomic,retain ) AVPlayer       *player;
/**
 *playerLayer,可以修改frame
 */
@property (nonatomic,retain ) AVPlayerLayer  *playerLayer;

/** 播放器的几种状态 */
@property (nonatomic, assign) APPlayerState   state;

/**
 *  底部操作工具栏
 */
@property (nonatomic,retain ) UIView         *bottomView;

/**
 *  定时器
 */
@property (nonatomic, retain) NSTimer        *durationTimer;
@property (nonatomic, retain) NSTimer        *autoDismissTimer;
/**
 *  BOOL值判断当前的状态
 */
@property (nonatomic, assign) BOOL           isFullscreen; //全屏播放
@property (nonatomic, assign) BOOL            isSmallScreen; //小屏播放

@property (nonatomic, assign) BOOL isPause;   //是否是暂停
/**
 *  控制全屏的按钮
 */
@property (nonatomic,retain ) UIButton       *fullScreenBtn;
/**
 *  播放暂停按钮
 */
@property (nonatomic,retain ) UIButton       *playOrPauseBtn;
/**
 *  关闭按钮
 */
@property (nonatomic,retain ) UIButton       *closeBtn;

/**
 *  当前播放的item
 */
@property (nonatomic, retain) AVPlayerItem   *currentItem;


@property (nonatomic, strong) UIButton *playBtn;/*  全屏后显示的按钮 */


@property (nonatomic, strong) UILabel *hitLabel; /* 提示文字 */
/**
 *  显示播放时间的UILabel
 */
@property (nonatomic,retain ) UILabel        *timeLabel;

@property (nonatomic,retain ) UISlider       *progressSlider;
/**
 *  BOOL值判断当前的播放状态
 */
//@property (nonatomic,assign ) BOOL            isPlaying;
/**
 *  设置播放的USRLString，可以是本地的路径也可以是http的网络路径
 */
@property (nonatomic,copy   ) NSString       *URLString;

- (void)play;
- (void)pause;
/**
 *  跳到time处播放
 *  @param time time这个时刻，这个时间点
 */
- (void)seekToTimeToPlay:(double)time;
/**
 *  获取正在播放的时间点
 *
 *  @return double的一个时间点
 */
- (double)currentTime;


-(void)toSmallScreen; //小屏播放操作
-(void)toFullScreenWithInterfaceOrientation:(UIInterfaceOrientation )interfaceOrientation; //全屏播放


-(void)releaseAPPlayer; /* 释放播放器 */

@end
