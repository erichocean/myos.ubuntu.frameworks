/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
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

#pragma mark - Helpers

- (void)scrollToPoint:(CGPoint)point
{
    self.frame = CGRectMake(point.x, point.y, bounds.size.width, bounds.size.height);
}

- (void)scrollToRect:(CGRect)rect
{
    self.frame = CGRectMake(rect.origin.x, rect.origin.y, bounds.size.width, bounds.size.height);
}

@end

static CAScrollLayer *closestCAScrollLayerAncestorFromLayer(CALayer *layer)
{
    if ([layer isKindOfClass:[CAScrollLayer class]]) {
        return (CAScrollLayer *)layer;
    } else {
        return closestCAScrollLayerAncestorFromLayer(layer->superlayer);
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
    return visibleRect;
}

@end

