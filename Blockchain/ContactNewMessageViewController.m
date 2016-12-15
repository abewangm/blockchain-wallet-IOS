//
//  ContactNewMessageViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 12/14/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ContactNewMessageViewController.h"

@interface ContactNewMessageViewController ()
@property (nonatomic) UITextView *textView;
@property (nonatomic) NSString *contactIdentifier;
@end

@implementation ContactNewMessageViewController

- (id)initWithContactIdentifier:(NSString *)identifier
{
    if (self = [super init]) {
        self.contactIdentifier = identifier;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.textView = [[UITextView alloc] initWithFrame:self.view.frame];
    self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
    [self.view addSubview:self.textView];
    
    [self setupTextViewInputAccessoryView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.textView becomeFirstResponder];
}

- (void)setupTextViewInputAccessoryView
{
    UIView *inputAccessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, BUTTON_HEIGHT)];
    inputAccessoryView.backgroundColor = [UIColor redColor];
    
    UIButton *sendButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, BUTTON_HEIGHT)];
    sendButton.backgroundColor = COLOR_BUTTON_GREEN;
    [sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [sendButton setTitle:BC_STRING_SEND forState:UIControlStateNormal];
    [sendButton addTarget:self action:@selector(sendMessage) forControlEvents:UIControlEventTouchUpInside];
    [inputAccessoryView addSubview:sendButton];
    
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(sendButton.frame.size.width - 50, 0, 50, BUTTON_HEIGHT)];
    cancelButton.backgroundColor = COLOR_BUTTON_GRAY_CANCEL;
    [cancelButton setImage:[UIImage imageNamed:@"cancel"] forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelEditing) forControlEvents:UIControlEventTouchUpInside];
    [inputAccessoryView addSubview:cancelButton];
    
    self.textView.inputAccessoryView = inputAccessoryView;
}

- (void)cancelEditing
{
    [self.textView resignFirstResponder];
}

- (void)sendMessage
{
    UIAlertController *confirmSendAlert = [UIAlertController alertControllerWithTitle:BC_STRING_SEND_MESSAGE_CONFIRM message:nil preferredStyle:UIAlertControllerStyleAlert];
    [confirmSendAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_SEND style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.delegate sendMessage:self.textView.text];
    }]];
    [confirmSendAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:confirmSendAlert animated:YES completion:nil];
}

@end
