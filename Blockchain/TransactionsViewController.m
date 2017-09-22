//
//  TransactionsViewController.m
//  Blockchain
//
//  Created by kevinwu on 9/9/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransactionsViewController.h"
#import "Assets.h"

@interface TransactionsViewController ()
@property (nonatomic) UILabel *noTransactionsTitle;
@property (nonatomic) UILabel *noTransactionsDescription;
@property (nonatomic) UIButton *getBitcoinButton;

@property (nonatomic) UIView *noTransactionsView;
@end

@implementation TransactionsViewController

- (void)setupNoTransactionsViewInView:(UIView *)view assetType:(AssetType)assetType
{
    [self.noTransactionsView removeFromSuperview];
    
    NSString *descriptionText;
    NSString *buttonText;

    if (assetType == AssetTypeBitcoin) {
        descriptionText = BC_STRING_NO_TRANSACTIONS_TEXT_BITCOIN;
        buttonText = BC_STRING_GET_BITCOIN;
    } else if (assetType == AssetTypeEther) {
        descriptionText = BC_STRING_NO_TRANSACTIONS_TEXT_ETHER;
        buttonText = BC_STRING_REQUEST_ETHER;
    }
    
    self.noTransactionsView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, 0, self.view.frame.size.width, self.view.frame.size.height)];
    
    // Title label Y origin will be above midpoint between end of cards view and table view height
    UILabel *noTransactionsTitle = [[UILabel alloc] initWithFrame:CGRectZero];
    noTransactionsTitle.textAlignment = NSTextAlignmentCenter;
    noTransactionsTitle.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL_MEDIUM];
    noTransactionsTitle.text = BC_STRING_NO_TRANSACTIONS_TITLE;
    noTransactionsTitle.textColor = COLOR_BLOCKCHAIN_BLUE;
    [noTransactionsTitle sizeToFit];
    CGFloat noTransactionsViewCenterY = (view.frame.size.height - self.noTransactionsView.frame.origin.y)/2 - noTransactionsTitle.frame.size.height;
    noTransactionsTitle.center = CGPointMake(self.noTransactionsView.center.x, noTransactionsViewCenterY);
    [self.noTransactionsView addSubview:noTransactionsTitle];
    self.noTransactionsTitle = noTransactionsTitle;
    
    // Description label Y origin will be 8 points under title label
    UILabel *noTransactionsDescription = [[UILabel alloc] initWithFrame:CGRectZero];
    noTransactionsDescription.textAlignment = NSTextAlignmentCenter;
    noTransactionsDescription.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_EXTRA_SMALL];
    noTransactionsDescription.numberOfLines = 0;
    noTransactionsDescription.text = descriptionText;
    noTransactionsDescription.textColor = COLOR_TEXT_DARK_GRAY;
    [noTransactionsDescription sizeToFit];
    CGSize labelSize = [noTransactionsDescription sizeThatFits:CGSizeMake(170, CGFLOAT_MAX)];
    CGRect labelFrame = noTransactionsDescription.frame;
    labelFrame.size = labelSize;
    noTransactionsDescription.frame = labelFrame;
    [self.noTransactionsView addSubview:noTransactionsDescription];
    noTransactionsDescription.center = CGPointMake(self.noTransactionsView.center.x, noTransactionsDescription.center.y);
    noTransactionsDescription.frame = CGRectMake(noTransactionsDescription.frame.origin.x, noTransactionsTitle.frame.origin.y + noTransactionsTitle.frame.size.height + 8, noTransactionsDescription.frame.size.width, noTransactionsDescription.frame.size.height);
    self.noTransactionsDescription = noTransactionsDescription;
    
    // Get bitcoin button Y origin will be 16 points under description label
    self.getBitcoinButton = [[UIButton alloc] initWithFrame:CGRectMake(0, noTransactionsDescription.frame.origin.y + noTransactionsDescription.frame.size.height + 16, 160, 30)];
    self.getBitcoinButton.clipsToBounds = YES;
    self.getBitcoinButton.layer.cornerRadius = CORNER_RADIUS_BUTTON;
    self.getBitcoinButton.backgroundColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
    self.getBitcoinButton.center = CGPointMake(self.noTransactionsView.center.x, self.getBitcoinButton.center.y);
    self.getBitcoinButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_EXTRA_SMALL];
    [self.getBitcoinButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.getBitcoinButton setTitle:[buttonText uppercaseString] forState:UIControlStateNormal];
    [self.getBitcoinButton addTarget:self action:@selector(getBitcoinButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.noTransactionsView addSubview:self.getBitcoinButton];
    
    [self centerNoTransactionSubviews];
    
    [view addSubview:self.noTransactionsView];
}

- (void)getBitcoinButtonClicked
{
    DLog(@"Warning! getBitcoinButtonClicked not overriden!");
}

- (void)centerNoTransactionSubviews
{
    // Reposition description label Y to center of screen, and reposition title and button Y origins around it
    self.noTransactionsDescription.center = CGPointMake(self.noTransactionsTitle.center.x, self.noTransactionsView.frame.size.height/2);
    self.noTransactionsTitle.center = CGPointMake(self.noTransactionsTitle.center.x, self.noTransactionsDescription.frame.origin.y - self.noTransactionsTitle.frame.size.height - 8 + self.noTransactionsTitle.frame.size.height/2);
    self.getBitcoinButton.center = CGPointMake(self.getBitcoinButton.center.x, self.noTransactionsDescription.frame.origin.y + self.noTransactionsDescription.frame.size.height + 16 + self.noTransactionsDescription.frame.size.height/2);
    self.getBitcoinButton.hidden = NO;
}

@end
