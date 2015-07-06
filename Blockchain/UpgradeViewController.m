//
//  UpgradeViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 7/1/15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

#import "UpgradeViewController.h"
#import "AppDelegate.h"
#import "LocalizationConstants.h"
#import "UILabel+MultiLineAutoSize.h"

@interface UpgradeViewController () <UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *captionLabel;
@property (weak, nonatomic) IBOutlet UIButton *upgradeWalletButton;
@property (weak, nonatomic) IBOutlet UIButton *askMeLaterButton;

@property (nonatomic) NSMutableArray *pageViewsMutableArray;
@property (nonatomic) NSArray *captionLabelAttributedStringsArray;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *upgradeButtonToPageControlConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *askLaterButtonToBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollViewToPageControlConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *captionLabelToTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollViewToCaptionLabelConstraint;

@end

@implementation UpgradeViewController

- (IBAction)upgradeWalletButtonTapped:(UIButton *)sender
{
    [self alertUserToConfirmUpgrade];
}

- (void)alertUserToConfirmUpgrade
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:BC_STRING_UPGRADE_ALERTVIEW_TITLE message:BC_STRING_UPGRADE_ALERTVIEW_MESSAGE delegate:self cancelButtonTitle:BC_STRING_UPGRADE_ALERTVIEW_CANCEL_TITLE otherButtonTitles:BC_STRING_UPGRADE_ALERTVIEW_UPDATE_TITLE, nil];
    alertView.tag = 1;
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1) {
        switch (buttonIndex) {
            case 0: NSLog(@"Cancelled upgrade");
                [self dismissSelf];
                break;
            case 1: NSLog(@"Upgrading wallet");
                [app.wallet loading_start_upgrade_to_hd];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [app.wallet performSelector:@selector(upgradeToHDWallet) withObject:nil afterDelay:0.1f];
                });
                [self dismissSelf];
                break;
        }
    }
}

- (void)dismissSelf
{
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancelButtonTapped:(UIButton *)sender
{
    [self dismissSelf];
}

- (NSArray *)imageNamesArray
{
    return @[@"home_icon_hi", @"home_icon", @"lock_icon"];
}

- (NSArray *)captionLabelStringsArray
{
    return @[BC_STRING_UPGRADE_FEATURE_ONE, BC_STRING_UPGRADE_FEATURE_TWO, BC_STRING_UPGRADE_FEATURE_THREE];
}

- (NSAttributedString *)createBlueAttributedStringWithWideLineSpacingFromString:(NSString *)string
{
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineHeightMultiple = 1.3;
    style.alignment = NSTextAlignmentCenter;
    
    UIFont *font = [UIFont fontWithName:@"Helvetica Neue" size:15];
    
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjects:@[COLOR_BLOCKCHAIN_BLUE, style, font] forKeys:@[NSForegroundColorAttributeName, NSParagraphStyleAttributeName, NSFontAttributeName]];
    
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string attributes:attributesDictionary];
    return attributedString;
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
        
//    TODOUpgrade: Uncomment for production
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
    
    [self setupCaptionLabels];
    
    self.upgradeWalletButton.titleLabel.text = BC_STRING_UPGRADE_BUTTON_TITLE;
    self.askMeLaterButton.titleLabel.text = BC_STRING_UPGRADE_ASKLATER_TITLE;
    
    self.pageControl.currentPage = 0;
    self.pageControl.numberOfPages = [[self imageNamesArray] count];
    
    self.pageViewsMutableArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < [[self imageNamesArray] count]; i++) {
        [self.pageViewsMutableArray addObject:[NSNull null]];
    }
    
    [self setTextForCaptionLabel];
}

- (void)setupCaptionLabels
{
    NSMutableArray *temporaryMutableArray = [[NSMutableArray alloc] init];
    
    for (NSString *captionString in [self captionLabelStringsArray]) {
        [temporaryMutableArray addObject:[self createBlueAttributedStringWithWideLineSpacingFromString:captionString]];
    }
    
    self.captionLabelAttributedStringsArray = [[NSArray alloc] initWithArray:temporaryMutableArray];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if([[UIDevice currentDevice]userInterfaceIdiom]==UIUserInterfaceIdiomPhone)
    {
        if ([[UIScreen mainScreen] bounds].size.height >= 568)
        {
            // Not iphone 4s
            self.upgradeButtonToPageControlConstraint.constant = 35;
            self.askLaterButtonToBottomConstraint.constant = 15;
            self.scrollViewToPageControlConstraint.constant = 8;
            self.captionLabelToTopConstraint.constant = 12;
            self.scrollViewToCaptionLabelConstraint.constant = 16;
            [self.view layoutIfNeeded];
        }
    }
    
    CGSize pagesScrollViewSize = self.scrollView.frame.size;
    self.scrollView.contentSize = CGSizeMake(pagesScrollViewSize.width * [self pageViewsMutableArray].count, pagesScrollViewSize.height);
    self.upgradeWalletButton.clipsToBounds = YES;
    self.upgradeWalletButton.layer.cornerRadius = 20;
    
    [self loadVisiblePages];
}

- (void)setTextForCaptionLabel
{
    [UIView transitionWithView:self.captionLabel duration:0.25f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.captionLabel.attributedText = self.captionLabelAttributedStringsArray[self.pageControl.currentPage];
    } completion:nil];
    
    [self.captionLabel adjustFontSizeToFit];
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
