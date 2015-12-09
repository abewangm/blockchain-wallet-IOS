//
//  SettingsTwoStepViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 12/4/15.
//  Copyright © 2015 Qkos Services Ltd. All rights reserved.
//

#import "SettingsTwoStepViewController.h"

@implementation SettingsTwoStepViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.twoStepButton.layer.borderWidth = 0.5;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateUI];
}

- (void)updateUI
{
    if ([self.settingsController hasEnabledTwoStep]) {
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
