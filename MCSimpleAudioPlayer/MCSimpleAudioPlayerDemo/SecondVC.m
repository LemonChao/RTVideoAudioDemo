//
//  SecondVC.m
//  MCSimpleAudioPlayerDemo
//
//  Created by Lemon on 17/2/10.
//  Copyright © 2017年 Chengyin. All rights reserved.
//

#import "SecondVC.h"
#import "ViewController.h"

@interface SecondVC ()

@end

@implementation SecondVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (IBAction)jumpToCameraVC:(UIButton *)sender {
    
    ViewController *cameraVC = [[ViewController alloc] init];
    cameraVC.hidesBottomBarWhenPushed = YES;
    [self presentViewController:cameraVC animated:YES completion:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
