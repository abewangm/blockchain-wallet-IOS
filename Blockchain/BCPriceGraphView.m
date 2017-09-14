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
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    NSArray *sortedYCoordinates = [self.graphValues sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        return [[numberFormatter numberFromString:[obj1 objectForKey:DICTIONARY_KEY_PRICE]] compare:[numberFormatter numberFromString:[obj2 objectForKey:DICTIONARY_KEY_PRICE]]];
    }];
    
    CGFloat minY = [[[sortedYCoordinates firstObject] objectForKey:DICTIONARY_KEY_PRICE] floatValue];
    CGFloat maxY = [[[sortedYCoordinates lastObject] objectForKey:DICTIONARY_KEY_PRICE] floatValue];
    
    self.minY = minY;
    self.maxY = maxY;
    
    [self setNeedsDisplay];
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
