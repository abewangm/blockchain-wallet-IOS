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
    
    NSArray *sortedYCoordinates = [self.graphValues sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        return [[obj1 objectForKey:DICTIONARY_KEY_PRICE] compare:[obj2 objectForKey:DICTIONARY_KEY_PRICE]];
    }];
    
    CGFloat minY = [[[sortedYCoordinates firstObject] objectForKey:DICTIONARY_KEY_PRICE] floatValue];
    CGFloat maxY = [[[sortedYCoordinates lastObject] objectForKey:DICTIONARY_KEY_PRICE] floatValue];

    int digitsToKeep = 0;
//
//    if ([self greatestPlaceValueFloor:maxY digitsToKeep:0] - [self greatestPlaceValueFloor:minY digitsToKeep:0] < 1) {
//        digitsToKeep = 1;
//    } else if ([self greatestPlaceValueFloor:maxY digitsToKeep:1] - [self greatestPlaceValueFloor:minY digitsToKeep:1] < 1) {
//        digitsToKeep = 2;
//    }
    
    CGFloat greatestPlaceValueMinY = [self greatestPlaceValueFloor:minY digitsToKeep:0];
    CGFloat greatestPlaceValueMaxY = [self greatestPlaceValueFloor:maxY digitsToKeep:0];
    
    while (greatestPlaceValueMaxY - greatestPlaceValueMinY < 1) {
        digitsToKeep++;
        greatestPlaceValueMinY = [self greatestPlaceValueFloor:minY digitsToKeep:digitsToKeep];
        greatestPlaceValueMaxY = [self greatestPlaceValueFloor:maxY digitsToKeep:digitsToKeep];
    }
    
    self.minY = greatestPlaceValueMinY;
    self.maxY = [self greatestPlaceValueCeiling:maxY digitsToKeep:digitsToKeep];
    
    [self setNeedsDisplay];
}

- (CGFloat)greatestPlaceValueCeiling:(CGFloat)value digitsToKeep:(CGFloat)digitsToKeep
{
    CGFloat digits = floorf(log10(value)) - digitsToKeep;
    CGFloat roundedInterval = pow(10.0, digits) * ceilf(value/pow(10.0, digits));
    return roundedInterval;
}

- (CGFloat)greatestPlaceValueFloor:(CGFloat)value digitsToKeep:(CGFloat)digitsToKeep
{
    CGFloat digits = floorf(log10(value)) - digitsToKeep;
    CGFloat roundedInterval = pow(10.0, digits) * floorf(value/pow(10.0, digits));
    return roundedInterval;
}

- (void)drawRect:(CGRect)rect
{
    CGFloat minX = [[[self.graphValues firstObject] objectForKey:DICTIONARY_KEY_TIMESTAMP] floatValue];
    CGFloat maxX = [[[self.graphValues lastObject] objectForKey:DICTIONARY_KEY_TIMESTAMP] floatValue];
    
    CGFloat timeLength = maxX - minX;
    CGFloat priceHeight = self.maxY - self.minY;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    [self.graphValues enumerateObjectsUsingBlock:^(NSDictionary *coordinate, NSUInteger index, BOOL *stop) {
        CGFloat convertedXCoordinate = ([[coordinate objectForKey:DICTIONARY_KEY_TIMESTAMP] floatValue] - minX) / timeLength * self.bounds.size.width;
        CGFloat convertedYCoordinate = (1 - ([[coordinate objectForKey:DICTIONARY_KEY_PRICE] floatValue] - self.minY) / priceHeight) * self.bounds.size.height;
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
