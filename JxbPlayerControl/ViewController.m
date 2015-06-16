//
//  ViewController.m
//  JxbPlayerControl
//
//  Created by Peter on 15/6/16.
//  Copyright (c) 2015年 Peter. All rights reserved.
//

#import "ViewController.h"
#import "JxbPlayer.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    JxbPlayer* jxb = [[JxbPlayer alloc] initWithMainColor:[UIColor redColor] frame:CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, 100)];
    jxb.itemUrl = @"http://stream.51voa.com/201506/se-health-south-korea-mers-15jun15.mp3";
    [self.view addSubview:jxb];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
