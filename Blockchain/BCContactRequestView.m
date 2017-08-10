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
#import "BCTotalAmountView.h"

#define CELL_HEIGHT 44

@interface BCContactRequestView () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) Contact *contact;

@property (nonatomic) UIButton *requestButton;

@property (nonatomic) uint64_t amount;
@property (nonatomic) id accountOrAddress;

@end

@implementation BCContactRequestView

- (id)initWithContact:(Contact *)contact amount:(uint64_t)amount willSend:(BOOL)willSend accountOrAddress:(id)accountOrAddress
{
    UIWindow *window = app.window;
    
    self = [super initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT, window.frame.size.width, window.frame.size.height - DEFAULT_HEADER_HEIGHT)];
    
    if (self) {
        
        self.numberOfRows = willSend ? 3 : 4;

        self.contact = contact;
        self.amount = amount;
        self.accountOrAddress = accountOrAddress;
        
        _willSend = willSend;
        self.backgroundColor = [UIColor whiteColor];

        BCTotalAmountView *totalAmountView = [[BCTotalAmountView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 100) color:self.willSend ? COLOR_BLOCKCHAIN_RED : COLOR_BLOCKCHAIN_AQUA amount:self.amount];
        [self addSubview:totalAmountView];
        self.topView = totalAmountView;
        
        CGFloat tableViewHeight = CELL_HEIGHT * (self.willSend ? 3 : 4);
        
        UITableView *summaryTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, totalAmountView.frame.origin.y + totalAmountView.frame.size.height, window.frame.size.width, tableViewHeight)];
        summaryTableView.showsVerticalScrollIndicator = NO;
        summaryTableView.scrollEnabled = NO;
        summaryTableView.delegate = self;
        summaryTableView.dataSource = self;
        [summaryTableView registerClass:[TransactionDetailDescriptionCell class] forCellReuseIdentifier:CELL_IDENTIFIER_TRANSACTION_DETAIL_DESCRIPTION];
        
        summaryTableView.layer.borderWidth = 1.0/[UIScreen mainScreen].scale;
        summaryTableView.layer.borderColor = [COLOR_LINE_GRAY CGColor];
        [self addSubview:summaryTableView];
        self.tableView = summaryTableView;

        UILabel *tableViewFooterLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, summaryTableView.frame.origin.y + summaryTableView.frame.size.height + 8, window.frame.size.width - 30, 0)];
        tableViewFooterLabel.numberOfLines = 0;
        tableViewFooterLabel.text = BC_STRING_TRANSACTIONS_MUST_BE_ACCEPTED_BY_YOUR_CONTACT_PRIOR_TO_SENDING;
        tableViewFooterLabel.textColor = COLOR_LIGHT_GRAY;
        tableViewFooterLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_EXTRA_SMALL];
        [tableViewFooterLabel sizeToFit];
        [tableViewFooterLabel changeXPosition:15];
        [self addSubview:tableViewFooterLabel];
        self.footerView = tableViewFooterLabel;
        
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

#pragma mark - Actions

- (void)completeRequest
{
    if (self.willSend) {
        [self.delegate createSendRequestForContact:self.contact withReason:self.descriptionField.text amount:self.amount lastSelectedField:self.descriptionField accountOrAddress:self.accountOrAddress];
    } else {
        [self.delegate createReceiveRequestForContact:self.contact withReason:self.descriptionField.text amount:self.amount lastSelectedField:self.descriptionField];
    }
}

