//
//  TransactionDetailViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 8/23/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransactionDetailViewController.h"
#import "Transaction.h"
#import "TransactionDetailDescriptionCell.h"
#import "TransactionDetailToCell.h"
#import "TransactionDetailFromCell.h"
#import "TransactionDetailDateCell.h"
#import "TransactionDetailStatusCell.h"
#import "TransactionDetailValueCell.h"
#import "TransactionDetailTableCell.h"
#import "TransactionDetailDoubleSpendWarningCell.h"
#import "NSNumberFormatter+Currencies.h"
#import "RootService.h"
#import "TransactionDetailNavigationController.h"
#import "BCWebViewController.h"
#import "TransactionRecipientsViewController.h"
#import <SafariServices/SafariServices.h>

#ifdef DEBUG
#import "UITextView+AssertionFailureFix.h"
#endif

const int cellRowWarning = 0;
const int cellRowValue = 1;
const int cellRowDescription = 2;
const int cellRowTo = 3;
const int cellRowFrom = 4;
const int cellRowDate = 5;
const int cellRowStatus = 6;

const CGFloat rowHeightDefault = 60;
const CGFloat rowHeightWarning = 44;
const CGFloat rowHeightValue = 100;
const CGFloat rowHeightValueReceived = 80;

@interface TransactionDetailViewController () <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, DescriptionDelegate, ValueDelegate, StatusDelegate, RecipientsDelegate>

@property (nonatomic) UITableView *tableView;
@property (nonatomic) UITextView *textView;
@property (nonatomic) NSRange textViewCursorPosition;
@property (nonatomic) UIView *descriptionInputAccessoryView;
@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic) BOOL isGettingFiatAtTime;

@property (nonatomic) TransactionRecipientsViewController *recipientsViewController;

@end
@implementation TransactionDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.tableView registerClass:[TransactionDetailDoubleSpendWarningCell class] forCellReuseIdentifier:CELL_IDENTIFIER_TRANSACTION_DETAIL_WARNING];
    [self.tableView registerClass:[TransactionDetailDescriptionCell class] forCellReuseIdentifier:CELL_IDENTIFIER_TRANSACTION_DETAIL_DESCRIPTION];
    [self.tableView registerClass:[TransactionDetailToCell class] forCellReuseIdentifier:CELL_IDENTIFIER_TRANSACTION_DETAIL_TO];
    [self.tableView registerClass:[TransactionDetailFromCell class] forCellReuseIdentifier:CELL_IDENTIFIER_TRANSACTION_DETAIL_FROM];
    [self.tableView registerClass:[TransactionDetailDateCell class] forCellReuseIdentifier:CELL_IDENTIFIER_TRANSACTION_DETAIL_DATE];
    [self.tableView registerClass:[TransactionDetailStatusCell class] forCellReuseIdentifier:CELL_IDENTIFIER_TRANSACTION_DETAIL_STATUS];
    [self.tableView registerClass:[TransactionDetailValueCell class] forCellReuseIdentifier:CELL_IDENTIFIER_TRANSACTION_DETAIL_VALUE];

    self.tableView.tableFooterView = [UIView new];
    
    [self setupPullToRefresh];
    [self setupTextViewInputAccessoryView];

    if (self.transactionModel.assetType == AssetTypeBitcoin && ![self.transactionModel.fiatAmountsAtTime objectForKey:[self getCurrencyCode]]) {
        [self getFiatAtTime];
    } else {
        [self reloadEtherData];
    }
}

- (void)setupTextViewInputAccessoryView
{
    UIView *inputAccessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, BUTTON_HEIGHT)];
    inputAccessoryView.backgroundColor = COLOR_WARNING_RED;
    
    UIButton *updateButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, BUTTON_HEIGHT)];
    updateButton.backgroundColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
    [updateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [updateButton.titleLabel setFont:[UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:updateButton.titleLabel.font.pointSize]];
    [updateButton setTitle:BC_STRING_UPDATE forState:UIControlStateNormal];
    [updateButton addTarget:self action:@selector(saveNote) forControlEvents:UIControlEventTouchUpInside];
    [inputAccessoryView addSubview:updateButton];
    
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(updateButton.frame.size.width - 50, 0, 50, BUTTON_HEIGHT)];
    cancelButton.backgroundColor = COLOR_BUTTON_GRAY_CANCEL;
    [cancelButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelEditing) forControlEvents:UIControlEventTouchUpInside];
    [inputAccessoryView addSubview:cancelButton];
    
    self.descriptionInputAccessoryView = inputAccessoryView;
}

