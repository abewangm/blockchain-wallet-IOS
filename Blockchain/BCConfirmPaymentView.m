//
//  BCConfirmPaymentView.m
//  Blockchain
//
//  Created by Kevin Wu on 10/2/15.
//  Copyright © 2015 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCConfirmPaymentView.h"
#import "NSNumberFormatter+Currencies.h"
#import "UIView+ChangeFrameAttribute.h"
#import "Blockchain-Swift.h"
#import "ContactTransaction.h"
#import "BCTotalAmountView.h"
#import "BCLine.h"

#define CELL_HEIGHT 44
#define NUMBER_OF_ROWS 5

const int cellRowFrom = 0;
const int cellRowTo = 1;
const int cellRowDescription = 2;
const int cellRowAmount = 3;
const int cellRowFee = 4;

@interface BCConfirmPaymentView () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@property (nonatomic) NSString *from;
@property (nonatomic) NSString *to;
@property (nonatomic) uint64_t amount;
@property (nonatomic) uint64_t fee;
@property (nonatomic) BOOL surgeIsOccurring;
@property (nonatomic) BCSecureTextField *descriptionField;
@property (nonatomic) UITextView *descriptionTextView;
@property (nonatomic) ContactTransaction *contactTransaction;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) BCTotalAmountView *totalAmountView;
@property (nonatomic) NSString *note;

@property (nonatomic) BOOL isEditingDescription;
@property (nonatomic) UIView *descriptionInputAccessoryView;
@property (nonatomic) CGFloat descriptionCellHeight;
@end
@implementation BCConfirmPaymentView

- (id)initWithWindow:(UIView *)window
                from:(NSString *)from
                  To:(NSString *)to
              amount:(uint64_t)amount
                 fee:(uint64_t)fee
               total:(uint64_t)total
         contactTransaction:(ContactTransaction *)contactTransaction
               surge:(BOOL)surgePresent
{
    self = [super initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT, window.frame.size.width, window.frame.size.height - DEFAULT_HEADER_HEIGHT)];
    
    if (self) {
        
        self.descriptionCellHeight = 140;
        [self setupTextViewInputAccessoryView];
        
        BCTotalAmountView *totalAmountView = [[BCTotalAmountView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, TOTAL_AMOUNT_VIEW_HEIGHT) color:COLOR_BLOCKCHAIN_RED amount:total];
        [self addSubview:totalAmountView];
        self.totalAmountView = totalAmountView;
        
        CGFloat tableViewHeight = CELL_HEIGHT * NUMBER_OF_ROWS;
        
        self.from = from;
        self.to = to;
        self.amount = amount;
        self.fee = fee;
        self.contactTransaction = contactTransaction;
        self.surgeIsOccurring = surgePresent;
        
        self.backgroundColor = [UIColor whiteColor];
        
        UITableView *summaryTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, totalAmountView.frame.origin.y + totalAmountView.frame.size.height, window.frame.size.width, tableViewHeight)];
        summaryTableView.scrollEnabled = NO;
        summaryTableView.delegate = self;
        summaryTableView.dataSource = self;
        [self addSubview:summaryTableView];
        
        CGFloat lineWidth = 1.0/[UIScreen mainScreen].scale;
        
        summaryTableView.clipsToBounds = YES;
        
        CALayer *topBorder = [CALayer layer];
        topBorder.borderColor = [COLOR_LINE_GRAY CGColor];
        topBorder.borderWidth = 1;
        topBorder.frame = CGRectMake(0, 0, CGRectGetWidth(summaryTableView.frame), lineWidth);
        [summaryTableView.layer addSublayer:topBorder];
        
        CALayer *bottomBorder = [CALayer layer];
        bottomBorder.borderColor = [COLOR_LINE_GRAY CGColor];
        bottomBorder.borderWidth = 1;
        bottomBorder.frame = CGRectMake(0, CGRectGetHeight(summaryTableView.frame) - lineWidth, CGRectGetWidth(summaryTableView.frame), lineWidth);
        [summaryTableView.layer addSublayer:bottomBorder];
        
        self.tableView = summaryTableView;
        
        CGFloat buttonHeight = 40;
        CGRect buttonFrame = CGRectMake(0, app.window.frame.size.height - DEFAULT_HEADER_HEIGHT - buttonHeight, app.window.frame.size.width, buttonHeight);;
        NSString *buttonTitle;
        
        if (self.contactTransaction) {
            buttonTitle = [self.contactTransaction.role isEqualToString:TRANSACTION_ROLE_RPR_INITIATOR] ? BC_STRING_SEND : BC_STRING_PAY;
        } else {
            buttonTitle = BC_STRING_SEND;
        }
        
        self.reallyDoPaymentButton = [[UIButton alloc] initWithFrame:CGRectZero];
        self.reallyDoPaymentButton.frame = buttonFrame;
        [self.reallyDoPaymentButton setTitle:buttonTitle forState:UIControlStateNormal];
        self.reallyDoPaymentButton.backgroundColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
        self.reallyDoPaymentButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:17.0];
        
        [self.reallyDoPaymentButton addTarget:self action:@selector(reallyDoPaymentButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:self.reallyDoPaymentButton];
    }
    return self;
}

