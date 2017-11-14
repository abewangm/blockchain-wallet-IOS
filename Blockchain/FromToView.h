//
//  FromToView.h
//  Blockchain
//
//  Created by kevinwu on 11/14/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FromToView : UIView
@property (nonatomic) UILabel *fromLabel;
@property (nonatomic) UIImageView *fromImageView;
@property (nonatomic) UILabel *toLabel;
@property (nonatomic) UITextField *toField;
@property (nonatomic) UIImageView *toImageView;

// Default height 96
- (id)initWithFrame:(CGRect)frame enableToTextField:(BOOL)enableToTextField;
@end
