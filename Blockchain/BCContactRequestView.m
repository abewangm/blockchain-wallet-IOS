//
//  BCContactRequestView.m
//  Blockchain
//
//  Created by kevinwu on 1/9/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCContactRequestView.h"
#import "Blockchain-Swift.h"
#import "Contact.h"

@interface BCContactRequestView ()

@property (nonatomic) Contact *contact;

@property (nonatomic) UIButton *requestButton;

@property (nonatomic) uint64_t amount;
@end

@implementation BCContactRequestView

- (id)initWithContact:(Contact *)contact amount:(uint64_t)amount willSend:(BOOL)willSend
{
    UIWindow *window = app.window;
    
    self = [super initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT, window.frame.size.width, window.frame.size.height - DEFAULT_HEADER_HEIGHT)];
    
    if (self) {
        self.contact = contact;
        _willSend = willSend;
        self.amount = amount;
        
        self.backgroundColor = [UIColor whiteColor];

        UILabel *promptLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 8, window.frame.size.width - 40, 80)];
        promptLabel.textColor = [UIColor darkGrayColor];
        promptLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:17.0];
        promptLabel.numberOfLines = 0;
        [self addSubview:promptLabel];
        
        // Input accessory view
        
        self.requestButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.requestButton.frame = CGRectMake(0, 0, window.frame.size.width, 46);
        self.requestButton.backgroundColor = COLOR_BUTTON_BLUE;
        [self.requestButton setTitle:BC_STRING_REQUEST forState:UIControlStateNormal];
        [self.requestButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.requestButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:17.0];
        
        promptLabel.text = [NSString stringWithFormat:BC_STRING_PROMPT_REASON, contact.name];
        [self.requestButton addTarget:self action:@selector(completeRequest) forControlEvents:UIControlEventTouchUpInside];
            
        _textField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(20, 95, window.frame.size.width - 40, 30)];
        _textField.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:_textField.font.pointSize];
        _textField.textColor = COLOR_DARK_GRAY;
        _textField.borderStyle = UITextBorderStyleRoundedRect;
        _textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _textField.spellCheckingType = UITextSpellCheckingTypeNo;
        [self addSubview:_textField];
            
        [_textField setReturnKeyType:UIReturnKeyNext];
        _textField.delegate = self;
        _textField.inputAccessoryView = self.requestButton;
    }
    return self;
}

- (void)showKeyboard
{
    if (self.textField) {
        [self.textField becomeFirstResponder];
    }
}

- (void)completeRequest
{
    if (self.willSend) {
        [self.delegate createSendRequestForContact:self.contact withReason:self.textField.text amount:self.amount lastSelectedField:self.textField];
    } else {
        [self.delegate createReceiveRequestForContact:self.contact withReason:self.textField.text amount:self.amount lastSelectedField:self.textField];
    }
}

@end