- (void)reallyDoPaymentButtonClicked
{
    if (!self.contactTransaction) {
        [self.delegate setupNoteForTransaction:self.note];
    }
}

- (void)feeInformationButtonClicked
{
    [self.delegate feeInformationButtonClicked];
}

#pragma mark - View Helpers

- (void)setupTextViewInputAccessoryView
{
    UIView *inputAccessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, BUTTON_HEIGHT)];
    inputAccessoryView.backgroundColor = [UIColor whiteColor];;
    
    BCLine *topLine = [[BCLine alloc] initWithYPosition:0];
    [inputAccessoryView addSubview:topLine];
    
    BCLine *bottomLine = [[BCLine alloc] initWithYPosition:0];
    [inputAccessoryView addSubview:bottomLine];
    
    UIButton *doneButton = [[UIButton alloc] initWithFrame:CGRectMake(inputAccessoryView.frame.size.width - 68, 0, 60, BUTTON_HEIGHT)];
    doneButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:13.0];
    [doneButton setTitleColor:COLOR_BLOCKCHAIN_LIGHT_BLUE forState:UIControlStateNormal];
    [doneButton setTitle:BC_STRING_DONE forState:UIControlStateNormal];
    [doneButton addTarget:self action:@selector(endEditingDescription) forControlEvents:UIControlEventTouchUpInside];
    [inputAccessoryView addSubview:doneButton];
    
    self.descriptionInputAccessoryView = inputAccessoryView;
}

- (void)moveViewsUpForSmallScreens
{
    if (IS_USING_SCREEN_SIZE_4S) {
        
        self.totalAmountView.hidden = YES;

        [UIView animateWithDuration:ANIMATION_DURATION_LONG animations:^{
            [self.tableView changeYPosition:0];
        }];
    }
}

- (void)moveViewsDownForSmallScreens
{
    if (IS_USING_SCREEN_SIZE_4S) {
        
        self.totalAmountView.alpha = 0;
        self.totalAmountView.hidden = NO;
        
        [UIView animateWithDuration:ANIMATION_DURATION_LONG animations:^{
            [self.tableView changeYPosition:self.totalAmountView.frame.origin.y + self.totalAmountView.frame.size.height];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:ANIMATION_DURATION animations:^{
                self.totalAmountView.alpha = 1;
            }];
        }];
    }
}

