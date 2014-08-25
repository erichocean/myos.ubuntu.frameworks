/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import "ShadowsView.h"

@implementation ShadowsView

#pragma mark - Life cycle

- (id)initWithFrame:(CGRect)theFrame
{
    self = [super initWithFrame:theFrame];
    if (self) {
/*        self.layer.backgroundColor = [[UIColor colorWithRed:0.4 green:0.6 blue:1.0 alpha:1.0] CGColor];
        self.layer.borderColor = [[UIColor brownColor] CGColor];
        self.layer.borderWidth = 3;
        self.layer.cornerRadius = 10;
        self.layer.shadowOpacity = 1.0;
        self.layer.shadowOffset = CGSizeMake(7,-7);
        self.layer.shadowRadius = 1;
        self.layer.masksToBounds = NO;
*/
        //self.backgroundColor = [UIColor blueColor];
    }
    return self;
}

#pragma mark - Overridden methods

- (void)drawRect:(CGRect)rect
{
    DLog(@"rect: %@", NSStringFromCGRect(rect));
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGContextSetRGBFillColor(ctx, 0, 0, 1, 0.5);
    CGContextSetRGBStrokeColor(ctx, 0, 0, 0, 1);
    CGContextFillRect(ctx, CGRectMake(10,10,rect.size.width - 20, rect.size.height - 20));
    CGContextStrokeRect(ctx, CGRectMake(10,10,rect.size.width - 20, rect.size.height - 20));

    CGContextSetShadow(ctx, CGSizeMake(3.0,3.0), 2.0);

    // Draw some rotated, shadowed squares
    CGContextSetRGBFillColor(ctx, 0, 1, 0.5, 1);
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, 225, 125);
    int i;
    for (i = 0; i < 2; i++) {
        CGContextRotateCTM(ctx, 0.4);
        CGContextFillRect(ctx, CGRectMake(-50,-50,100,100));
    }
    CGContextRestoreGState(ctx);

    CGContextSetRGBFillColor(ctx, 1, 0, 0.5, 1);
    CGContextFillRect(ctx, CGRectMake(10, 200, 50, 15));
    CGContextFillRect(ctx, CGRectMake(10, 10, 15, 75));
    CGContextFillRect(ctx, CGRectMake(400, 10, 35, 35));

//    CGSize offset = CGSizeMake(10,10);
    //CGContextSetShadow(ctx,offset,2);

    // draw curves
/*    CGContextSetStrokeColorWithColor(ctx, [[UIColor redColor] CGColor]);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddArc(path, NULL, 100, 100, 25, 0, 2 * PI, YES);
    CGPathAddArc(path, NULL, 200, 200, 50, 0, 0.8 * PI, NO);
    CGPathAddArc(path, NULL, 300, 300, 50, 1.7 * PI, 1 * PI, NO);

    CGPathMoveToPoint(path, NULL, 300, 100);
    CGPathAddCurveToPoint(path, NULL, 300, 150, 350, 100, 350, 150);
    CGPathAddCurveToPoint(path, NULL, 400, 200, 400, 200, 450, 150);

    CGContextAddPath(ctx, (CGPathRef)path);
    CGContextStrokePath(ctx);

    // Draw the curved rectangle 
    CGContextSaveGState(ctx);
    CGRect aRect = CGRectMake(150, 10, 250, 100);
    CGFloat radius = 10;
    CGFloat buffer = floorf(CGRectGetMaxY(aRect) * 0);
    CGFloat aMaxX = floorf(CGRectGetMaxX(aRect) - buffer);
    CGFloat aMaxY = floorf(CGRectGetMaxY(aRect) - buffer);
    CGFloat aMinX = floorf(CGRectGetMinX(aRect) + buffer);
    CGFloat aMinY = floorf(CGRectGetMinY(aRect) + buffer);

    CGContextBeginPath(ctx);
    CGContextSetLineWidth(ctx,3);
    CGContextSetRGBFillColor(ctx, 0.5, 1.0, 0.0, 1.0);
    //CGContextSetStrokeColorWithColor(ctx, [[UIColor blueColor] CGColor]);
    CGContextAddArc(ctx, aMaxX - radius, aMinY + radius, radius, PI*1.5, 0 , NO);
    CGContextAddArc(ctx, aMaxX - radius, aMaxY - radius, radius, 0, PI/2 , NO);
    CGContextAddArc(ctx, aMinX + radius, aMaxY - radius, radius, PI/2, PI, NO);
    CGContextAddArc(ctx, aMinX + radius, aMinY + radius, radius, PI, PI*1.5, NO);
    CGContextClosePath(ctx);
    //CGContextStrokePath(ctx);
    CGContextFillPath(ctx);

    CGContextRestoreGState(ctx);
*/
}

@end

