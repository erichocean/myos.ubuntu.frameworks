/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import "SmileyFaceView.h"

@implementation SmileyFaceView

#pragma mark - Life cycle

- (id)initWithFrame:(CGRect)theFrame
{
    self = [super initWithFrame:theFrame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:0.7];
        //self.backgroundColor = [UIColor yellowColor];
    }
    return self;
}

#pragma mark - Overridden methods

- (void)drawRect:(CGRect)theRect
{
//    return;
    //DLog(@"theRect: %@", NSStringFromCGRect(theRect));
    CGContextRef aContext = UIGraphicsGetCurrentContext();
    //CGContextSaveGState(aContext);

    //CGContextSetRGBFillColor(aContext, 1, 1, 0, 0.7);
    //CGContextSetFillColorWithColor(aContext, [self.backgroundColor CGColor]);
    //CGContextFillRect(aContext, self.bounds);
    
    CGContextSetRGBStrokeColor(aContext, 0, 0, 0, 0.7);
    CGContextStrokeRect(aContext, self.bounds);

    // Draw a smiley
    //DLog(@"Draw a smiley");
    CGContextBeginPath(aContext);
    //DLog("CGContextIsPathEmpty: %d", CGContextIsPathEmpty(aContext));
    CGContextMoveToPoint(aContext,14,35); CGContextAddArc(aContext,10,35,4,0,2*PI,0); CGContextClosePath(aContext);
    CGContextMoveToPoint(aContext,44,35); CGContextAddArc(aContext,40,35,4,0,2*PI,0); CGContextClosePath(aContext);
    CGContextMoveToPoint(aContext,16,15); CGContextAddArc(aContext,12,15,4,0,2*PI,0); CGContextClosePath(aContext);
    CGContextMoveToPoint(aContext,23,10); CGContextAddArc(aContext,19,10,4,0,2*PI,0); CGContextClosePath(aContext);
    CGContextMoveToPoint(aContext,29,8);  CGContextAddArc(aContext,25,8,4,0,2*PI,0);  CGContextClosePath(aContext);
    CGContextMoveToPoint(aContext,35,10); CGContextAddArc(aContext,31,10,4,0,2*PI,0); CGContextClosePath(aContext);
    CGContextMoveToPoint(aContext,42,15); CGContextAddArc(aContext,38,15,4,0,2*PI,0); CGContextClosePath(aContext);

    //DLog(@"");
    CGContextSetRGBFillColor(aContext, 1, 0, 0, 0.5);
    CGContextSetRGBStrokeColor(aContext, 0, 0, 0, 1);
    CGContextDrawPath(aContext, kCGPathFillStroke);
    //CGContextRestoreGState(aContext);
}

@end

