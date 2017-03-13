//
//  ViewController.m
//  MCSimpleAudioPlayerDemo
//
//  Created by Chengyin on 14-7-29.
//  Copyright (c) 2014年 Chengyin. All rights reserved.
//

#import "ViewController.h"
#import "MCSimpleAudioPlayer.h"
#import "NSTimer+BlocksSupport.h"

#import "RTAVSession.h"
#import "RTAVVideoConfiguration.h"

@interface ViewController ()
{
@private
    MCSimpleAudioPlayer *_player;
    
    //
    RTAVSession  * session;

}
@end

@implementation ViewController

#pragma mark - lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    if (!_player)
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"MP3Sample" ofType:@"mp3"];
        _player = [[MCSimpleAudioPlayer alloc] initWithFilePath:path fileType:kAudioFileMP3Type];
        
    }
    [_player play];

    //kRTVideoQuality_HD_Low 1280x720
    //kRTVideoQuality_Common_Medium123 640x480

    session = [[RTAVSession alloc]initWithRTAVVideoConfiguration:[RTAVVideoConfiguration defaultConfigurationForQuality:kRTVideoQuality_HD_Low]];
    
    session.preView = self.view;
    
    session.running = YES;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.titleLabel.text = @" 返 回 ";
    button.backgroundColor = [UIColor redColor];
    [button setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(goToBack) forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(100, 100, 68, 68);
    [self.view addSubview:button];


}


- (void)goToBack {
    
    [session takePholtoWithParam];
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
