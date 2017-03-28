//
//  BCCardView.h
//  Blockchain
//
//  Created by kevinwu on 3/28/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol CardViewDelegate
- (void)actionClicked;
@end
@interface BCCardView : UIView

- (id)initWithContainerFrame:(CGRect)frame title:(NSString *)title description:(NSString *)description actionName:(NSString *)actionName imageName:(NSString *)imageName delegate:(id<CardViewDelegate>)delegate;

@end
