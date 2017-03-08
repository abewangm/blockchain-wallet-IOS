//
//  BCCreateContactView.m
//  Blockchain
//
//  Created by Kevin Wu on 11/7/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCCreateContactView.h"
#import "RootService.h"
#import "Blockchain-Swift.h"

@interface BCCreateContactView ()
@property (nonatomic) UIButton *nextButton;
@property (nonatomic) UIButton *doneButton;
@property (nonatomic) NSString *contactName;
@property (nonatomic) NSString *senderName;
@end
@implementation BCCreateContactView

- (id)initWithContactName:(NSString *)contactName senderName:(NSString *)senderName;
{
    UIWindow *window = app.window;
    
    self = [super initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT, window.frame.size.width, window.frame.size.height - DEFAULT_HEADER_HEIGHT)];
    
    if (self) {
        self.contactName = contactName;
        self.senderName = senderName;
        
        self.backgroundColor = [UIColor whiteColor];
        
        UILabel *promptLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 55, window.frame.size.width - 40, 25)];
        promptLabel.textColor = [UIColor darkGrayColor];
        promptLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:17.0];
        promptLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:promptLabel];
        
        if (contactName && senderName) {

            CGFloat buttonHeight = 100;
            
            promptLabel.text = BC_STRING_SHARE_INVITE_METHOD;
            
            UIButton *showQRButton = [[UIButton alloc] initWithFrame:CGRectMake(20, promptLabel.frame.origin.y + promptLabel.frame.size.height + 16, self.frame.size.width - 40, buttonHeight)];
            showQRButton.backgroundColor = COLOR_BUTTON_BLUE;
            showQRButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:13];
            showQRButton.layer.cornerRadius = 8;
            [showQRButton setTitle:BC_STRING_VIA_QR_CODE_IN_PERSON forState:UIControlStateNormal];
            showQRButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
            showQRButton.titleLabel.textAlignment = NSTextAlignmentCenter;
            [showQRButton addTarget:self action:@selector(createQRCode) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:showQRButton];
            
            UIButton *showLinkButton = [[UIButton alloc] initWithFrame:CGRectMake(20, showQRButton.frame.origin.y + showQRButton.frame.size.height + 8, self.frame.size.width - 40, buttonHeight)];
            showLinkButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:13];
            showLinkButton.backgroundColor = COLOR_BUTTON_RED;
            showLinkButton.layer.cornerRadius = 8;
            showLinkButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
            showLinkButton.titleLabel.textAlignment = NSTextAlignmentCenter;
            [showLinkButton setTitle:BC_STRING_USING_A_LINK forState:UIControlStateNormal];
            [showLinkButton addTarget:self action:@selector(shareLink) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:showLinkButton];
            
            self.doneButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
            self.doneButton.backgroundColor = COLOR_BUTTON_BLUE;
            self.doneButton.layer.cornerRadius = 4;
            [self.doneButton setTitle:BC_STRING_DONE forState:UIControlStateNormal];
            self.doneButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:17.0];
            [self.doneButton addTarget:self action:@selector(doneButtonClicked) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:self.doneButton];
            self.doneButton.center = CGPointMake(self.center.x, self.frame.size.height - 100);
            self.doneButton.hidden = YES;
            
        } else {
            
            _textField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(20, 95, window.frame.size.width - 40, 30)];
            _textField.borderStyle = UITextBorderStyleRoundedRect;
            _textField.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:_textField.font.pointSize];
            _textField.textColor = COLOR_DARK_GRAY;
            _textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
            _textField.autocorrectionType = UITextAutocorrectionTypeNo;
            _textField.spellCheckingType = UITextSpellCheckingTypeNo;
            [self addSubview:_textField];
            
            [_textField setReturnKeyType:UIReturnKeyNext];
            _textField.delegate = self;
            
            self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
            self.nextButton.frame = CGRectMake(0, 0, window.frame.size.width, 46);
            self.nextButton.backgroundColor = COLOR_BUTTON_BLUE;
            [self.nextButton setTitle:BC_STRING_NEXT forState:UIControlStateNormal];
            [self.nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            self.nextButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:17.0];
            
            if (!contactName && !senderName) {
                promptLabel.text = BC_STRING_WHO_ARE_YOU_CONNECTING_WITH;
                [self.nextButton addTarget:self action:@selector(submitContactName) forControlEvents:UIControlEventTouchUpInside];
            } else if (contactName && !senderName) {
                promptLabel.text = [NSString stringWithFormat:BC_STRING_WHAT_NAME_DOES_ARGUMENT_KNOW_YOU_BY, contactName];
                [self.nextButton addTarget:self action:@selector(submitSenderName) forControlEvents:UIControlEventTouchUpInside];
            } else {
                DLog(@"Unknown create contact step");
            }
            
            _textField.inputAccessoryView = self.nextButton;
        }
    }
    
    return self;
}

- (void)setShouldhowDoneButton:(BOOL)shouldShowDoneButton
{
    _shouldShowDoneButton = shouldShowDoneButton;
    self.doneButton.hidden = !shouldShowDoneButton;
}

- (void)showDoneButton
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_SHARE_CONTACT_LINK object:nil];
    
    self.doneButton.hidden = NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.nextButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    
    return YES;
}

- (void)submitContactName
{
    [self.delegate didCreateContactName:self.textField.text];
}

- (void)submitSenderName
{
    [self.delegate didCreateSenderName:self.textField.text contactName:self.contactName];
}

- (void)createQRCode
{
    [self.delegate didSelectQRCode];
    
    [self createContact];
}

- (void)shareLink
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showDoneButton) name:NOTIFICATION_KEY_SHARE_CONTACT_LINK object:nil];
    
    [self.delegate didSelectShareLink];

    [self createContact];
}

- (void)doneButtonClicked
{
    [self.delegate doneButtonClicked];
}

- (void)createContact
{
    if ([app checkInternetConnection]) {
        [app.wallet createContactWithName:self.senderName ID:self.contactName];
    }
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    [_textField becomeFirstResponder];
}

@end
