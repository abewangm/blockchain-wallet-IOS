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
@property (nonatomic) ContactTransaction *contactTransaction;
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
        
        self.reallyDoPaymentButton = [[UIButton alloc] initWithFrame:CGRectMake(0, window.frame.size.height - 40, window.frame.size.width, 40)];
        self.reallyDoPaymentButton.backgroundColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
        [self.reallyDoPaymentButton setTitle:BC_STRING_SEND forState:UIControlStateNormal];
        self.reallyDoPaymentButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:17.0];
        
        [self.reallyDoPaymentButton addTarget:self action:@selector(reallyDoPaymentButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:self.reallyDoPaymentButton];
        
        self.from = from;
        self.to = to;
        self.amount = amount;
        self.fee = fee;
        self.contactTransaction = contactTransaction;
        self.surgeIsOccurring = surgePresent;
        
        self.backgroundColor = [UIColor whiteColor];
        
        UILabel *totalLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 8, 0, 0)];
        totalLabel.text = BC_STRING_TOTAL;
        totalLabel.textColor = [UIColor darkGrayColor];
        totalLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_SEMIBOLD size:FONT_SIZE_SMALL];
        totalLabel.textAlignment = NSTextAlignmentCenter;
        [totalLabel sizeToFit];
        totalLabel.center = CGPointMake(window.center.x, totalLabel.center.y);
        [self addSubview:totalLabel];
        
        UILabel *btcAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, totalLabel.frame.origin.y + totalLabel.frame.size.height + 8, 0, 0)];
        btcAmountLabel.text = [NSNumberFormatter formatBTC:total];
        btcAmountLabel.textColor = COLOR_BLOCKCHAIN_RED;
        btcAmountLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_SEMIBOLD size:FONT_SIZE_EXTRA_EXTRA_LARGE];
        btcAmountLabel.textAlignment = NSTextAlignmentCenter;
        [btcAmountLabel sizeToFit];
        btcAmountLabel.center = CGPointMake(window.center.x, btcAmountLabel.center.y);
        [self addSubview:btcAmountLabel];
        
        UILabel *fiatAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, btcAmountLabel.frame.origin.y + btcAmountLabel.frame.size.height + 8, 0, 0)];
        fiatAmountLabel.text = [NSNumberFormatter formatMoney:total localCurrency:YES];
        fiatAmountLabel.textColor = COLOR_BLOCKCHAIN_RED;
        fiatAmountLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_MEDIUM];
        fiatAmountLabel.textAlignment = NSTextAlignmentCenter;
        [fiatAmountLabel sizeToFit];
        fiatAmountLabel.center = CGPointMake(window.center.x, fiatAmountLabel.center.y);
        [self addSubview:fiatAmountLabel];
        
        CGFloat tableViewHeight = CELL_HEIGHT * NUMBER_OF_ROWS;
        
        UITableView *summaryTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, fiatAmountLabel.frame.origin.y + fiatAmountLabel.frame.size.height + 20, window.frame.size.width, tableViewHeight)];
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
    }
    return self;
}

- (void)reallyDoPaymentButtonClicked
{
    [self.delegate setupNoteForTransaction:self.descriptionField.text];
}

- (void)feeInformationButtonClicked
{
    [self.delegate feeInformationButtonClicked];
}

#pragma mark - Text Helpers

- (NSString *)formatAmountInBTCAndFiat:(uint64_t)amount
{
    return [NSString stringWithFormat:@"%@ (%@)", [NSNumberFormatter formatMoney:amount localCurrency:NO], [NSNumberFormatter formatMoney:amount localCurrency:YES]];
}

#pragma mark - Text Field Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return NUMBER_OF_ROWS;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.textLabel.textColor = COLOR_TEXT_DARK_GRAY;
    cell.textLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_SEMIBOLD size:FONT_SIZE_SMALL];
    cell.detailTextLabel.textColor = COLOR_TEXT_DARK_GRAY;
    cell.detailTextLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    
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
        testLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_SEMIBOLD size:FONT_SIZE_SMALL];
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
        
        self.descriptionField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(cell.frame.size.width/2 + 16, 0, cell.frame.size.width/2 - 16 - 15, 20)];
        self.descriptionField.center = CGPointMake(self.descriptionField.center.x, cell.contentView.center.y);
        self.descriptionField.placeholder = BC_STRING_TRANSACTION_DESCRIPTION_PLACEHOLDER;
        self.descriptionField.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
        self.descriptionField.textColor = COLOR_TEXT_DARK_GRAY;
        self.descriptionField.textAlignment = NSTextAlignmentRight;
        self.descriptionField.returnKeyType = UIReturnKeyDone;
        
        if (self.contactTransaction) {
            self.descriptionField.text = self.contactTransaction.reason;
            self.descriptionField.userInteractionEnabled = NO;
            
            // Do not set a note, since description is saved in the metadata service
            self.delegate = nil;
        } else {
            // Text will be empty for regular (non-contacts-related) transactions - allow setting a note

            self.descriptionField.delegate = self;
            
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self.descriptionField action:@selector(resignFirstResponder)];
            [self addGestureRecognizer:tapGesture];
        }

        [cell.contentView addSubview:self.descriptionField];
    }
    return cell;
}

@end
