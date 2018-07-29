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

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Video Player";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        ESCImageVideoPlayViewController *viewController = [[ESCImageVideoPlayViewController alloc] init];
        [self.navigationController pushViewController:viewController animated:YES];
    }else if (indexPath.row == 1) {
        ESCRGBVideoPlayViewController *viewController = [[ESCRGBVideoPlayViewController alloc] init];
        [self.navigationController pushViewController:viewController animated:YES];
    }else if (indexPath.row == 2) {
        ESCYUV420VideoPlayViewController *viewController = [[ESCYUV420VideoPlayViewController alloc] init];
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

@end
