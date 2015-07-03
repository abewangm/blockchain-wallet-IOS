//
//  UpgradeViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 7/1/15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

#import "UpgradeViewController.h"
#import "AppDelegate.h"

// Need to be localized

#define UPGRADE_FEATURE_ONE @"Create personalized accounts to help keep your wallet organized"
#define UPGRADE_FEATURE_TWO @"Easy one time wallet backup keeps you in control of your funds"
#define UPGRADE_FEATURE_THREE @"Anything you need to store, spend and receive your bitcoin"

#define UPGRADE_ALERTVIEW_TITLE @"Upgrade Wallet"
#define UPGRADE_ALERTVIEW_MESSAGE @"We've included some significant privacy and security improvements. Once you click update you won't be able to go back to your old wallet"
#define UPGRADE_ALERTVIEW_CANCEL_TITLE @"Not now"
#define UPGRADE_ALERTVIEW_UPDATE_TITLE @"Update"

@interface UpgradeViewController () <UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *captionLabel;
@property (weak, nonatomic) IBOutlet UIButton *upgradeWalletButton;

@property (nonatomic) NSMutableArray *pageViewsMutableArray;

@end

@implementation UpgradeViewController

- (IBAction)upgradeWalletButtonTapped:(UIButton *)sender
{
    [self alertUserToConfirmUpgrade];
}

- (void)alertUserToConfirmUpgrade
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:UPGRADE_ALERTVIEW_TITLE message:UPGRADE_ALERTVIEW_MESSAGE delegate:self cancelButtonTitle:UPGRADE_ALERTVIEW_CANCEL_TITLE otherButtonTitles:UPGRADE_ALERTVIEW_UPDATE_TITLE, nil];
    alertView.tag = 1;
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1) {
        switch (buttonIndex) {
            case 0: NSLog(@"cancel");
                break;
            case 1: NSLog(@"update");
                // TODO call objc completion function first
                [app.wallet loading_start_upgrade_to_hd];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [app.wallet upgradeToHDWallet];
                });
                break;
        }
    }
}

- (IBAction)cancelButtonTapped:(UIButton *)sender
{
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (NSArray *)imageNamesArray
{
    return @[@"home_icon_hi", @"home_icon", @"lock_icon"];
}

- (NSMutableAttributedString *)captionLabelTextAtPageIndex:(NSInteger)index
{
    switch (index) {
        case 0:
            return [self createBlueAttributedStringWithWideLineSpacingFromString:UPGRADE_FEATURE_ONE];
        case 1: return [self createBlueAttributedStringWithWideLineSpacingFromString:UPGRADE_FEATURE_TWO];
        case 2: return [self createBlueAttributedStringWithWideLineSpacingFromString:UPGRADE_FEATURE_THREE];
        default: return nil;
    }
}

- (NSMutableAttributedString *)createBlueAttributedStringWithWideLineSpacingFromString:(NSString *)string
{
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineHeightMultiple = 1.3;
    style.alignment = NSTextAlignmentCenter;
    
    UIFont *font = [UIFont fontWithName:@"Helvetica Neue" size:15];
    
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjects:@[COLOR_BLOCKCHAIN_BLUE, style, font] forKeys:@[NSForegroundColorAttributeName, NSParagraphStyleAttributeName, NSFontAttributeName]];
    
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:string attributes:attributesDictionary];
    return mutableAttributedString;
}

- (void)loadPage:(NSInteger)page
{
    if (page < 0 || page >= [self imageNamesArray].count) {
        return;
    }
    
    UIView *pageView = [self.pageViewsMutableArray objectAtIndex:page];
    
    if ((NSNull*)pageView == [NSNull null]) {
        CGRect frame = self.scrollView.bounds;
        frame.origin.x = frame.size.width * page;
        frame.origin.y = 0.0f;
        
//    TODO: Uncomment for production
//        UIImage *image = [UIImage imageNamed:[[self imageNamesArray] objectAtIndex:page]];
//        UIImageView *newPageView = [[UIImageView alloc] initWithImage:image];
        
        // These two lines are for testing borders only
        UIView *newPageView = [[UIView alloc] init];
        newPageView.backgroundColor = [UIColor greenColor];

        newPageView.contentMode = UIViewContentModeScaleAspectFit;
        newPageView.frame = frame;
        [self.scrollView addSubview:newPageView];
        [self.pageViewsMutableArray replaceObjectAtIndex:page withObject:newPageView];
    }
}

- (void)purgePage:(NSInteger)page {
    
    if (page < 0 || page >= [self imageNamesArray].count) {
        return;
    }
    
    UIView *pageView = [self.pageViewsMutableArray objectAtIndex:page];
    
    if ((NSNull*)pageView != [NSNull null]) {
        [pageView removeFromSuperview];
        [self.pageViewsMutableArray replaceObjectAtIndex:page withObject:[NSNull null]];
    }
}

- (void)loadVisiblePages
{
    CGFloat pageWidth = self.scrollView.frame.size.width;
    NSInteger page = (NSInteger)floor((self.scrollView.contentOffset.x * 2.0f + pageWidth) / (pageWidth * 2.0f));
    
    self.pageControl.currentPage = page;
    
    NSInteger firstPage = page - 1;
    NSInteger lastPage = page + 1;
    
    for (NSInteger i = 0; i < firstPage; i++) {
        [self purgePage:i];
    }
    
    for (NSInteger i = firstPage; i <= lastPage; i++) {
        [self loadPage:i];
    }
    
    for (NSInteger i = lastPage+1; i < [self pageViewsMutableArray].count; i++) {
        [self purgePage:i];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.pageControl.currentPage = 0;
    self.pageControl.numberOfPages = [[self imageNamesArray] count];
    
    self.pageViewsMutableArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < [[self imageNamesArray] count]; i++) {
        [self.pageViewsMutableArray addObject:[NSNull null]];
    }
    
    [self setTextForCaptionLabel];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGSize pagesScrollViewSize = self.scrollView.frame.size;
    self.scrollView.contentSize = CGSizeMake(pagesScrollViewSize.width * [self pageViewsMutableArray].count, pagesScrollViewSize.height);
    self.upgradeWalletButton.clipsToBounds = YES;
    self.upgradeWalletButton.layer.cornerRadius = 20;
    
    [self loadVisiblePages];
}

- (void)setTextForCaptionLabel
{
    [UIView transitionWithView:self.captionLabel duration:0.25f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.captionLabel.attributedText = [self captionLabelTextAtPageIndex:self.pageControl.currentPage];
    } completion:nil];
}

#pragma mark UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self loadVisiblePages];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self setTextForCaptionLabel];
}

@end
