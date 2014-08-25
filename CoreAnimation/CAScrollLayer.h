/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <CoreAnimation/CALayer.h>

extern NSString *const kCAScrollNone;
extern NSString *const kCAScrollVertically;
extern NSString *const kCAScrollHorizontally;
extern NSString *const kCAScrollBoth;

@interface CAScrollLayer : CALayer
{
@package
	NSString *scrollMode;
}

@property (copy) NSString *scrollMode;

- (void)scrollToPoint:(CGPoint)point;
- (void)scrollToRect:(CGRect)rect;

@end

@interface CALayer (CALayerScrolling)

- (void)scrollPoint:(CGPoint)point;
- (void)scrollRectToVisible:(CGRect)rect;
- (CGRect)visibleRect;

@end
