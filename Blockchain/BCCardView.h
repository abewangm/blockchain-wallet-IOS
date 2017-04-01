//
//  BCCardView.h
//  Blockchain
//
//  Created by kevinwu on 3/28/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
    ActionTypeBuyBitcoin,
    ActionTypeShowReceive,
    ActionTypeScanQR,
};

typedef NSInteger ActionType;

@protocol CardViewDelegate
- (void)actionClicked:(ActionType)actionType;
@end
@interface BCCardView : UIView
@property (nonatomic) id<CardViewDelegate> delegate;
- (id)initWithContainerFrame:(CGRect)frame title:(NSString *)title description:(NSString *)description actionType:(ActionType)actionType imageName:(NSString *)imageName delegate:(id<CardViewDelegate>)delegate;
+ (CGRect)frameFromContainer:(CGRect)containerFrame;
@end
