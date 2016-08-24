//
//  TransactionDetailViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 8/23/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransactionDetailViewController.h"
#import "TransactionDetailTableCell.h"

@interface TransactionDetailViewController () <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>

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
    [self.tableView registerClass:[TransactionDetailTableCell class] forCellReuseIdentifier:@"detail"];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TransactionDetailTableCell *cell = (TransactionDetailTableCell *)[tableView dequeueReusableCellWithIdentifier:@"detail" forIndexPath:indexPath];
    
    if (indexPath.row == 2) {
        cell.textView = [[UITextView alloc] initWithFrame:CGRectMake(cell.frame.size.width/2, 0, cell.frame.size.width/2, 44)];
        cell.textView.textAlignment = NSTextAlignmentRight;
        cell.textView.backgroundColor = [UIColor redColor];
        self.oldTextViewHeight = cell.textView.frame.size.height;
        cell.textView.delegate = self;
        [cell addSubview:cell.textView];
        self.textView = cell.textView;
    } else {

    }
    
    cell.textLabel.text = @"Test";
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 2 && self.textView.text) {
        CGSize size = [self.textView sizeThatFits:CGSizeMake(self.textView.frame.size.width, FLT_MAX)];
        return size.height < 44 ? 44 : size.height;
    }
    return 44;
}

@end
