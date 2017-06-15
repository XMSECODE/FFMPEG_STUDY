//
//  ViewController.m
//  FFMPEG_STUDY
//
//  Created by xiangmingsheng on 2017/6/15.
//  Copyright © 2017年 XMSECODE. All rights reserved.
//

#import "ViewController.h"
#import "avformat.h"
#import "avcodec.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    av_register_all();
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
