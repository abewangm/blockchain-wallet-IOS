//
//  ExchangeProgressViewController.m
//  Blockchain
//
//  Created by Maurice A. on 11/20/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ExchangeProgressViewController.h"
#import "ExchangeDetailView.h"
#import "UIView+ChangeFrameAttribute.h"

@interface ExchangeProgressViewController ()

@end

@implementation ExchangeProgressViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.view.backgroundColor = COLOR_TABLE_VIEW_BACKGROUND_LIGHT_GRAY;
    
    ExchangeDetailView *detailView = [[ExchangeDetailView alloc] initWithFrame:CGRectMake(0, 0, WINDOW_WIDTH, 0) fetchedTrade:self.trade];
    
    CGFloat windowWidth = WINDOW_WIDTH;
    BOOL isUsingLargerScreen = IS_USING_SCREEN_SIZE_LARGER_THAN_5S;
    UIView *summaryView = [[UIView alloc] initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT, windowWidth, isUsingLargerScreen ? 250 : self.view.frame.size.height - detailView.frame.size.height - 24 - DEFAULT_HEADER_HEIGHT)];

    UITextView *descriptionTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, windowWidth, 0)];
    descriptionTextView.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_EXTRA_SMALL];
    descriptionTextView.textColor = COLOR_TEXT_DARK_GRAY;
    descriptionTextView.text = [self descriptionStringForTrade:self.trade];
    descriptionTextView.textAlignment = NSTextAlignmentCenter;
    descriptionTextView.backgroundColor = [UIColor clearColor];
    descriptionTextView.editable = NO;
    descriptionTextView.selectable = NO;
    [descriptionTextView sizeToFit];
    [descriptionTextView changeYPosition:summaryView.frame.size.height - descriptionTextView.frame.size.height];
    descriptionTextView.center = CGPointMake(summaryView.frame.size.width/2, descriptionTextView.center.y);
    [summaryView addSubview:descriptionTextView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    titleLabel.text = [self titleStringForTrade:self.trade];
    titleLabel.textColor = COLOR_LIGHT_GRAY;
    titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_EXTRA_SMALL];
    [titleLabel sizeToFit];
    [titleLabel changeYPosition:descriptionTextView.frame.origin.y - titleLabel.frame.size.height - 8];
    titleLabel.center = CGPointMake(summaryView.frame.size.width/2, titleLabel.center.y);
    [summaryView addSubview:titleLabel];
    
    CGFloat imageViewHeight = titleLabel.frame.origin.y - 32;
    UIImageView *iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 16, imageViewHeight, imageViewHeight)];
    iconImageView.center = CGPointMake(summaryView.frame.size.width/2, iconImageView.center.y);
    iconImageView.image = [self imageForTrade:self.trade];
    
    [summaryView addSubview:iconImageView];
    
    [self.view addSubview:summaryView];
    
    [detailView changeYPosition:summaryView.frame.origin.y + summaryView.frame.size.height + 16];
    
    [self.view addSubview:detailView];
}

- (UIImage *)imageForTrade:(ExchangeTrade *)trade
{
    if ([trade.status isEqualToString:TRADE_STATUS_COMPLETE]) {
        return [UIImage imageNamed:@"exchange_complete"];
    } else if ([trade.status isEqualToString:TRADE_STATUS_RECEIVED] || [trade.status isEqualToString:TRADE_STATUS_NO_DEPOSITS]) {
        return [UIImage imageNamed:@"exchange_in_progress"];
    }
    
    return nil;
}

- (NSString *)descriptionStringForTrade:(ExchangeTrade *)trade
{
    if ([trade.status isEqualToString:TRADE_STATUS_COMPLETE]) {
        return BC_STRING_COMPLETE;
    } else if ([trade.status isEqualToString:TRADE_STATUS_RECEIVED] || [trade.status isEqualToString:TRADE_STATUS_NO_DEPOSITS]) {
        return BC_STRING_IN_PROGRESS;
    }
    
    return nil;
}

- (NSString *)titleStringForTrade:(ExchangeTrade *)trade
{
    if ([trade.status isEqualToString:TRADE_STATUS_COMPLETE]) {
        return [NSString stringWithFormat:BC_STRING_STEP_ARGUMENT_OF_ARGUMENT, 3, 3];
    } else if ([trade.status isEqualToString:TRADE_STATUS_RECEIVED] || [trade.status isEqualToString:TRADE_STATUS_NO_DEPOSITS]) {
        return [NSString stringWithFormat:BC_STRING_STEP_ARGUMENT_OF_ARGUMENT, 2, 3];
    }
    
    return nil;
}

@end