- (void)endEditingDescription
{
    self.note = self.descriptionTextView.text;
    
    self.isEditingDescription = NO;
    
    [self.descriptionTextView resignFirstResponder];
    
    [self moveViewsDownForSmallScreens];
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)beginEditingDescription
{
    [self moveViewsUpForSmallScreens];
    
    self.isEditingDescription = YES;
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Text Helpers

- (NSString *)formatAmountInBTCAndFiat:(uint64_t)amount
{
    return [NSString stringWithFormat:@"%@ (%@)", [NSNumberFormatter formatMoney:amount localCurrency:NO], [NSNumberFormatter formatMoney:amount localCurrency:YES]];
}

#pragma mark - Text Field Delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    textField.hidden = YES;
    
    [self beginEditingDescription];
    
    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    [self moveViewsDownForSmallScreens];
    
    return YES;
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.isEditingDescription ? self.descriptionCellHeight : CELL_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.isEditingDescription ? 1 : NUMBER_OF_ROWS;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.textLabel.textColor = COLOR_TEXT_DARK_GRAY;
    cell.textLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    cell.detailTextLabel.textColor = COLOR_TEXT_DARK_GRAY;
    cell.detailTextLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL];
    
    if (self.isEditingDescription) {
        cell.textLabel.text = BC_STRING_DESCRIPTION;
        
        self.descriptionTextView = [[UITextView alloc] initWithFrame:CGRectMake(cell.contentView.frame.size.width/2 + 8, 8, cell.contentView.frame.size.width/2 - 8 - 8, self.descriptionCellHeight - 16)];
        self.descriptionTextView.textColor = COLOR_TEXT_DARK_GRAY;
        self.descriptionTextView.textContainerInset = UIEdgeInsetsZero;
        self.descriptionTextView.textAlignment = NSTextAlignmentRight;
        self.descriptionTextView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.descriptionTextView.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL];
        self.descriptionTextView.inputAccessoryView = self.descriptionInputAccessoryView;
        self.descriptionTextView.text = self.note;
        [cell.contentView addSubview:self.descriptionTextView];
        
        self.descriptionTextView.hidden = NO;
        [self.descriptionTextView becomeFirstResponder];
    } else {
        if (indexPath.row == cellRowTo) {
            cell.textLabel.text = BC_STRING_TO;
            cell.detailTextLabel.text = self.to;
            cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        } else if (indexPath.row == cellRowFrom) {
            cell.textLabel.text = BC_STRING_FROM;
            cell.detailTextLabel.text = self.from;
            cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        } else if (indexPath.row == cellRowAmount) {
            cell.textLabel.text = BC_STRING_AMOUNT;
            cell.detailTextLabel.text = [self formatAmountInBTCAndFiat:self.amount];
        } else if (indexPath.row == cellRowFee) {
            cell.textLabel.text = BC_STRING_FEE;
            cell.detailTextLabel.text = [self formatAmountInBTCAndFiat:self.fee];
            
            UILabel *testLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            testLabel.textColor = COLOR_TEXT_DARK_GRAY;
            testLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
            testLabel.text = BC_STRING_FEE;
            [testLabel sizeToFit];
            
            self.feeInformationButton = [[UIButton alloc] initWithFrame:CGRectMake(15 + testLabel.frame.size.width + 8, 0, 19, 19)];
            [self.feeInformationButton setImage:[[UIImage imageNamed:@"help"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            self.feeInformationButton.tintColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
            self.feeInformationButton.center = CGPointMake(self.feeInformationButton.center.x, cell.contentView.center.y);
            [self.feeInformationButton addTarget:self action:@selector(feeInformationButtonClicked) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:self.feeInformationButton];
            
            if (self.surgeIsOccurring) cell.detailTextLabel.textColor = COLOR_WARNING_RED;
        } else if (indexPath.row == cellRowDescription) {
            cell.textLabel.text = BC_STRING_DESCRIPTION;
            
            self.descriptionField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(self.frame.size.width/2 + 16, 0, self.frame.size.width/2 - 16 - 15, 20)];
            self.descriptionField.center = CGPointMake(self.descriptionField.center.x, cell.contentView.center.y);
            self.descriptionField.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL];
            self.descriptionField.textColor = COLOR_TEXT_DARK_GRAY;
            self.descriptionField.textAlignment = NSTextAlignmentRight;
            self.descriptionField.returnKeyType = UIReturnKeyDone;
            
            if (self.contactTransaction) {
                self.descriptionField.text = self.contactTransaction.reason;
                self.descriptionField.userInteractionEnabled = NO;
                self.descriptionField.placeholder = BC_STRING_NO_DESCRIPTION;
            } else {
                // Text will be empty for regular (non-contacts-related) transactions - allow setting a note
                
                self.descriptionField.delegate = self;
                self.descriptionField.placeholder = BC_STRING_TRANSACTION_DESCRIPTION_PLACEHOLDER;
                self.descriptionField.text = self.note;
            }
            
            [cell.contentView addSubview:self.descriptionField];
        }
    }
    return cell;
}

@end
