//
//  BCTwoButtonView.h
//  Blockchain
//
//  Created by kevinwu on 3/7/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol TwoButtonDelegate <NSObject>
- (void)topButtonClicked:(NSString *)senderName;
- (void)bottomButtonClicked:(NSString *)senderName;
@end

@interface BCTwoButtonView : UIView
- (id)initWithName:(NSString *)name topButtonText:(NSString *)topText bottomButtonText:(NSString *)bottomText;
@property (nonatomic) UIViewController <TwoButtonDelegate> *delegate;
@end
