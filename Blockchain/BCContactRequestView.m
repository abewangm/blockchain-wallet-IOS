//
//  BCContactRequestView.m
//  Blockchain
//
//  Created by kevinwu on 1/9/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCContactRequestView.h"
#import "RootService.h"
#import "BCLine.h"
#import "Blockchain-Swift.h"
#import "Contact.h"

@interface BCContactRequestView ()

@property (nonatomic) Contact *contact;

@property (nonatomic) UIButton *nextButton;

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

        UILabel *promptLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 55, window.frame.size.width - 40, 80)];
        promptLabel.textColor = [UIColor darkGrayColor];
        promptLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:17.0];
        promptLabel.numberOfLines = 0;
        [self addSubview:promptLabel];
        
        // Input accessory view
        
        self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.nextButton.frame = CGRectMake(0, 0, window.frame.size.width, 46);
        self.nextButton.backgroundColor = COLOR_BUTTON_BLUE;
        [self.nextButton setTitle:BC_STRING_NEXT forState:UIControlStateNormal];
        [self.nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.nextButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:17.0];
        
        promptLabel.text = [NSString stringWithFormat:[self getPromptTextForReason], contact.name, [NSNumberFormatter formatMoney:self.amount localCurrency:NO]];
        [self.nextButton addTarget:self action:@selector(completeRequest) forControlEvents:UIControlEventTouchUpInside];
            
        _textField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(20, 145, window.frame.size.width - 40, 30)];
        _textField.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:_textField.font.pointSize];
        _textField.textColor = COLOR_DARK_GRAY;
        _textField.borderStyle = UITextBorderStyleRoundedRect;
        _textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _textField.spellCheckingType = UITextSpellCheckingTypeNo;
        [self addSubview:_textField];
            
        [_textField setReturnKeyType:UIReturnKeyNext];
        _textField.delegate = self;
        _textField.inputAccessoryView = self.nextButton;
    }
    return self;
}

- (void)showKeyboard
{
    if (self.textField) {
        [self.textField becomeFirstResponder];
    }
}

- (NSString *)getPromptTextForReason
{
    return self.willSend ? BC_STRING_PROMPT_REASON_SEND_NAME_ARGUMENT_AMOUNT_ARGUMENT : BC_STRING_PROMPT_REASON_RECEIVE_NAME_ARGUMENT_AMOUNT_ARGUMENT;
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
