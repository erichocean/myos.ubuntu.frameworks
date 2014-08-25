#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

#import "Layers.h"

CGLayerRef makeSampleLayer(CGContextRef context);

@interface Layers()
- (CGLayerRef)makeSampleLayer:(CGContextRef)context;
@end

@implementation Layers

@synthesize context;
@synthesize border;

- (id)initWithContext:(CGContextRef)aContext andBorder:(CGRect)aBorder
{
    self = [super init];
    if (self) {
        self.context = aContext;
        self.border = aBorder;
    }
    return self;
}

- (void)fillBorder
{
    CGContextSaveGState(context);

    CGContextScaleCTM(context, border.size.width, border.size.height);
    CGContextSetRGBFillColor(context, 0, 0, 1, 0.5);
    CGContextSetRGBStrokeColor(context, 0, 0, 0, 1);
    CGRect rect = CGRectMake(0.05,0.05,0.9,0.9);// CGRectMake(10, 10, border.size.width - 20, border.size.height - 20));
    CGRect rect2 = CGRectMake(0.05,0.05,0.9,0.9);// CGRectMake(10, 10, border.size.width - 20, border.size.height - 20));
    CGContextFillRect(context, rect);
    CGContextSetLineWidth(context, 0.003);
    CGContextStrokeRect(context, rect); 
    CGContextRestoreGState(context);
}

- (void)draw //(CGContextRef context, CGRect border)
{
  CGContextScaleCTM(context, border.size.width, border.size.height);

  CGColorSpaceRef AdobeRGB, sRGB;

  AdobeRGB = CGColorSpaceCreateWithName(kCGColorSpaceAdobeRGB1998);
  sRGB = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);

  const CGFloat full[4] = {0.0, 0.0, 1.0, 1.0};
  const CGFloat partial[4] = {0.0, 0.0, 0.75, 1.0};

  CGColorRef adobe1, adobe2, srgb1, srgb2;
  adobe1 = CGColorCreate(AdobeRGB, full);
  adobe2 = CGColorCreate(AdobeRGB, partial);
  srgb1 = CGColorCreate(sRGB, full);
  srgb2 = CGColorCreate(sRGB, partial);

  /* AdobeRGB 100% green | sRGB 100% green
     --------------------+----------------
     AdobeRGB 75% green  | sRGB 75% green  */

  CGContextSetFillColorWithColor(context, adobe1);
  CGContextFillRect(context, CGRectMake(0, 0.5, 0.5, 0.5));
//  CGContextSetFillColorWithColor(context, srgb1);
//  CGContextFillRect(context, CGRectMake(0.5, 0.5, 0.5, 0.5));

  CGContextSetFillColorWithColor(context, adobe2);
  CGContextFillRect(context, CGRectMake(0, 0, 0.5, 0.5));
//  CGContextSetFillColorWithColor(context, srgb2);
//  CGContextFillRect(context, CGRectMake(0.5, 0, 0.5, 0.5));
}
 
- (void)draw2
{
    // Draw some copies of a layer
    CGLayerRef layer = [self makeSampleLayer:context];
    
////    DLog(@"layer: %@", layer);    
    // Draw some rotated faces
/*    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 225, 200);
    DLog(@"");    
    CGContextDrawLayerInRect(context, CGRectMake(-145,-110,290,220), layer);
    CGContextRestoreGState(context);
*/
////    CGContextDrawLayerInRect(context, CGRectMake(180,115,290,220), layer);
    
//    CGContextDrawLayerAtPoint(context, CGPointMake(100, 170), layer);
////    CGContextDrawLayerAtPoint(context, CGPointMake(300, 170), layer);

//    CGContextDrawLayerAtPoint(context, CGPointMake(100, 60), layer);
//    CGContextDrawLayerAtPoint(context, CGPointMake(150, 16), layer);
//    CGContextDrawLayerAtPoint(context, CGPointMake(200, 10), layer);
//    CGContextDrawLayerAtPoint(context, CGPointMake(250, 16), layer);
//    CGContextDrawLayerAtPoint(context, CGPointMake(300, 60), layer);
////    DLog(@"");    
    CGLayerRelease(layer); 
}

- (CGLayerRef)makeSampleLayer:(CGContextRef)aContext
{
    CGRect layerBounds = CGRectMake(0,0,50, 50);
    CGLayerRef layer = CGLayerCreateWithContext(aContext, layerBounds.size, NULL);
    CGContextRef layerCtx = CGLayerGetContext(layer);
/*
    CGContextSetRGBFillColor(layerCtx, 1, 1, 0, 0.5);
    CGContextFillRect(layerCtx, layerBounds);
    
    CGContextSetRGBStrokeColor(layerCtx, 0, 0, 0, 0.7);
    CGContextStrokeRect(layerCtx, layerBounds);
*/
    // Draw a smiley
    DLog(@"Draw a smiley");
    CGContextBeginPath(layerCtx);
    DLog("CGContextIsPathEmpty: %d", CGContextIsPathEmpty(layerCtx));
    CGContextMoveToPoint(layerCtx, 14, 35); CGContextAddArc(layerCtx, 10, 35, 4, 0, 2 * PI, 0); CGContextClosePath(layerCtx);
    CGContextMoveToPoint(layerCtx, 44, 35); CGContextAddArc(layerCtx, 40, 35, 4, 0, 2 * PI, 0); CGContextClosePath(layerCtx);
    CGContextMoveToPoint(layerCtx, 16, 15); CGContextAddArc(layerCtx, 12, 15, 4, 0, 2 * PI, 0); CGContextClosePath(layerCtx);
    CGContextMoveToPoint(layerCtx, 23, 10); CGContextAddArc(layerCtx, 19, 10, 4, 0, 2 * PI, 0); CGContextClosePath(layerCtx);
    CGContextMoveToPoint(layerCtx, 29, 8);  CGContextAddArc(layerCtx, 25, 8, 4, 0, 2 * PI, 0);  CGContextClosePath(layerCtx);
/*    CGContextMoveToPoint(layerCtx, 35, 10); CGContextAddArc(layerCtx, 31, 10, 4, 0, 2 * PI, 0); CGContextClosePath(layerCtx);
    CGContextMoveToPoint(layerCtx, 42, 15); CGContextAddArc(layerCtx, 38, 15, 4, 0, 2 * PI, 0); CGContextClosePath(layerCtx);
*/
    DLog(@"");
//    CGContextSetRGBFillColor(layerCtx, 1, 0, 0, 0.5);
//    CGContextSetRGBStrokeColor(layerCtx, 0, 0, 0, 1);
    CGContextDrawPath(layerCtx, kCGPathFillStroke);
  
    return layer;
}

@end

