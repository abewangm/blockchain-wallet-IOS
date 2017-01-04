//
//  ReminderModalViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 12/14/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ReminderModalViewController.h"

@interface ReminderModalViewController ()
@property (nonatomic, readonly) ReminderType reminderType;
@end

@implementation ReminderModalViewController

- (id)initWithReminderType:(ReminderType)reminderType
{
    if (self = [super init]) {
        _reminderType = reminderType;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGFloat centerX = self.view.center.x;
    CGFloat centerY = self.view.center.y;
    
    UIButton *continueButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 240, 40)];
    continueButton.center = CGPointMake(centerX, self.view.frame.size.height - 100);
    continueButton.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
    continueButton.layer.cornerRadius = 8;
    [self.view addSubview:continueButton];
    
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 240, 40)];
    cancelButton.center = CGPointMake(centerX, self.view.frame.size.height - 50);
    cancelButton.backgroundColor = [UIColor whiteColor];
    [cancelButton setTitleColor:COLOR_TEXT_GRAY forState:UIControlStateNormal];
    [cancelButton setTitle:BC_STRING_ILL_DO_THIS_LATER forState:UIControlStateNormal];
    cancelButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    cancelButton.layer.cornerRadius = 16;
    [cancelButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cancelButton];
    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 46, 26, 20, 20)];
    [closeButton setImage:[UIImage imageNamed:@"close_large"] forState:UIControlStateNormal];
    closeButton.imageView.image = [closeButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [closeButton setTintColor:COLOR_BLOCKCHAIN_BLUE];
    [closeButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    
    UIImageView *iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    iconImageView.center = CGPointMake(centerX, centerY - 150);
    iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:iconImageView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, iconImageView.frame.origin.y + iconImageView.frame.size.height + 16, self.view.frame.size.width - 100, 30)];
    titleLabel.font = [UIFont boldSystemFontOfSize:20];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.center = CGPointMake(iconImageView.center.x, titleLabel.center.y);
    [self.view addSubview:titleLabel];
    
    UILabel *detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, titleLabel.frame.origin.y + titleLabel.frame.size.height + 8, 270, 200)];
    detailLabel.numberOfLines = 0;
    detailLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:detailLabel];
    
    if (self.reminderType == ReminderTypeEmail) {
        titleLabel.text = BC_STRING_REMINDER_CHECK_EMAIL_TITLE;
        detailLabel.text = BC_STRING_REMINDER_CHECK_EMAIL_MESSAGE;
        iconImageView.image = [UIImage imageNamed:@"email_square"];
        [continueButton setTitle:BC_STRING_GO_TO_MAIL forState:UIControlStateNormal];
        [continueButton addTarget:self action:@selector(openMail) forControlEvents:UIControlEventTouchUpInside];
    } else if (self.reminderType == ReminderTypeBackup) {
        titleLabel.text = BC_STRING_REMINDER_BACKUP_TITLE;
        detailLabel.text = BC_STRING_REMINDER_BACKUP_MESSAGE;
        iconImageView.image = [UIImage imageNamed:@"lock_large"];
        [continueButton setTitle:BC_STRING_BACKUP forState:UIControlStateNormal];
        [continueButton addTarget:self action:@selector(showBackup) forControlEvents:UIControlEventTouchUpInside];
    } else if (self.reminderType == ReminderTypeTwoFactor) {
        titleLabel.text = BC_STRING_REMINDER_TWO_FACTOR_TITLE;
        detailLabel.text = BC_STRING_REMINDER_TWO_FACTOR_MESSAGE;
        iconImageView.image = [UIImage imageNamed:@"mobile_large"];
        [continueButton setTitle:BC_STRING_ENABLE_TWO_STEP forState:UIControlStateNormal];
        [continueButton addTarget:self action:@selector(showTwoStep) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [detailLabel sizeToFit];
    detailLabel.center = CGPointMake(iconImageView.center.x, detailLabel.center.y);
}

- (void)openMail
{
    [self.delegate openMail];
}

- (void)showBackup
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate showBackup];
    }];
}

- (void)showTwoStep
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate showTwoStep];
    }];
}

- (void)close
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
