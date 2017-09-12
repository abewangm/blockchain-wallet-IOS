//
//  BCPriceGraphView.m
//  Blockchain
//
//  Created by kevinwu on 9/5/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCPriceGraphView.h"
#import <CoreGraphics/CoreGraphics.h>

@interface BCPriceGraphView ()
@property (nonatomic) NSArray *graphValues;
@end
@implementation BCPriceGraphView

- (void)setGraphValues:(NSArray *)values
{
    _graphValues = values;
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGFloat minX = [[[self.graphValues firstObject] objectForKey:DICTIONARY_KEY_X] floatValue];
    CGFloat maxX = [[[self.graphValues lastObject] objectForKey:DICTIONARY_KEY_X] floatValue];
    CGFloat timeLength = maxX - minX;
    
    NSArray *sortedYCoordinates = [self.graphValues sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        return [[obj1 objectForKey:DICTIONARY_KEY_Y] compare:[obj2 objectForKey:DICTIONARY_KEY_Y]];
    }];
    
    CGFloat minY = [[[sortedYCoordinates firstObject] objectForKey:DICTIONARY_KEY_Y] floatValue];
    CGFloat maxY = [[[sortedYCoordinates lastObject] objectForKey:DICTIONARY_KEY_Y] floatValue];
    
    self.minY = minY;
    self.maxY = maxY;
    
    CGFloat priceHeight = maxY - minY;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    [self.graphValues enumerateObjectsUsingBlock:^(NSDictionary *coordinate, NSUInteger index, BOOL *stop) {
        CGFloat convertedXCoordinate = ([[coordinate objectForKey:DICTIONARY_KEY_X] floatValue] - minX) / timeLength * self.bounds.size.width;
        CGFloat convertedYCoordinate = (1 - ([[coordinate objectForKey:DICTIONARY_KEY_Y] floatValue] - minY) / priceHeight) * self.bounds.size.height;
        if (index == 0) {
            [path moveToPoint:CGPointMake(convertedXCoordinate, convertedYCoordinate)];
        } else {
            [path addLineToPoint:CGPointMake(convertedXCoordinate, convertedYCoordinate)];
        }
    }];
    
    [COLOR_BLOCKCHAIN_BLUE setStroke];
    [path stroke];
}

@end