- (void)getFiatAtTime
{
    [app.wallet getFiatAtTime:self.transactionModel.time * MSEC_PER_SEC value:imaxabs(self.transactionModel.amountInSatoshi) currencyCode:[app.latestResponse.symbol_local.code lowercaseString]];
    self.isGettingFiatAtTime = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadDataAfterGetFiatAtTime) name:NOTIFICATION_KEY_GET_FIAT_AT_TIME object:nil];
}

- (NSString *)getNotePlaceholder
{
    if (self.transactionModel.assetType == AssetTypeBitcoin) {
        NSString *label = [app.wallet getNotePlaceholderForTransactionHash:self.transactionModel.myHash];
        return label.length > 0 ? label : nil;
    } else {
        return nil;
    }
}

- (void)cancelEditing
{
    self.textViewCursorPosition = self.textView.selectedRange;

    [self.textView resignFirstResponder];
    self.textView.editable = NO;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self getCellRowDescription] inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    });
}

- (void)saveNote
{
    self.textViewCursorPosition = self.textView.selectedRange;
    
    [self.textView resignFirstResponder];
    self.textView.editable = NO;

    [self.busyViewDelegate showBusyViewWithLoadingText:BC_STRING_LOADING_SYNCING_WALLET];
    
    [app.wallet saveNote:self.textView.text forTransaction:self.transactionModel.myHash];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getHistoryAfterSavingNote) name:NOTIFICATION_KEY_BACKUP_SUCCESS object:nil];
}

- (void)getHistoryAfterSavingNote
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_BACKUP_SUCCESS object:nil];
    [app.wallet getHistory];
}

- (void)didGetHistory
{
    if (self.isGettingFiatAtTime) return; // Multiple calls to didGetHistory will occur due to did_set_latest_block and did_multiaddr; prevent observer from being added twice
    [self getFiatAtTime];
}

- (void)reloadDataAfterGetFiatAtTime
{
    self.isGettingFiatAtTime = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_GET_FIAT_AT_TIME object:nil];
    [self reloadData];
}

- (void)reloadData
{
    [self.busyViewDelegate hideBusyView];
    
    NSArray *newTransactions = app.latestResponse.transactions;
    
    [self findAndUpdateTransaction:newTransactions];
    
    [self.tableView reloadData];
    
    if (self.refreshControl && self.refreshControl.isRefreshing) {
        [self.refreshControl endRefreshing];
    }
}

- (void)reloadEtherData
{
    [self.busyViewDelegate hideBusyView];
    
    [self.tableView reloadData];
    
    if (self.refreshControl && self.refreshControl.isRefreshing) {
        [self.refreshControl endRefreshing];
    }
}

- (void)findAndUpdateTransaction:(NSArray *)newTransactions
{
    BOOL didFindTransaction = NO;
    for (Transaction *transaction in newTransactions) {
        if ([transaction.myHash isEqualToString:self.transactionModel.myHash]) {
            transaction.fiatAmountsAtTime = self.transactionModel.fiatAmountsAtTime;
            self.transactionModel = [[TransactionDetailViewModel alloc] initWithTransaction:transaction];
            didFindTransaction = YES;
            break;
        }
    }

    if (!didFindTransaction) {
        [self dismissViewControllerAnimated:YES completion:^{
            [app standardNotify:[NSString stringWithFormat:BC_STRING_COULD_NOT_FIND_TRANSACTION_ARGUMENT, self.transactionModel.myHash]];
        }];
    }
}

- (CGSize)addVerticalPaddingToSize:(CGSize)size
{
    return CGSizeMake(size.width, size.height + 16);
}

