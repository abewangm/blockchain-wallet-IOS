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
    self.view.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
    
    UIImageView *logoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, 150)];
    logoImageView.image = [UIImage imageNamed:@"blockchain_wallet_logo"];
    logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:logoImageView];
    
    CGFloat labelWidth = self.view.frame.size.width - 30;

    UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.frame.size.width - labelWidth)/2, logoImageView.frame.origin.y + logoImageView.frame.size.height + 16, labelWidth, 90)];
    infoLabel.textAlignment = NSTextAlignmentCenter;
    infoLabel.textColor = [UIColor whiteColor];
    infoLabel.numberOfLines = 3;
    infoLabel.text = [NSString stringWithFormat:@"%@ %@\n%@\n%@", BC_STRING_BLOCKCHAIN_WALLET, [app getVersionLabelString], [NSString stringWithFormat:@"%@ %@ %@", BC_STRING_COPYRIGHT_LOGO, COPYRIGHT_YEAR, BC_STRING_BLOCKCHAIN_LUXEMBOURG_SA], BC_STRING_BLOCKCHAIN_ALL_RIGHTS_RESERVED];
    [self.view addSubview:infoLabel];
}

@end