- (void)cancelEditing
{
    self.note = self.textView.text;
    
    [super cancelEditing];
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == self.cellRowDescription && self.textView.text) {
        return UITableViewAutomaticDimension;
    }
    return CELL_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.willSend ? 3 : 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.textLabel.textColor = COLOR_TEXT_DARK_GRAY;
    cell.textLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    cell.detailTextLabel.textColor = COLOR_TEXT_DARK_GRAY;
    cell.detailTextLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL];

    int rowAmount = 0;
    int rowTo = 1;
    int rowFrom = 2;
    self.cellRowDescription = 3;
    
    if (self.willSend) {
        rowAmount = -1;
        rowTo = 1;
        rowFrom = 0;
        self.cellRowDescription = 2;
    }
    
    NSString *accountOrAddressString = [self.accountOrAddress isKindOfClass:[NSString class]] ? self.accountOrAddress : [app.wallet getLabelForAccount:[self.accountOrAddress intValue]];
    
    if (indexPath.row == rowTo) {
        cell.textLabel.text = BC_STRING_TO;
        cell.detailTextLabel.text = self.willSend ? self.contact.name : accountOrAddressString;
    } else if (indexPath.row == rowFrom) {
        cell.textLabel.text = BC_STRING_FROM;
        cell.detailTextLabel.text = self.willSend ? accountOrAddressString : self.contact.name;
    } else if (indexPath.row == self.cellRowDescription) {
        TransactionDetailDescriptionCell *descriptionCell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_TRANSACTION_DETAIL_DESCRIPTION forIndexPath:indexPath];
        descriptionCell.descriptionDelegate = self;
        
        Transaction *transactionWithNote = [Transaction new];
        transactionWithNote.note = self.note;
        CGFloat spacing = SPACING_TEXTVIEW;
        [descriptionCell configureWithTransaction:transactionWithNote spacing:spacing];
        descriptionCell.mainLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
        descriptionCell.textViewPlaceholderLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL];
        descriptionCell.textView.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL];
        self.textView = descriptionCell.textView;
        descriptionCell.textView.inputAccessoryView = [self getDescriptionInputAccessoryView];
        return descriptionCell;
    } else if (indexPath.row == rowAmount) {
        CGFloat labelWidth = IS_USING_SCREEN_SIZE_LARGER_THAN_5S ? 48 : 42;

        UILabel *btcLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, labelWidth, 21)];
        btcLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
        btcLabel.textColor = COLOR_TEXT_DARK_GRAY;
        btcLabel.text = app.latestResponse.symbol_btc.symbol;
        btcLabel.center = CGPointMake(btcLabel.center.x, cell.contentView.center.y);
        [cell.contentView addSubview:btcLabel];
        
        UILabel *fiatLabel = [[UILabel alloc] initWithFrame:CGRectMake(cell.contentView.frame.size.width/2 + 15, 0, labelWidth, 21)];
        fiatLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
        fiatLabel.textColor = COLOR_TEXT_DARK_GRAY;
        fiatLabel.text = app.latestResponse.symbol_local.code;
        fiatLabel.center = CGPointMake(fiatLabel.center.x, cell.contentView.center.y);
        [cell.contentView addSubview:fiatLabel];
        
        CGFloat btcAmountLabelOriginX = btcLabel.frame.origin.x + btcLabel.frame.size.height + 24;
        UILabel *btcAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake(btcAmountLabelOriginX, 0, fiatLabel.frame.origin.x - btcAmountLabelOriginX - 15, 21)];
        btcAmountLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL];
        btcAmountLabel.textColor = COLOR_TEXT_DARK_GRAY;
        btcAmountLabel.text = [NSNumberFormatter formatAmount:self.amount localCurrency:NO];
        btcAmountLabel.center = CGPointMake(btcAmountLabel.center.x, cell.contentView.center.y);
        [cell.contentView addSubview:btcAmountLabel];

        CGFloat fiatAmountLabelOriginX = fiatLabel.frame.origin.x + fiatLabel.frame.size.height + 24;
        UILabel *fiatAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake(fiatAmountLabelOriginX, 0, cell.contentView.frame.size.width - fiatAmountLabelOriginX - 15, 21)];
        fiatAmountLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL];
        fiatAmountLabel.textColor = COLOR_TEXT_DARK_GRAY;
        fiatAmountLabel.text = [NSNumberFormatter formatMoney:self.amount localCurrency:YES];
        fiatAmountLabel.center = CGPointMake(fiatAmountLabel.center.x, cell.contentView.center.y);
        [cell.contentView addSubview:fiatAmountLabel];
    }
    return cell;
}

@end
