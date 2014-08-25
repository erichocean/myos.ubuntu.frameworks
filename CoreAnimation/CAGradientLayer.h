/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

@class CALayer;

extern NSString *const kCAGradientLayerAxial;

// Displays a gradient of colors
@interface CAGradientLayer : CALayer
{
@package
    NSArray *colors;
    NSArray *locations;
    CGPoint startPoint;
    CGPoint endPoint;
    NSString *type;
}

@property (copy) NSArray *colors;
@property (copy) NSArray *locations;
@property CGPoint startPoint;
@property CGPoint endPoint;
@property (copy) NSString *type;

@end
