//
//  BCContactRequestView.m
//  Blockchain
//
//  Created by kevinwu on 1/9/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCContactRequestView.h"
#import "Blockchain-Swift.h"
#import "BCLine.h"
#import "Contact.h"
#import "UIView+ChangeFrameAttribute.h"

#define CELL_HEIGHT 44

@interface BCContactRequestView () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

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

        UILabel *totalLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 8, 0, 0)];
        totalLabel.text = BC_STRING_TOTAL;
        totalLabel.textColor = [UIColor darkGrayColor];
        totalLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_SEMIBOLD size:FONT_SIZE_SMALL];
        totalLabel.textAlignment = NSTextAlignmentCenter;
        [totalLabel sizeToFit];
        totalLabel.center = CGPointMake(window.center.x, totalLabel.center.y);
        [self addSubview:totalLabel];
        
        UILabel *btcAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, totalLabel.frame.origin.y + totalLabel.frame.size.height + 8, 0, 0)];
        btcAmountLabel.text = [NSNumberFormatter formatBTC:self.amount];
        btcAmountLabel.textColor = COLOR_BLOCKCHAIN_RED;
        btcAmountLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_SEMIBOLD size:FONT_SIZE_EXTRA_EXTRA_LARGE];
        btcAmountLabel.textAlignment = NSTextAlignmentCenter;
        [btcAmountLabel sizeToFit];
        btcAmountLabel.center = CGPointMake(window.center.x, btcAmountLabel.center.y);
        [self addSubview:btcAmountLabel];
        
        UILabel *fiatAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, btcAmountLabel.frame.origin.y + btcAmountLabel.frame.size.height + 8, 0, 0)];
        fiatAmountLabel.text = [NSNumberFormatter formatMoney:self.amount localCurrency:YES];
        fiatAmountLabel.textColor = COLOR_BLOCKCHAIN_RED;
        fiatAmountLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_MEDIUM];
        fiatAmountLabel.textAlignment = NSTextAlignmentCenter;
        [fiatAmountLabel sizeToFit];
        fiatAmountLabel.center = CGPointMake(window.center.x, fiatAmountLabel.center.y);
        [self addSubview:fiatAmountLabel];
        
        CGFloat tableViewHeight = CELL_HEIGHT * 3;
        
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
        
        UILabel *tableViewFooterLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, summaryTableView.frame.origin.y + summaryTableView.frame.size.height + 8, window.frame.size.width - 30, 0)];
        tableViewFooterLabel.numberOfLines = 0;
        tableViewFooterLabel.text = BC_STRING_TRANSACTIONS_MUST_BE_ACCEPTED_BY_YOUR_CONTACT_PRIOR_TO_SENDING;
        tableViewFooterLabel.textColor = COLOR_LIGHT_GRAY;
        tableViewFooterLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_EXTRA_SMALL];
        [tableViewFooterLabel sizeToFit];
        [tableViewFooterLabel changeXPosition:15];
        [self addSubview:tableViewFooterLabel];
        
        // Input accessory view
        
        self.requestButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.requestButton.frame = CGRectMake(0, self.frame.size.height - BUTTON_HEIGHT - 8, 240, BUTTON_HEIGHT);
        self.requestButton.center = CGPointMake(self.center.x, self.requestButton.center.y);
        self.requestButton.layer.cornerRadius = CORNER_RADIUS_BUTTON;
        self.requestButton.backgroundColor = COLOR_BUTTON_BLUE;
        [self.requestButton setTitle:BC_STRING_START_TRANSACTION forState:UIControlStateNormal];
        [self.requestButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.requestButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_LARGE];
        [self.requestButton addTarget:self action:@selector(completeRequest) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.requestButton];
    }
    return self;
}

- (void)completeRequest
{
    if (self.willSend) {
        [self.delegate createSendRequestForContact:self.contact withReason:self.descriptionField.text amount:self.amount lastSelectedField:self.descriptionField];
    } else {
        [self.delegate createReceiveRequestForContact:self.contact withReason:self.descriptionField.text amount:self.amount lastSelectedField:self.descriptionField];
    }
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
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.textLabel.textColor = COLOR_TEXT_DARK_GRAY;
    cell.textLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_SEMIBOLD size:FONT_SIZE_SMALL];
    cell.detailTextLabel.textColor = COLOR_TEXT_DARK_GRAY;
    cell.detailTextLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];

    if (indexPath.row == 0) {
        cell.textLabel.text = BC_STRING_TO;
        cell.detailTextLabel.text = self.contact.name;
    } else if (indexPath.row == 1) {
        cell.textLabel.text = BC_STRING_FROM;
        cell.detailTextLabel.text = nil;
    } else if (indexPath.row == 2) {
        cell.textLabel.text = BC_STRING_DESCRIPTION;
        
        self.descriptionField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(cell.frame.size.width/2 + 16, 0, cell.frame.size.width/2 - 16 - 15, 20)];
        self.descriptionField.center = CGPointMake(self.descriptionField.center.x, cell.contentView.center.y);
        self.descriptionField.placeholder = [NSString stringWithFormat:BC_STRING_SHARED_WITH_CONTACT_NAME_ARGUMENT, self.contact.name];
        self.descriptionField.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
        self.descriptionField.textColor = COLOR_TEXT_DARK_GRAY;
        self.descriptionField.textAlignment = NSTextAlignmentRight;
        self.descriptionField.returnKeyType = UIReturnKeyDone;
        self.descriptionField.delegate = self;
        [cell.contentView addSubview:self.descriptionField];
    }
    return cell;
}

@end
