//
//  BCVerifyEmailViewController.m
//  Blockchain
//
//  Created by kevinwu on 2/14/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCVerifyEmailViewController.h"
#import "Blockchain-Swift.h"

@interface BCVerifyEmailViewController () <UITextFieldDelegate>
@property (nonatomic) BCSecureTextField *emailField;
@property (nonatomic) UILabel *verifiedStatusLabel;
@property (nonatomic) UIButton *updateButton;
@end

@implementation BCVerifyEmailViewController

- (id)initWithEmailDelegate:(UIViewController<EmailDelegate>*)delegate
{
    if (self = [super init]) {
        self.delegate = delegate;
    }
    return self;
}

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:self.delegate.view.frame];
    self.view.backgroundColor = [UIColor whiteColor];
    
    if (self.view == nil) {
        [super loadView];
    }
    
    UILabel *promptLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT + 16, self.view.frame.size.width - 80, 140)];
    promptLabel.numberOfLines = 7;
    promptLabel.textAlignment = NSTextAlignmentCenter;
    promptLabel.font = [UIFont fontWithName:FONT_GILL_SANS_REGULAR size:15];
    promptLabel.text = BC_STRING_SETTINGS_EMAIL_PROMPT;
    [self.view addSubview:promptLabel];
    
    [promptLabel sizeToFit];
    
    promptLabel.center = CGPointMake(self.view.center.x, promptLabel.center.y);
    
    self.emailField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(0, promptLabel.frame.origin.y + promptLabel.frame.size.height + 16, 200, 30)];
    self.emailField.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:13];
    self.emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.emailField.textAlignment = NSTextAlignmentCenter;
    self.emailField.returnKeyType = UIReturnKeyDone;
    self.emailField.delegate = self;
    [self.view addSubview:self.emailField];
    self.emailField.center = CGPointMake(self.view.center.x, self.emailField.center.y);
    
    UIButton *updateButton = [UIButton buttonWithType:UIButtonTypeCustom];
    updateButton.frame = CGRectMake(0, 0, self.view.frame.size.width, 46);
    updateButton.backgroundColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
    [updateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    updateButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:17.0];
    [updateButton setTitle:BC_STRING_UPDATE forState:UIControlStateNormal];
    [updateButton addTarget:self action:@selector(changeEmail) forControlEvents:UIControlEventTouchUpInside];
    self.updateButton = updateButton;
    
    self.emailField.inputAccessoryView = updateButton;
    
    self.verifiedStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.emailField.frame.origin.y + self.emailField.frame.size.height + 8, 150, 50)];
    self.verifiedStatusLabel.textAlignment = NSTextAlignmentCenter;
    self.verifiedStatusLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:15];
    [self.view addSubview:self.verifiedStatusLabel];
    self.verifiedStatusLabel.center = CGPointMake(self.view.center.x, self.verifiedStatusLabel.center.y);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self reload];
    
    SettingsNavigationController *navigationController = (SettingsNavigationController *)self.navigationController;
    navigationController.headerLabel.text = BC_STRING_SETTINGS_EMAIL;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didGetAccountInfo) name:NOTIFICATION_KEY_GET_ACCOUNT_INFO_SUCCESS object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.emailField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_GET_ACCOUNT_INFO_SUCCESS object:nil];
}

#pragma mark - Actions

- (void)reload
{
    self.emailField.text = [self getEmail];
    
    if ([self getVerifiedStatus]) {
        self.verifiedStatusLabel.textColor = COLOR_BLOCKCHAIN_AQUA;
        self.verifiedStatusLabel.text = BC_STRING_SETTINGS_VERIFIED;
    } else {
        self.verifiedStatusLabel.textColor = COLOR_BLOCKCHAIN_RED;
        self.verifiedStatusLabel.text = BC_STRING_SETTINGS_UNVERIFIED;
    }
}

- (NSString *)getEmail
{
    return [self.delegate getEmail];
}

- (BOOL)getVerifiedStatus
{
    return [self.delegate isEmailVerified];
}

- (void)changeEmail
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeEmailSuccess) name:NOTIFICATION_KEY_CHANGE_EMAIL_SUCCESS object:nil];

    [self.delegate changeEmail:self.emailField.text];
}

- (void)changeEmailSuccess
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_CHANGE_EMAIL_SUCCESS object:nil];
    
    [self reload];
}

- (void)didGetAccountInfo
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_GET_ACCOUNT_INFO_SUCCESS object:nil];
    
    [self reload];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self changeEmail];
    return YES;
}

@end
