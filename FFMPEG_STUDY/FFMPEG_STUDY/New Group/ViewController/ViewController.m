//
//  ViewController.m
//  FFMPEG_STUDY
//
//  Created by xiangmingsheng on 2017/6/15.
//  Copyright © 2017年 XMSECODE. All rights reserved.
//

#import "ViewController.h"
#import "ESCImageVideoPlayViewController.h"
#import "ESCRGBVideoPlayViewController.h"
#import "ESCYUV420VideoPlayViewController.h"
#import "ESCYUV420MetalVideoPlayViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Video Player";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"test_540p.mp4" ofType:nil];
//    NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"test_720p.mp4" ofType:nil];
    NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"test_1080p.mp4" ofType:nil];
//    NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"demo.mp4" ofType:nil];
//    NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"IMG_2123.mp4" ofType:nil];
    
    if (indexPath.row == 0) {
        ESCImageVideoPlayViewController *viewController = [[ESCImageVideoPlayViewController alloc] init];
        viewController.videoPath = videoPath;
        [self.navigationController pushViewController:viewController animated:YES];
    }else if (indexPath.row == 1) {
        ESCRGBVideoPlayViewController *viewController = [[ESCRGBVideoPlayViewController alloc] init];
        viewController.videoPath = videoPath;
        [self.navigationController pushViewController:viewController animated:YES];
    }else if (indexPath.row == 2) {
        ESCYUV420VideoPlayViewController *viewController = [[ESCYUV420VideoPlayViewController alloc] init];
        viewController.videoPath = videoPath;
        [self.navigationController pushViewController:viewController animated:YES];
    }else if (indexPath.row == 3) {
        ESCYUV420MetalVideoPlayViewController *viewController = [[ESCYUV420MetalVideoPlayViewController alloc] init];
        viewController.videoPath = videoPath;
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

@end
