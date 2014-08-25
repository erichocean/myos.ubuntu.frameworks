/*
 * Copyright (c) 2012. All rights reserved.
 *
 */

#import "ColorSpaceView.h"

@implementation ColorSpaceView

#pragma mark - Life cycle

- (id)initWithFrame:(CGRect)theFrame
{
    self = [super initWithFrame:theFrame];
    if (self) {
        //self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:0.5];
        self.backgroundColor = [UIColor greenColor];
    }
    return self;
}

#pragma mark - Overridden methods

- (void)drawRect:(CGRect)rect
{
    //DLog(@"rect: %@", NSStringFromCGRect(rect));
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGContextScaleCTM(ctx, rect.size.width, rect.size.height);

    CGColorSpaceRef AdobeRGB, sRGB;

    AdobeRGB = CGColorSpaceCreateWithName(kCGColorSpaceAdobeRGB1998);
    sRGB = CGColorSpaceCreateDeviceRGB(); //CGColorSpaceCreateWithName(kCGColorSpaceSRGB); 

    const CGFloat full[4] = {0.0, 1.0, 0.0, 1.0};
    const CGFloat partial[4] = {0.0, 0.75, 0.0, 1.0};

    CGColorRef adobe1, adobe2, srgb1, srgb2;
    adobe1 = CGColorCreate(AdobeRGB, full);
    adobe2 = CGColorCreate(AdobeRGB, partial);
    srgb1 = CGColorCreate(sRGB, full);
    srgb2 = CGColorCreate(sRGB, partial);

    /* AdobeRGB 100% green | sRGB 100% green
       --------------------+----------------
       AdobeRGB 75% green  | sRGB 75% green  */

    CGContextSetFillColorWithColor(ctx, adobe1);
    CGContextFillRect(ctx, CGRectMake(0, 0.5, 0.5, 0.5));
    CGContextSetFillColorWithColor(ctx, srgb1);
    CGContextFillRect(ctx, CGRectMake(0.5, 0.5, 0.5, 0.5));

    CGContextSetFillColorWithColor(ctx, adobe2);
    CGContextFillRect(ctx, CGRectMake(0, 0, 0.5, 0.5));
    CGContextSetFillColorWithColor(ctx, srgb2);
    CGContextFillRect(ctx, CGRectMake(0.5, 0, 0.5, 0.5));

}

@end

