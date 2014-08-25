/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import "ImagesView.h"

@implementation ImagesView

#pragma mark - Life cycle

- (id)initWithFrame:(CGRect)theFrame
{
    self = [super initWithFrame:theFrame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.4 green:0.6 blue:1.0 alpha:0.5];
        //self.backgroundColor = [UIColor blueColor];
        //self.backgroundColor = [UIColor colorWithRed:0.4 green:0.6 blue:1.0 alpha:0.5];//yellowColor];
    }
        return self;
}

#pragma mark - Overridden methods

#define pi 3.14159265358979323846

static CGImageRef png, jpeg, tiff;

- (void)drawRect:(CGRect)rect
{
    DLog(@"rect: %@", NSStringFromCGRect(rect));
    CGContextRef ctx = UIGraphicsGetCurrentContext();
//    CGContextScaleCTM(ctx, 2, 2);

    //CGContextSetRGBFillColor(ctx, 0.4, 0.6, 1.0, 0.7);
    //CGContextFillRect(ctx, rect);

    // Draw a checkerboard
 /*   CGContextSetRGBFillColor(ctx, 0.4, 0.4, 0.4, 1.0);
    unsigned int x, y;
    for (x=0; x<rect.size.width; x+=10) {
        for (y=0; y<rect.size.height; y+=10) {
            if (((x % 20) == 0) != ((y % 20) == 0)) {
                CGContextFillRect(ctx,  CGRectMake(x, y, 10, 10));
            }
        }
    }*/
    //if (nil == png) {
    CGDataProviderRef pngData = CGDataProviderCreateWithFilename("sunglass.png");
    DLog(@"pngData: %@", pngData);
    png = CGImageCreateWithPNGDataProvider(pngData, NULL, YES, kCGRenderingIntentDefault);
    //DLog(@"png: %@", png);
    CGDataProviderRelease(pngData);
    //}
    DLog(@"png: %@", png);
    float width = 256;
    float height = 256;
    float xPosition = (rect.size.width - width)/2;
    float yPosition = (rect.size.height - height)/2;
    CGRect pngRect = CGRectMake(150,150,130,130);//rect.size.width,rect.size.height);
    CGContextSaveGState(ctx);
    //CGContextConcatCTM(ctx, CGContextGetUserSpaceToDeviceSpaceTransform(ctx));
    CGContextTranslateCTM(ctx, 0, 300);
    CGContextScaleCTM(ctx, 1, -1.0);
    CGContextDrawImage(ctx, pngRect, png);
//    CGContextRestoreGState(ctx);

    pngData = CGDataProviderCreateWithFilename("eartharrow.png");
    png = CGImageCreateWithPNGDataProvider(pngData, NULL, YES, kCGRenderingIntentDefault);
    CGDataProviderRelease(pngData);
    pngRect = CGRectMake(10,0,250,250);
    CGContextDrawImage(ctx, pngRect, png);

    pngData = CGDataProviderCreateWithFilename("cuckoo.png");
    png = CGImageCreateWithPNGDataProvider(pngData, NULL, YES, kCGRenderingIntentDefault);
    CGDataProviderRelease(pngData);
    pngRect = CGRectMake(70,70,100,100);
    CGContextDrawImage(ctx, pngRect, png);
 
    CGContextRestoreGState(ctx);

 
    return;
    if (nil == jpeg) {
        CGDataProviderRef jpegData = CGDataProviderCreateWithFilename("test.jpg");
        DLog(@"jpegData: %@", jpegData);
        jpeg = CGImageCreateWithJPEGDataProvider(jpegData, NULL, YES, kCGRenderingIntentDefault);
        DLog(@"jpeg: %@", jpeg);
        CGDataProviderRelease(jpegData);
    }
    DLog(@"jpeg: %@", jpeg);
    CGRect jpegRect = CGRectMake(rect.size.width/3,0,rect.size.width/3, rect.size.height);
    CGContextDrawImage(ctx, jpegRect, jpeg);
    return;

    if (nil == tiff) {
        CGDataProviderRef tiffData = CGDataProviderCreateWithFilename("test.tiff");
        CGImageSourceRef tiffSource = CGImageSourceCreateWithDataProvider(tiffData, nil);
        tiff = CGImageSourceCreateImageAtIndex(tiffSource, 0, nil);
        CGDataProviderRelease(tiffData);
        [tiffSource release];
    }
    CGRect tiffRect = CGRectMake((2*rect.size.width)/3,0,rect.size.width/3, rect.size.height);
    CGContextDrawImage(ctx, tiffRect, tiff);

/*
        CGContextScaleCTM(ctx, rect.size.width, rect.size.height);

        CGGradientRef myGradient;
        CGColorSpaceRef myColorspace;
        size_t num_locations = 2;
        CGFloat locations[2] = { 0.0, 1.0 };
        CGFloat components[8] = { 0.2, 0.5, 0.9, 1.0,  // Start color
                              0.2, 0.5, 0.2, 1.0 }; // End color

        myColorspace = CGColorSpaceCreateDeviceRGB();
        myGradient = CGGradientCreateWithColorComponents (myColorspace, components, locations, num_locations);

        CGPoint myStartPoint, myEndPoint;
        myStartPoint.x = 0.3;
        myStartPoint.y = 0.0;
        myEndPoint.x = 0.7;
        myEndPoint.y = 1.0;
        CGContextDrawLinearGradient(ctx, myGradient, myStartPoint, myEndPoint, 0);
*/
}

@end

