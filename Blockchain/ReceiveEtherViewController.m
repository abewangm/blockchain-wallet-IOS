//
//  ReceiveEtherViewController.m
//  Blockchain
//
//  Created by kevinwu on 8/31/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ReceiveEtherViewController.h"
#import "RootService.h"

@interface ReceiveEtherViewController ()

@end

@implementation ReceiveEtherViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGFloat statusBarAdjustment = [[UIApplication sharedApplication] statusBarFrame].size.height > DEFAULT_STATUS_BAR_HEIGHT ? DEFAULT_STATUS_BAR_HEIGHT : 0;

    self.view.frame = CGRectMake(0,
                                 TAB_HEADER_HEIGHT_DEFAULT - TAB_HEADER_HEIGHT_SMALL_OFFSET - DEFAULT_HEADER_HEIGHT,
                                 [UIScreen mainScreen].bounds.size.width,
                                 [UIScreen mainScreen].bounds.size.height - (TAB_HEADER_HEIGHT_DEFAULT - TAB_HEADER_HEIGHT_SMALL_OFFSET) - DEFAULT_FOOTER_HEIGHT - statusBarAdjustment);
    
    CGFloat imageWidth = 120;
    
    UIView *qrCodeView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 120 - 12, imageWidth, imageWidth)];
    qrCodeView.center = CGPointMake(self.view.center.x, self.view.frame.size.height/2);
    [self.view addSubview:qrCodeView];
}

@end
