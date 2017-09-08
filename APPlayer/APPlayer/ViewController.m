//
//  ViewController.m
//  APPlayer
//
//  Created by lyc on 2017/9/8.
//  Copyright © 2017年 PieDi. All rights reserved.
//

#import "ViewController.h"
#import "APPlayer.h"
#import "AppDelegate.h"

@interface ViewController (){
    APPlayer *apPlayer;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    

    
}

- (IBAction)playAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        if (apPlayer.isSmallScreen) {
            [apPlayer releaseAPPlayer];
        }
        if (apPlayer) {
            [apPlayer removeFromSuperview];
            [apPlayer releaseAPPlayer];
        }
        apPlayer = [[APPlayer alloc]initWithFrame:CGRectMake(0, 64, kScreenWidth, 3*kScreenWidth/4)];
        apPlayer.URLString = @"http://media.okcom.com/sulaiomalu.mp4";
        [apPlayer play];
        apPlayer.closeBtn.hidden = YES;
        apPlayer.isSmallScreen = NO;
        [self.view addSubview:apPlayer];
        [self.view bringSubviewToFront:apPlayer];
    }else{
        [apPlayer releaseAPPlayer];
    }
    
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle { //设置样式
    
    return UIStatusBarStyleLightContent;
    
}

- (BOOL)prefersStatusBarHidden {
    //设置隐藏显示
    return NO;
    
}







- (BOOL)shouldAutorotate {
    return YES;
}
//返回直接支持的方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}
//返回最优先显示的屏幕方向
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}




@end
