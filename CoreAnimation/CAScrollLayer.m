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

#import <CoreAnimation/CAScrollLayer.h>

NSString *const kCAScrollNone = @"CAScrollNone";
NSString *const kCAScrollVertically = @"CAScrollVertically";
NSString *const kCAScrollHorizontally = @"CAScrollHorizontally";
NSString *const kCAScrollBoth = @"CAScrollBoth";

@implementation CAScrollLayer

@synthesize scrollMode;

#pragma mark - Life cycle

- (id)init
{
    self = [super init];
    if (self) {
        scrollMode = [kCAScrollBoth copy];
    }
    return self;
}

- (void)dealloc
{
    [scrollMode release];
    [super dealloc];
}

#pragma mark - Public methods

- (void)scrollToPoint:(CGPoint)point
{
    self.frame = CGRectMake(point.x, point.y, _bounds.size.width, _bounds.size.height);
}

- (void)scrollToRect:(CGRect)rect
{
    self.frame = CGRectMake(rect.origin.x, rect.origin.y, _bounds.size.width, _bounds.size.height);
}

@end

static CAScrollLayer *closestCAScrollLayerAncestorFromLayer(CALayer *layer)
{
    if ([layer isKindOfClass:[CAScrollLayer class]]) {
        return (CAScrollLayer *)layer;
    } else {
        return closestCAScrollLayerAncestorFromLayer(layer->_superlayer);
    }
}

@implementation CALayer(CALayerScrolling)

- (void)scrollPoint:(CGPoint)point
{
    [closestCAScrollLayerAncestorFromLayer(self) scrollToPoint:point];
}

- (void)scrollRectToVisible:(CGRect)rect
{
    [closestCAScrollLayerAncestorFromLayer(self) scrollToRect:rect];
}

- (CGRect)visibleRect
{
    return _visibleRect;
}

@end