- (void)reloadSymbols
{
    [self.recipientsViewController reloadTableView];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self getCellRowValue] inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.transactionModel.doubleSpend || self.transactionModel.replaceByFee ? 7 : 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [self getCellRowWarning]) {
        TransactionDetailDoubleSpendWarningCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_TRANSACTION_DETAIL_WARNING forIndexPath:indexPath];
        [cell configureWithTransactionModel:self.transactionModel];
        return cell;
    } else if (indexPath.row == [self getCellRowValue]) {
        TransactionDetailValueCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_TRANSACTION_DETAIL_VALUE forIndexPath:indexPath];
        cell.valueDelegate = self;
        [cell configureWithTransactionModel:self.transactionModel];
        return cell;
    } else if (indexPath.row == [self getCellRowDescription]) {
        TransactionDetailDescriptionCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_TRANSACTION_DETAIL_DESCRIPTION forIndexPath:indexPath];
        cell.descriptionDelegate = self;
        [cell configureWithTransactionModel:self.transactionModel];
        self.textView = cell.textView;
        cell.textView.inputAccessoryView = [self getDescriptionInputAccessoryView];
        return cell;
    } else if (indexPath.row == [self getCellRowTo]) {
        TransactionDetailToCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_TRANSACTION_DETAIL_TO forIndexPath:indexPath];
        [cell configureWithTransactionModel:self.transactionModel];
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showToAddressOptions)];
        tapGestureRecognizer.numberOfTapsRequired = 1;
        [cell.accessoryLabel addGestureRecognizer:tapGestureRecognizer];
        cell.accessoryLabel.userInteractionEnabled = YES;
        
        return cell;
    } else if (indexPath.row == [self getCellRowFrom]) {
        TransactionDetailFromCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_TRANSACTION_DETAIL_FROM forIndexPath:indexPath];
        [cell configureWithTransactionModel:self.transactionModel];
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showFromAddressOptions)];
        tapGestureRecognizer.numberOfTapsRequired = 1;
        [cell.accessoryLabel addGestureRecognizer:tapGestureRecognizer];
        cell.accessoryLabel.userInteractionEnabled = YES;
        
        return cell;
    } else if (indexPath.row == [self getCellRowDate]) {
        TransactionDetailDateCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_TRANSACTION_DETAIL_DATE forIndexPath:indexPath];
        [cell configureWithTransactionModel:self.transactionModel];
        return cell;
    } else if (indexPath.row == [self getCellRowStatus]) {
        TransactionDetailStatusCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_TRANSACTION_DETAIL_STATUS forIndexPath:indexPath];
        cell.statusDelegate = self;
        [cell configureWithTransactionModel:self.transactionModel];
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [self getCellRowTo] && self.transactionModel.to.count > 1) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self showRecipients];
        return;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [self getCellRowWarning]) {
        return rowHeightWarning;
    } else if (indexPath.row == [self getCellRowValue]) {
        return [self.transactionModel.txType isEqualToString:TX_TYPE_RECEIVED] ? rowHeightValueReceived : rowHeightValue;
    } else if (indexPath.row == [self getCellRowDescription] && self.textView.text) {
        return UITableViewAutomaticDimension;
    } else if (indexPath.row == [self getCellRowTo]) {
        return rowHeightDefault;
    } else if (indexPath.row == [self getCellRowFrom]) {
        return rowHeightDefault/2 + 20.5/2;
    } else if (indexPath.row == [self getCellRowStatus]) {
        return rowHeightDefault + 80;
    }
    return rowHeightDefault;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return rowHeightDefault;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [self getCellRowTo]) {
        [cell setSeparatorInset:UIEdgeInsetsMake(0, 15, 0, CGRectGetWidth(cell.bounds)-15)];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 50;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *spacer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 50)];
    return spacer;
}

- (void)showRecipients
{
    self.recipientsViewController = [[TransactionRecipientsViewController alloc] initWithRecipients:self.transactionModel.to];
    self.recipientsViewController.recipientsDelegate = self;
    [self.navigationController pushViewController:self.recipientsViewController animated:YES];
}

- (void)setupPullToRefresh
{
    // Tricky way to get the refreshController to work on a UIViewController - @see http://stackoverflow.com/a/12502450/2076094
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl setTintColor:[UIColor grayColor]];
    [self.refreshControl addTarget:self
                       action:@selector(refreshControlActivated)
             forControlEvents:UIControlEventValueChanged];
    tableViewController.refreshControl = self.refreshControl;
}

- (void)refreshControlActivated
{
    [self.busyViewDelegate showBusyViewWithLoadingText:BC_STRING_LOADING_LOADING_TRANSACTIONS];
    [app.wallet performSelector:@selector(getHistory) withObject:nil afterDelay:0.1f];
}

