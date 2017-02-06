//
//  SettingsNavigationController.m
//  Blockchain
//
//  Created by Kevin Wu on 7/13/15.
//  Copyright (c) 2015 Blockchain Luxembourg S.A. All rights reserved.
//

#import "SettingsNavigationController.h"
#import "SettingsTableViewController.h"
#import "RootService.h"

@interface SettingsNavigationController ()
@end

@implementation SettingsNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.frame = CGRectMake(0, 0, app.window.frame.size.width, app.window.frame.size.height);
    
    UIView *topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, DEFAULT_HEADER_HEIGHT)];
    topBar.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
    [self.view addSubview:topBar];
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 17.5, self.view.frame.size.width - 160, 40)];
    headerLabel.font = [UIFont systemFontOfSize:22.0];
    headerLabel.textColor = [UIColor whiteColor];
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.adjustsFontSizeToFitWidth = YES;
    headerLabel.text = BC_STRING_SETTINGS;
    [topBar addSubview:headerLabel];
    self.headerLabel = headerLabel;
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    backButton.contentEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
    [backButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
    [backButton setImage:[UIImage imageNamed:@"back_chevron_icon"] forState:UIControlStateNormal];
    [backButton setTitleColor:[UIColor colorWithWhite:0.56 alpha:1.0] forState:UIControlStateHighlighted];
    [backButton addTarget:self action:@selector(backButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:backButton];
    self.backButton = backButton;
    
    BCFadeView *busyView = [[BCFadeView alloc] initWithFrame:app.window.rootViewController.view.frame];
    busyView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
    UIView *textWithSpinnerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 250, 110)];
    textWithSpinnerView.backgroundColor = [UIColor whiteColor];
    [busyView addSubview:textWithSpinnerView];
    textWithSpinnerView.center = busyView.center;
    
    UILabel *busyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, BUSY_VIEW_LABEL_WIDTH, BUSY_VIEW_LABEL_HEIGHT)];
    busyLabel.adjustsFontSizeToFitWidth = YES;
    busyLabel.font = [UIFont systemFontOfSize:BUSY_VIEW_LABEL_FONT_SYSTEM_SIZE];
    busyLabel.alpha = BUSY_VIEW_LABEL_ALPHA;
    busyLabel.textAlignment = NSTextAlignmentCenter;
    busyLabel.text = BC_STRING_LOADING_SYNCING_WALLET;
    busyLabel.center = CGPointMake(textWithSpinnerView.bounds.origin.x + textWithSpinnerView.bounds.size.width/2, textWithSpinnerView.bounds.origin.y + textWithSpinnerView.bounds.size.height/2 + 15);
    [textWithSpinnerView addSubview:busyLabel];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.center = CGPointMake(textWithSpinnerView.bounds.origin.x + textWithSpinnerView.bounds.size.width/2, textWithSpinnerView.bounds.origin.y + textWithSpinnerView.bounds.size.height/2 - 15);
    [textWithSpinnerView addSubview:spinner];
    [textWithSpinnerView bringSubviewToFront:spinner];
    [spinner startAnimating];

    busyView.containerView = textWithSpinnerView;
    [busyView fadeOut];
    
    [self.view addSubview:busyView];
    
    [self.view bringSubviewToFront:busyView];
    
    self.busyView = busyView;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    if (self.viewControllers.count == 1) {
        self.backButton.frame = CGRectMake(self.view.frame.size.width - 80, 15, 80, 51);
        self.backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        self.backButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        [self.backButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0)];
        [self.backButton setTitle:BC_STRING_CLOSE forState:UIControlStateNormal];
        [self.backButton setImage:nil forState:UIControlStateNormal];
    } else {
        self.backButton.frame = CGRectMake(0, 12, 85, 51);
        self.backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [self.backButton setTitle:@"" forState:UIControlStateNormal];
        [self.backButton setImage:[UIImage imageNamed:@"back_chevron_icon"] forState:UIControlStateNormal];
    }
}

- (void)backButtonClicked:(UIButton *)sender
{
    if ([self.visibleViewController isMemberOfClass:[SettingsTableViewController class]]) {
        [self dismissViewControllerAnimated:YES completion:nil];
        app.topViewControllerDelegate = nil;
    } else {
        [self popViewControllerAnimated:YES];
    }
}

- (void)reload
{
    [self.busyView fadeOut];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_RELOAD_SETTINGS_AND_SECURITY_CENTER object:nil];
}

- (void)reloadAfterMultiAddressResponse
{
    [self.busyView fadeOut];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_RELOAD_SETTINGS_AND_SECURITY_CENTER_AFTER_MULTIADDRESS object:nil];
}

- (void)showSettings
{
    [self popToRootViewControllerAnimated:NO];
}

- (void)showBackup
{
    if ([self.visibleViewController isMemberOfClass:[SettingsTableViewController class]]) {
        SettingsTableViewController *tableViewController = (SettingsTableViewController *)self.visibleViewController;
        [tableViewController showBackup];
    } else {
        DLog(@"Error: Settings Navigation Controller's visible view controller is not a SettingsTableViewController!");
    }
}

- (void)showTwoStep
{
    if ([self.visibleViewController isMemberOfClass:[SettingsTableViewController class]]) {
        SettingsTableViewController *tableViewController = (SettingsTableViewController *)self.visibleViewController;
        [tableViewController showTwoStep];
    } else {
        DLog(@"Error: Settings Navigation Controller's visible view controller is not a SettingsTableViewController!");
    }
}

#pragma mark Top View Controller Delegate

- (void)showBusyViewWithLoadingText:(NSString *)text
{
    //TODO: use this delegate method instead of handling busy views manually from view controllers
    return;
}

- (void)updateBusyViewLoadingText:(NSString *)text
{
    //TODO: use this delegate method instead of handling busy views manually from view controllers
    return;
}

- (void)hideBusyView
{
    //TODO: use this delegate method instead of handling busy views manually from view controllers
    return;
}

- (void)presentAlertController:(UIAlertController *)alertController
{
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
