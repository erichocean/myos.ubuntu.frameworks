/*
 Copyright © 2014 myOS Group.
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 Lesser General Public License for more details.
 
 Contributor(s):
 Amr Aboelela <amraboelela@gmail.com>
 */

@class CALayer;

extern NSString *const kCAGradientLayerAxial;

// Displays a gradient of colors
@interface CAGradientLayer : CALayer {
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
