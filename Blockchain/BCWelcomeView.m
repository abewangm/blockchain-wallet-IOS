//
//  WelcomeView.m
//  Blockchain
//
//  Created by Mark Pfluger on 9/23/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "BCWelcomeView.h"
#import "AppDelegate.h"
#import "LocalizationConstants.h"

#define BUTTON_HEIGHT 40

@implementation BCWelcomeView

UIImageView *imageView;
Boolean shouldShowAnimation;

-(id)init
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UIWindow *window = appDelegate.window;
    
    shouldShowAnimation = true;
    
    self = [super initWithFrame:CGRectMake(0, 0, window.frame.size.width, window.frame.size.height - 20)];
    
    if (self) {
        self.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
        
        // Logo
        UIImage *logo = [UIImage imageNamed:@"welcome_logo"];
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake((window.frame.size.width -logo.size.width) / 2, 80, logo.size.width, logo.size.height)];
        imageView.image = logo;
        imageView.alpha = 0;
        
        [self addSubview:imageView];
        
        // Buttons
        self.createWalletButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.createWalletButton.frame = CGRectMake(40, self.frame.size.height - 220, 240, BUTTON_HEIGHT);
        self.createWalletButton.layer.cornerRadius = 16;
        self.createWalletButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
        self.createWalletButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        [self.createWalletButton setTitleColor:COLOR_BLOCKCHAIN_BLUE forState:UIControlStateNormal];
        [self.createWalletButton setTitle:[BC_STRING_CREATE_NEW_WALLET uppercaseString] forState:UIControlStateNormal];
        [self.createWalletButton setBackgroundColor:[UIColor whiteColor]];
        [self addSubview:self.createWalletButton];
        self.createWalletButton.enabled = NO;
        self.createWalletButton.alpha = 0.0;
        
        self.existingWalletButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.existingWalletButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
        self.existingWalletButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        [self.existingWalletButton setTitle:BC_STRING_LOG_IN_TO_WALLET forState:UIControlStateNormal];
        self.existingWalletButton.frame = CGRectMake(20, self.frame.size.height - 160, 280, BUTTON_HEIGHT);
        [self.existingWalletButton setBackgroundColor:COLOR_BLOCKCHAIN_BLUE];
        [self addSubview:self.existingWalletButton];
        self.existingWalletButton.enabled = NO;
        self.existingWalletButton.alpha = 0.0;
        
        // Version
        [self setupVersionLabel];
    }
    
    return self;
}

- (void)didMoveToSuperview
{
    // If the animation has started already, don't show it again until init is called again
    if (!shouldShowAnimation) {
        return;
    }
    shouldShowAnimation = false;
    
    // Some nice animations
    [UIView animateWithDuration:2*ANIMATION_DURATION
                     animations:^{
                         // Fade in logo
                         imageView.alpha = 1.0;
                         
                         // Fade in controls
                         self.createWalletButton.alpha = 1.0;
                         self.existingWalletButton.alpha = 1.0;
                     }
                     completion:^(BOOL finished){
                         // Activate controls
                         self.createWalletButton.enabled = YES;
                         self.existingWalletButton.enabled = YES;
                     }];
}

- (void)setupVersionLabel
{
    UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, self.frame.size.height - 30, self.frame.size.width - 30, 20)];
    versionLabel.font = [UIFont systemFontOfSize:12];
    versionLabel.textAlignment = NSTextAlignmentRight;
    versionLabel.textColor = [UIColor whiteColor];
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *version = infoDictionary[@"CFBundleShortVersionString"];
    versionLabel.text = [NSString stringWithFormat:@"v%@", version];
    [self addSubview:versionLabel];
    
    [self addLongPressGestureToShowBundleShortNameAlertToLabel:versionLabel];
}

- (void)addLongPressGestureToShowBundleShortNameAlertToLabel:(UILabel *)label
{
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPressGesture.minimumPressDuration = 1.0;
    [label addGestureRecognizer:longPressGesture];
    label.userInteractionEnabled = YES;
}

- (void)showBundleShortNameAlert
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *bundleShortName = infoDictionary[@"CFBundleName"];
    NSString *bundleVersion = infoDictionary[@"CFBundleVersion"];
    NSString *bundleShortVersionString = infoDictionary[@"CFBundleShortVersionString"];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:bundleShortName message:[[NSString alloc] initWithFormat:@"%@\nv%@", bundleVersion, bundleShortVersionString] delegate:nil cancelButtonTitle:BC_STRING_OK otherButtonTitles: nil];
    [alert show];
}

-  (void)handleLongPress:(UILongPressGestureRecognizer*)sender
{
    if (sender.state == UIGestureRecognizerStateBegan){
        [self showBundleShortNameAlert];
    }
}

@end
