//
//  BCPriceGraphView.h
//  Blockchain
//
//  Created by kevinwu on 9/5/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BCPriceGraphView : UIView
@property (nonatomic) float maxY;
@property (nonatomic) float minY;
@property (nonatomic) CGFloat firstQuarter;
@property (nonatomic) CGFloat secondQuarter;
@property (nonatomic) CGFloat thirdQuarter;

- (void)setGraphValues:(NSArray *)values;
@end