- (void)showToAddressOptions
{
    [self showAddressOptions:[self.transactionModel.to firstObject]];
}

- (void)showFromAddressOptions
{
    [self showAddressOptions:self.transactionModel];
}

- (void)showAddressOptions:(TransactionDetailViewModel *)transactionModel
{
    NSString *address = transactionModel.fromAddress;
    
    if (transactionModel.fromWithinWallet) return;
    
    UIAlertController *copyAddressController = [UIAlertController alertControllerWithTitle:transactionModel.fromString message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [copyAddressController addAction:[UIAlertAction actionWithTitle:BC_STRING_COPY_ADDRESS style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [UIPasteboard generalPasteboard].string = address;
    }]];
    [copyAddressController addAction:[UIAlertAction actionWithTitle:BC_STRING_SEND_TO_ADDRESS style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:^{
            [app setupSendToAddress:address];
        }];
    }]];
    [copyAddressController addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:copyAddressController animated:YES completion:nil];
}

#pragma mark - Cell Row Getters

- (int)getCellRow:(int)cellConstant
{
    return self.transactionModel.doubleSpend || self.transactionModel.replaceByFee ? cellConstant : cellConstant - 1;
}

- (int)getCellRowWarning
{
    return [self getCellRow:cellRowWarning];
}

- (int)getCellRowValue
{
    return [self getCellRow:cellRowValue];
}

- (int)getCellRowDescription
{
    return [self getCellRow:cellRowDescription];
}

- (int)getCellRowTo
{
    return [self getCellRow:cellRowTo];
}

- (int)getCellRowFrom
{
    return [self getCellRow:cellRowFrom];
}

- (int)getCellRowDate
{
    return [self getCellRow:cellRowDate];
}

- (int)getCellRowStatus
{
    return [self getCellRow:cellRowStatus];
}

#pragma mark - Detail Delegate

- (void)toggleSymbol
{
    [app toggleSymbol];
}

- (void)textViewDidChange:(UITextView *)textView
{
    CGPoint currentOffset = self.tableView.contentOffset;
    [UIView setAnimationsEnabled:NO];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    [UIView setAnimationsEnabled:YES];
    self.tableView.contentOffset = currentOffset;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CGRect keyboardAccessoryRect = [self.descriptionInputAccessoryView.superview convertRect:self.descriptionInputAccessoryView.frame toView:self.tableView];
        CGRect keyboardPlusAccessoryRect = CGRectMake(keyboardAccessoryRect.origin.x, keyboardAccessoryRect.origin.y, keyboardAccessoryRect.size.width, self.view.frame.size.height - keyboardAccessoryRect.origin.y);
        
        UITextRange *selectionRange = [textView selectedTextRange];
        CGRect selectionEndRect = [textView convertRect:[textView caretRectForPosition:selectionRange.end] toView:self.tableView];
        
        if (CGRectIntersectsRect(keyboardPlusAccessoryRect, selectionEndRect)) {
            [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentOffset.y + selectionEndRect.origin.y + selectionEndRect.size.height - keyboardAccessoryRect.origin.y + 15) animated:NO];
        }
    });
}

- (void)showWebviewDetail
{
    NSURL *url = [NSURL URLWithString:self.transactionModel.detailButtonLink];
    
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:url];
        if (safariViewController) {
            [self presentViewController:safariViewController animated:YES completion:nil];
        } else {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

- (NSString *)getCurrencyCode
{
    return [app.latestResponse.symbol_local.code lowercaseString];
}

- (CGFloat)getDefaultRowHeight
{
    return rowHeightDefault;
}

- (NSRange)getTextViewCursorPosition
{
    return self.textViewCursorPosition;
}

- (void)setDefaultTextViewCursorPosition:(NSUInteger)textLength
{
    self.textViewCursorPosition = NSMakeRange(textLength, 0);
    _didSetTextViewCursorPosition = YES;
}

- (UIView *)getDescriptionInputAccessoryView
{
    return self.textView.isEditable ? self.descriptionInputAccessoryView : nil;
}

#pragma mark - Recipients Delegate

- (BOOL)isWatchOnlyLegacyAddress:(NSString *)addr
{
    return [app.wallet isWatchOnlyLegacyAddress:addr];
}

@end
