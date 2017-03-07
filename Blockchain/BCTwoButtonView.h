//
//  BCTwoButtonView.h
//  Blockchain
//
//  Created by kevinwu on 3/7/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol TwoButtonDelegate <NSObject>
- (void)topButtonClicked;
- (void)bottomButtonClicked;
@end

@interface BCTwoButtonView : UIView
- (id)initWithTopButtonText:(NSString *)topText bottomButtonText:(NSString *)bottomText;
@property (nonatomic) UIViewController <TwoButtonDelegate> *delegate;
@end
