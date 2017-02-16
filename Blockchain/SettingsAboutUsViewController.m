//
//  SettingsAboutUsViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 11/7/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "SettingsAboutUsViewController.h"
#import "RootService.h"

@interface SettingsAboutUsViewController ()
@end

@implementation SettingsAboutUsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 80, 15, 80, 51)];
    closeButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 20);
    closeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [closeButton setImage:[[UIImage imageNamed:@"close"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    closeButton.imageView.tintColor = COLOR_BLOCKCHAIN_BLUE;
    closeButton.center = CGPointMake(closeButton.center.x, closeButton.center.y);
    [closeButton addTarget:self action:@selector(closeButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    CGFloat imageWidth = self.view.frame.size.width - 120;
    
    UIImageView *logoImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - imageWidth)/2, 100, imageWidth, 80)];
    logoImageView.image = [UIImage imageNamed:@"logo_large"];
    logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:logoImageView];
    
    UIImageView *bannerImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - imageWidth)/2, logoImageView.frame.origin.y + logoImageView.frame.size.height + 16, imageWidth, 50)];
    bannerImageView.image = [UIImage imageNamed:@"text"];
    bannerImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:bannerImageView];
    
    CGFloat labelWidth = self.view.frame.size.width - 30;

    UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.frame.size.width - labelWidth)/2, bannerImageView.frame.origin.y + bannerImageView.frame.size.height + 16, labelWidth, 90)];
    infoLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:15];
    infoLabel.textAlignment = NSTextAlignmentCenter;
    infoLabel.textColor = COLOR_BLOCKCHAIN_BLUE;
    infoLabel.numberOfLines = 3;
    infoLabel.text = [NSString stringWithFormat:@"%@ %@\n%@\n%@", ABOUT_STRING_BLOCKCHAIN_WALLET, [app getVersionLabelString], [NSString stringWithFormat:@"%@ %@ %@", ABOUT_STRING_COPYRIGHT_LOGO, COPYRIGHT_YEAR, ABOUT_STRING_BLOCKCHAIN_LUXEMBOURG_SA], BC_STRING_BLOCKCHAIN_ALL_RIGHTS_RESERVED];
    
    [self.view addSubview:infoLabel];
    
    [self addButtonsWithWidth:labelWidth - 30 belowView:infoLabel];
}

- (void)addButtonsWithWidth:(CGFloat)buttonWidth belowView:(UIView *)aboveView
{
    UIButton *rateUsButton = [[UIButton alloc] initWithFrame:CGRectMake((self.view.frame.size.width - buttonWidth)/2, aboveView.frame.origin.y + aboveView.frame.size.height + 16, buttonWidth, 40)];
    rateUsButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [rateUsButton setTitleColor:COLOR_BLOCKCHAIN_BLUE forState:UIControlStateNormal];
    rateUsButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:15];
    [rateUsButton setTitle:BC_STRING_RATE_US forState:UIControlStateNormal];
    [self.view addSubview:rateUsButton];
    [rateUsButton addTarget:self action:@selector(rateApp) forControlEvents:UIControlEventTouchUpInside];
}

- (void)rateApp
{
    [app rateApp];
}

- (void)closeButtonClicked
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
