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
    self.view.backgroundColor = COLOR_TABLE_VIEW_BACKGROUND_LIGHT_GRAY;
    
    ExchangeDetailView *detailView = [[ExchangeDetailView alloc] initWithFrame:CGRectMake(0, 0, WINDOW_WIDTH, 0) fetchedTrade:self.trade];
    
    CGFloat windowWidth = WINDOW_WIDTH;
    BOOL isUsingLargerScreen = IS_USING_SCREEN_SIZE_LARGER_THAN_5S;
    UIView *summaryView = [[UIView alloc] initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT, windowWidth, isUsingLargerScreen ? 250 : self.view.frame.size.height - detailView.frame.size.height - 24 - DEFAULT_HEADER_HEIGHT)];

    UITextView *descriptionTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    descriptionTextView.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_EXTRA_SMALL];
    descriptionTextView.text = @"description text";
    descriptionTextView.backgroundColor = [UIColor clearColor];
    descriptionTextView.editable = NO;
    descriptionTextView.selectable = NO;
    [descriptionTextView sizeToFit];
    [descriptionTextView changeYPosition:summaryView.frame.size.height - descriptionTextView.frame.size.height];
    descriptionTextView.center = CGPointMake(summaryView.frame.size.width/2, descriptionTextView.center.y);
    [summaryView addSubview:descriptionTextView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    titleLabel.text = @"title text";
    titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_EXTRA_SMALL];
    [titleLabel sizeToFit];
    [titleLabel changeYPosition:descriptionTextView.frame.origin.y - titleLabel.frame.size.height - 8];
    titleLabel.center = CGPointMake(summaryView.frame.size.width/2, titleLabel.center.y);
    [summaryView addSubview:titleLabel];
    
    UIImageView *iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 20, 100, summaryView.frame.size.height/2)];
    iconImageView.center = CGPointMake(summaryView.frame.size.width/2, iconImageView.center.y);
    
    [summaryView addSubview:iconImageView];
    
    [self.view addSubview:summaryView];
    
    [detailView changeYPosition:summaryView.frame.origin.y + summaryView.frame.size.height + 16];
    
    [self.view addSubview:detailView];
}

@end
