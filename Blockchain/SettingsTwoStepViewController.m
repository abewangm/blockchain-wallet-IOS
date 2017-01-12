//
//  SettingsTwoStepViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 12/4/15.
//  Copyright © 2015 Blockchain Luxembourg S.A. All rights reserved.
//

#import "SettingsTwoStepViewController.h"
#import "RootService.h"

@implementation SettingsTwoStepViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.twoStepButton.layer.borderWidth = 0.5;
    self.twoStepButton.titleEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 20);
    self.twoStepButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.twoStepButton.titleLabel.textAlignment = NSTextAlignmentCenter;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateUI];
}

- (void)updateUI
{
    if ([app.wallet hasEnabledTwoStep]) {
        [self.twoStepButton setTitle:BC_STRING_DISABLE forState:UIControlStateNormal];
    } else {
        [self.twoStepButton setTitle:BC_STRING_ENABLE_TWO_STEP_SMS forState:UIControlStateNormal];
    }
}

- (IBAction)twoStepTapped:(UIButton *)sender
{
    [self.settingsController changeTwoStepTapped];
}

@end
