//
//  BCConfirmPaymentView.m
//  Blockchain
//
//  Created by Kevin Wu on 10/2/15.
//  Copyright © 2015 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCConfirmPaymentView.h"
#import "UIView+ChangeFrameAttribute.h"
#import "Blockchain-Swift.h"
#import "ContactTransaction.h"
#import "BCTotalAmountView.h"
#import "BCConfirmPaymentViewModel.h"

#define CELL_HEIGHT 44

const int cellRowFrom = 0;
const int cellRowTo = 1;
const int cellRowDescription = 2;
const int cellRowAmount = 3;
const int cellRowFee = 4;

@interface BCConfirmPaymentView () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@property (nonatomic) BCSecureTextField *descriptionField;
@property (nonatomic) ContactTransaction *contactTransaction;
@property (nonatomic) BCTotalAmountView *totalAmountView;
@property (nonatomic) BCConfirmPaymentViewModel *viewModel;
@property (nonatomic) NSMutableArray *rows;
@end
@implementation BCConfirmPaymentView

- (id)initWithWindow:(UIView *)window viewModel:(BCConfirmPaymentViewModel *)viewModel
{
    self = [super initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT, window.frame.size.width, window.frame.size.height - DEFAULT_HEADER_HEIGHT)];
    
    if (self) {
        
        self.viewModel = viewModel;
        
        BCTotalAmountView *totalAmountView = [[BCTotalAmountView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, TOTAL_AMOUNT_VIEW_HEIGHT) color:COLOR_BLOCKCHAIN_RED amount:0];
        
        totalAmountView.btcAmountLabel.text = self.viewModel.btcTotalAmountText;
        totalAmountView.fiatAmountLabel.text = self.viewModel.fiatTotalAmountText;
        
        [self addSubview:totalAmountView];
        self.topView = totalAmountView;
        
        [self setupRows];
        
        CGFloat tableViewHeight = CELL_HEIGHT * [self.rows count];
        
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

- (void)setupRows
{
    self.rows = [NSMutableArray new];
    if (self.viewModel.from) [self.rows addObject:@[BC_STRING_FROM, self.viewModel.from]];
    if (self.viewModel.to) [self.rows addObject:@[BC_STRING_TO, self.viewModel.to]];
    [self.rows addObject:@[BC_STRING_DESCRIPTION, self.viewModel.noteText ? : @""]];
    if (self.viewModel.btcWithFiatAmountText) [self.rows addObject:@[BC_STRING_AMOUNT, self.viewModel.btcWithFiatAmountText]];
    if (self.viewModel.btcWithFiatFeeText) [self.rows addObject:@[BC_STRING_FEE, self.viewModel.btcWithFiatFeeText]];
}

- (void)reallyDoPaymentButtonClicked
{
    if (!self.contactTransaction) {
        [self.confirmDelegate setupNoteForTransaction:self.note];
    }
}

- (void)feeInformationButtonClicked
{
    [self.confirmDelegate feeInformationButtonClicked];
}

#pragma mark - Text Field Delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    textField.hidden = YES;
    
    [self beginEditingDescription];
    
    return NO;
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.isEditingDescription ? self.descriptionCellHeight : CELL_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.isEditingDescription ? 1 : [self.rows count];
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
        cell = [self configureDescriptionTextViewForCell:cell];
    } else {
        
        NSString *textLabel = [self.rows[indexPath.row] firstObject];
        NSString *detailTextLabel = [self.rows[indexPath.row] lastObject];

        cell.textLabel.text = textLabel;
        cell.detailTextLabel.text = detailTextLabel;
        
        cell.detailTextLabel.adjustsFontSizeToFitWidth = [textLabel isEqualToString:BC_STRING_FROM] || [textLabel isEqualToString:BC_STRING_TO];
        
        if ([textLabel isEqualToString:BC_STRING_FEE]) {
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
            
            if (self.viewModel.surgeIsOccurring) cell.detailTextLabel.textColor = COLOR_WARNING_RED;
        } else if ([textLabel isEqualToString:BC_STRING_DESCRIPTION]) {
            cell.textLabel.text = nil;
            
            CGFloat leftMargin = IS_USING_6_OR_7_PLUS_SCREEN_SIZE ? 20 : 15;
            CGFloat labelHeight = 16;
            
            UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, 14, self.frame.size.width/2 - 8 - leftMargin, labelHeight)];
            descriptionLabel.text = BC_STRING_DESCRIPTION;
            descriptionLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
            descriptionLabel.textColor = COLOR_TEXT_DARK_GRAY;
            
            [cell.contentView addSubview:descriptionLabel];
            
            self.descriptionField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(self.frame.size.width/2 + 16, 0, self.frame.size.width/2 - 16 - 15, 20)];
            self.descriptionField.center = CGPointMake(self.descriptionField.center.x, cell.contentView.center.y);
            self.descriptionField.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL];
            self.descriptionField.textColor = COLOR_TEXT_DARK_GRAY;
            self.descriptionField.textAlignment = NSTextAlignmentRight;
            self.descriptionField.returnKeyType = UIReturnKeyDone;
            
            if (self.viewModel.noteText) {
                self.descriptionField.text = self.viewModel.noteText;
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
