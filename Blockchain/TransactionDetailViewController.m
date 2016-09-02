//
//  TransactionDetailViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 8/23/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransactionDetailViewController.h"
#import "TransactionDetailTableCell.h"
#import "NSNumberFormatter+Currencies.h"
#import "RootService.h"
#import "TransactionDetailNavigationController.h"

#ifdef DEBUG
#import "UITextView+AssertionFailureFix.h"
#endif

const int cellRowValue = 0;
const int cellRowDescription = 1;
const int cellRowToFrom = 2;
const int cellRowDate = 3;
const int cellRowStatus = 4;

const CGFloat rowHeightDefault = 60;
const CGFloat rowHeightValue = 108;
const CGFloat rowHeightToFrom = 88;

@interface TransactionDetailViewController () <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, DetailViewDelegate>

@property (nonatomic) UITableView *tableView;
@property (nonatomic) UITextView *textView;
@property CGFloat oldTextViewHeight;
@property (nonatomic) UIView *descriptonInputAccessoryView;

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
    [self.tableView registerClass:[TransactionDetailTableCell class] forCellReuseIdentifier:CELL_IDENTIFIER_TRANSACTION_DETAIL];
    self.tableView.tableFooterView = [UIView new];
    
    [self setupTextViewInputAccessoryView];
}

- (void)setupTextViewInputAccessoryView
{
    UIView *inputAccessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, BUTTON_HEIGHT)];
    inputAccessoryView.backgroundColor = [UIColor redColor];
    
    UIButton *updateButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, BUTTON_HEIGHT)];
    updateButton.backgroundColor = COLOR_BUTTON_GREEN;
    [updateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [updateButton setTitle:BC_STRING_UPDATE forState:UIControlStateNormal];
    [updateButton addTarget:self action:@selector(saveNote) forControlEvents:UIControlEventTouchUpInside];
    [inputAccessoryView addSubview:updateButton];
    
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(updateButton.frame.size.width - 50, 0, 50, BUTTON_HEIGHT)];
    cancelButton.backgroundColor = COLOR_BUTTON_GRAY_CANCEL;
    [cancelButton setImage:[UIImage imageNamed:@"cancel"] forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(endEditing) forControlEvents:UIControlEventTouchUpInside];
    [inputAccessoryView addSubview:cancelButton];
    
    self.descriptonInputAccessoryView = inputAccessoryView;
}

- (void)endEditing
{
    [self.textView resignFirstResponder];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:cellRowDescription inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)textViewDidChange:(UITextView *)textView
{
    CGSize size = [self.textView sizeThatFits:CGSizeMake(self.textView.frame.size.width, FLT_MAX)];
    if (size.height != self.oldTextViewHeight) {
        self.oldTextViewHeight = size.height;
        self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y, self.textView.frame.size.width, size.height);
        [UIView setAnimationsEnabled:NO];
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
        [UIView setAnimationsEnabled:YES];
    }
}

- (void)saveNote
{
    [self.textView resignFirstResponder];
    
    TransactionDetailNavigationController *navigationController = (TransactionDetailNavigationController *)self.navigationController;
    [navigationController.busyView fadeIn];
    
    [app.wallet saveNote:self.textView.text forTransaction:self.transaction.myHash];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getHistory) name:NOTIFICATION_KEY_BACKUP_SUCCESS object:nil];
}

- (void)getHistory
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_BACKUP_SUCCESS object:nil];
    [app.wallet getHistory];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:NOTIFICATION_KEY_GET_HISTORY_SUCCESS object:nil];
}

- (void)reloadData
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_GET_HISTORY_SUCCESS object:nil];
    
    TransactionDetailNavigationController *navigationController = (TransactionDetailNavigationController *)self.navigationController;
    [navigationController.busyView fadeOut];
    
    NSArray *newTransactions = app.latestResponse.transactions;
    
    if (newTransactions.count >= self.transactionCount) {
        self.transaction = [newTransactions objectAtIndex:self.transactionIndex + (newTransactions.count - self.transactionCount)];
    } else {
        DLog(@"Error reloading transcation details: new transaction count is less than old transaction count!");
    }
    
    self.transactionCount = newTransactions.count;
    
    [self.tableView reloadData];
}

- (CGSize)addVerticalPaddingToSize:(CGSize)size
{
    return CGSizeMake(size.width, size.height + 16);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TransactionDetailTableCell *cell = (TransactionDetailTableCell *)[tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_TRANSACTION_DETAIL forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.clipsToBounds = YES;
    
    if (indexPath.row == cellRowValue) {
        [cell configureValueCell:self.transaction];
    } else if (indexPath.row == cellRowDescription) {
        // Set initial height for sizeThatFits: calculation
        cell.frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height < rowHeightDefault ? rowHeightDefault : cell.frame.size.height);
        
        [cell configureDescriptionCell:self.transaction];
        
        self.oldTextViewHeight = cell.textView.frame.size.height;
        cell.detailViewDelegate = self;
        self.textView = cell.textView;
        cell.textView.inputAccessoryView = self.descriptonInputAccessoryView;
    } else if (indexPath.row == cellRowToFrom) {
        [cell configureToFromCell:self.transaction];
    } else if (indexPath.row == cellRowDate) {
        [cell configureDateCell:self.transaction];
    } else if (indexPath.row == cellRowStatus) {
        [cell configureStatusCell:self.transaction];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == cellRowValue) {
        return rowHeightToFrom;
    } else if (indexPath.row == cellRowDescription && self.textView.text) {
        CGSize size = [self.textView sizeThatFits:CGSizeMake(self.textView.frame.size.width, FLT_MAX)];
        CGSize sizeToUse = [self addVerticalPaddingToSize:size];
        return sizeToUse.height < rowHeightDefault ? rowHeightDefault : sizeToUse.height;
    } else if (indexPath.row == cellRowToFrom) {
        return rowHeightToFrom;
    }
    return rowHeightDefault;
}

@end
