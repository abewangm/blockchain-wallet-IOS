//
//  TransactionDetailViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 8/23/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransactionDetailViewController.h"
#import "TransactionDetailTableCell.h"

const int cellRowValue = 0;
const int cellRowDescription = 1;
const int cellRowToFrom = 2;
const int cellRowDate = 3;
const int cellRowStatus = 4;

@interface TransactionDetailViewController () <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, DetailViewDelegate>

@property (nonatomic) UITableView *tableView;
@property (nonatomic) UITextView *textView;
@property CGFloat oldTextViewHeight;

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
    
    cell.clipsToBounds = YES;
    
    if (indexPath.row == cellRowDescription) {
        cell.frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height < 60 ? 60 : cell.frame.size.height);
        [cell addTextView];
        self.oldTextViewHeight = cell.textView.frame.size.height;
        cell.detailViewDelegate = self;
        self.textView = cell.textView;
    } else if (indexPath.row == cellRowToFrom) {
        [cell addToAndFromLabels];
    } else if (indexPath.row == cellRowDate) {
        cell.textLabel.text = BC_STRING_DATE;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == cellRowDescription && self.textView.text) {
        CGSize size = [self.textView sizeThatFits:CGSizeMake(self.textView.frame.size.width, FLT_MAX)];
        CGSize sizeToUse = [self addVerticalPaddingToSize:size];
        return sizeToUse.height < 60 ? 60 : sizeToUse.height;
    } else if (indexPath.row == cellRowToFrom) {
        return 88;
    }
    return 44;
}

@end
