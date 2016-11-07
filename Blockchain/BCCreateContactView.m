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

@implementation BCCreateContactView

-(id)init
{
    UIWindow *window = app.window;
    
    self = [super initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT, window.frame.size.width, window.frame.size.height - DEFAULT_HEADER_HEIGHT)];
    
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 55, window.frame.size.width - 40, 25)];
        nameLabel.text = BC_STRING_NAME;
        nameLabel.textColor = [UIColor darkGrayColor];
        nameLabel.font = [UIFont systemFontOfSize:17.0];
        [self addSubview:nameLabel];
        
        _nameField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(20, 95, window.frame.size.width - 40, 30)];
        _nameField.borderStyle = UITextBorderStyleRoundedRect;
        _nameField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _nameField.autocorrectionType = UITextAutocorrectionTypeNo;
        _nameField.spellCheckingType = UITextSpellCheckingTypeNo;
        [self addSubview:_nameField];
        
        [_nameField setReturnKeyType:UIReturnKeyNext];
        _nameField.delegate = self;
        
        UILabel *idLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, _nameField.frame.origin.y + _nameField.frame.size.height + 15, window.frame.size.width - 40, 25)];
        idLabel.text = BC_STRING_ID;
        idLabel.textColor = [UIColor darkGrayColor];
        idLabel.font = [UIFont systemFontOfSize:17.0];
        [self addSubview:idLabel];
        
        _idField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(20, idLabel.frame.origin.y + idLabel.frame.size.height + 15, window.frame.size.width - 40, 30)];
        _idField.borderStyle = UITextBorderStyleRoundedRect;
        _idField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _idField.autocorrectionType = UITextAutocorrectionTypeNo;
        _idField.spellCheckingType = UITextSpellCheckingTypeNo;
        [self addSubview:_idField];

        [_idField setReturnKeyType:UIReturnKeyDone];
        _idField.delegate = self;
        
        UIButton *createContactButton = [UIButton buttonWithType:UIButtonTypeCustom];
        createContactButton.frame = CGRectMake(0, 0, window.frame.size.width, 46);
        createContactButton.backgroundColor = COLOR_BUTTON_GRAY;
        [createContactButton setTitle:BC_STRING_SAVE forState:UIControlStateNormal];
        [createContactButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        createContactButton.titleLabel.font = [UIFont systemFontOfSize:17.0];
        
        [createContactButton addTarget:self action:@selector(createContactClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        _nameField.inputAccessoryView = createContactButton;
        _idField.inputAccessoryView = createContactButton;
    }
    
    return self;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _nameField) {
        [_idField becomeFirstResponder];
    } else {
        [self createContactClicked:nil];
    }
    
    return YES;
}

- (IBAction)createContactClicked:(id)sender
{
    if ([app checkInternetConnection]) {

    }
}

@end
