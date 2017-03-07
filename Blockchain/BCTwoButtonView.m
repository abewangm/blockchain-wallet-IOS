//
//  BCTwoButtonView.m
//  Blockchain
//
//  Created by kevinwu on 3/7/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCTwoButtonView.h"
#import "RootService.h"

@interface BCTwoButtonView()
@end

@implementation BCTwoButtonView

- (id)initWithTopButtonText:(NSString *)topText bottomButtonText:(NSString *)bottomText
{
    UIWindow *window = app.window;
    
    self = [super initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT, window.frame.size.width, window.frame.size.height - DEFAULT_HEADER_HEIGHT)];

    if (self) {
        
        CGFloat buttonHeight = 100;

        UIButton *topButton = [[UIButton alloc] initWithFrame:CGRectMake(20, self.frame.size.height/2 - buttonHeight - DEFAULT_HEADER_HEIGHT, self.frame.size.width - 40, buttonHeight)];
        topButton.backgroundColor = COLOR_BUTTON_BLUE;
        topButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:13];
        topButton.layer.cornerRadius = 8;
        [topButton setTitle:topText forState:UIControlStateNormal];
        topButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        topButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [topButton addTarget:self action:@selector(topButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:topButton];
        
        UIButton *bottomButton = [[UIButton alloc] initWithFrame:CGRectMake(20, topButton.frame.origin.y + topButton.frame.size.height + 16, self.frame.size.width - 40, buttonHeight)];
        bottomButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:13];
        bottomButton.backgroundColor = COLOR_BUTTON_RED;
        bottomButton.layer.cornerRadius = 8;
        bottomButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        bottomButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [bottomButton setTitle:bottomText forState:UIControlStateNormal];
        [bottomButton addTarget:self action:@selector(bottomButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:bottomButton];
    }
    return self;
}

- (void)topButtonClicked
{
    [self.delegate topButtonClicked];
}

- (void)bottomButtonClicked
{
    [self.delegate bottomButtonClicked];
}

- (void)dismissContactController
{
    [self.delegate dismissViewControllerAnimated:YES completion:nil];
}

@end
