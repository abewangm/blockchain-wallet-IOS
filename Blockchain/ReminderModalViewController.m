//
//  ReminderModalViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 12/14/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ReminderModalViewController.h"

@interface ReminderModalViewController ()

@end

@implementation ReminderModalViewController

- (void)viewDidLoad {

    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGFloat centerX = self.view.center.x;
    UIButton *continueButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 240, 40)];
    continueButton.center = CGPointMake(centerX, self.view.frame.size.height - 100);
    continueButton.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
    [continueButton setTitle:BC_STRING_CONTINUE forState:UIControlStateNormal];
    [self.view addSubview:continueButton];
    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 56, 36, 40, 40)];
    [closeButton setImage:[UIImage imageNamed:@"cancel_template"] forState:UIControlStateNormal];
    closeButton.imageView.image = [closeButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [closeButton setTintColor:COLOR_BLOCKCHAIN_BLUE];
    [self.view addSubview:closeButton];
    [closeButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
}

- (void)close
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
