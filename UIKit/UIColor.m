/*
 * Copyright (c) 2011, The Iconfactory. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of The Iconfactory nor the names of its contributors may
 *    be used to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE ICONFACTORY BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <UIKit/UIColor.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIGraphics.h>
//#import <CoreImage/CoreImage.h>

// callback for CreateImagePattern.
static void drawPatternImage(void *info, CGContextRef ctx)
{
    CGImageRef image = (CGImageRef)info;
    CGContextDrawImage(ctx, CGRectMake(0,0, CGImageGetWidth(image),CGImageGetHeight(image)), image);
}

// callback for CreateImagePattern.
static void releasePatternImage(void *info)
{
    CGImageRelease((CGImageRef)info);
}

static CGPatternRef CreateImagePattern(CGImageRef image)
{
    NSCParameterAssert(image);
    CGImageRetain(image);
    int width = CGImageGetWidth(image);
    int height = CGImageGetHeight(image);
    static const CGPatternCallbacks callbacks = {0, &drawPatternImage, &releasePatternImage};
    return CGPatternCreate (image,
                            CGRectMake (0, 0, width, height),
                            CGAffineTransformMake (1, 0, 0, -1, 0, height),
                            width,
                            height,
                            kCGPatternTilingConstantSpacing,
                            true,
                            &callbacks);
}

static CGColorRef CreatePatternColor(CGImageRef image)
{
    CGPatternRef pattern = CreateImagePattern(image);
    CGColorSpaceRef space = CGColorSpaceCreatePattern(NULL);
    CGFloat components[1] = {1.0};
    CGColorRef color = CGColorCreateWithPattern(space, pattern, components);
    CGColorSpaceRelease(space);
    CGPatternRelease(pattern);
    return color;
}

static UIColor *BlackColor = nil;
static UIColor *DarkGrayColor = nil;
static UIColor *LightGrayColor = nil;
static UIColor *WhiteColor = nil;
static UIColor *GrayColor = nil;
static UIColor *RedColor = nil;
static UIColor *GreenColor = nil;
static UIColor *BlueColor = nil;
static UIColor *CyanColor = nil;
static UIColor *YellowColor = nil;
static UIColor *MagentaColor = nil;
static UIColor *OrangeColor = nil;
static UIColor *PurpleColor = nil;
static UIColor *BrownColor = nil;
static UIColor *ClearColor = nil;

@implementation UIColor

#pragma mark - Life cycle

- (id)initWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha
{
    self = [super init];
    if (self) {
        _color = CGColorCreateGenericRGB(red, green, blue, alpha);
    }
    return self;
}

- (id)initWithWhite:(CGFloat)white alpha:(CGFloat)alpha
{
    return [self initWithRed:white green:white blue:white alpha:alpha];
}

- (id)initWithHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness alpha:(CGFloat)alpha
{
    int I = (int)(hue * 6);
    double V = brightness;
    double S = saturation;
    double F = (hue * 6) - I;
    double M = V * (1 - S);
    double N = V * (1 - S * F);
    double K = M - N + V;
    double R, G, B;
    switch (I) {
        case 1: R = N; G = V; B = M; break;
        case 2: R = M; G = V; B = K; break;
        case 3: R = M; G = N; B = V; break;
        case 4: R = K; G = M; B = V; break;
        case 5: R = V; G = M; B = N; break;
        default: R = V; G = K; B = M; break;
    }
    CGFloat _red_component = (CGFloat)R;
    CGFloat _green_component = (CGFloat)G;
    CGFloat _blue_component = (CGFloat)B;
    return [self initWithRed:_red_component green:_green_component blue:_blue_component alpha:alpha];
}

- (id)initWithCGColor:(CGColorRef)ref
{
    self = [super init];
    if (self) {
        _color = CGColorRetain(ref);
    }
    return self;
}

- (id)initWithPatternImage:(UIImage *)patternImage
{
    if (!patternImage) {
        [self release];
        self = nil;
    }
    else {
        self = [super init];
    }
    if (self) {
        _color = CreatePatternColor(patternImage.CGImage);
    }
    return self;
}

- (void)dealloc
{
    CGColorRelease(_color);
    [super dealloc];
}

#pragma mark - Class methods

+ (UIColor *)colorWithWhite:(CGFloat)white alpha:(CGFloat)alpha
{
    return [[[self alloc] initWithWhite:white alpha:alpha] autorelease];
}

+ (UIColor *)colorWithHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness alpha:(CGFloat)alpha
{
    return [[[self alloc] initWithHue:hue saturation:saturation brightness:brightness alpha:alpha] autorelease];
}

+ (UIColor *)colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha
{
    return [[[self alloc] initWithRed:red green:green blue:blue alpha:alpha] autorelease];
}

+ (UIColor *)colorWithCGColor:(CGColorRef)ref
{
    return [[[self alloc] initWithCGColor:ref] autorelease];
}

+ (UIColor *)colorWithPatternImage:(UIImage *)patternImage
{
    return [[[self alloc] initWithPatternImage:patternImage] autorelease];
}

+ (UIColor *)blackColor	
{
    return BlackColor ?: (BlackColor = [[self alloc] initWithRed:0.0 green:0.0 blue:0.0 alpha:1.0]);
}

+ (UIColor *)darkGrayColor 
{
    return DarkGrayColor ?: (DarkGrayColor = [[self alloc] initWithRed:0.33 green:0.33 blue:0.33 alpha:1.0]);
}

+ (UIColor *)lightGrayColor 
{
    return LightGrayColor ?: (LightGrayColor = [[self alloc] initWithRed:0.667 green:0.667 blue:0.667 alpha:1.0]);
}

+ (UIColor *)whiteColor	
{
    return WhiteColor ?: (WhiteColor = [[self alloc] initWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]);
}

+ (UIColor *)grayColor
{
    return GrayColor ?: (GrayColor = [[self alloc] initWithRed:0.5 green:0.5 blue:0.5 alpha:1.0]);
}

+ (UIColor *)redColor
{
    return RedColor ?: (RedColor = [[self alloc] initWithRed:1.0 green:0.0 blue:0.0 alpha:1.0]);
}

+ (UIColor *)greenColor
{
    return GreenColor ?: (GreenColor = [[self alloc] initWithRed:0.0 green:1.0 blue:0.0 alpha:1.0]);
}

+ (UIColor *)blueColor
{
    return BlueColor ?: (BlueColor = [[self alloc] initWithRed:0.0 green:0.0 blue:1.0 alpha:1.0]);
}

+ (UIColor *)cyanColor
{
    return CyanColor ?: (CyanColor = [[self alloc] initWithRed:0.0 green:1.0 blue:1.0 alpha:1.0]);
}

+ (UIColor *)yellowColor
{
    return YellowColor ?: (YellowColor = [[self alloc] initWithRed:1.0 green:1.0 blue:0.0 alpha:1.0]);
}

+ (UIColor *)magentaColor
{
    return MagentaColor ?: (MagentaColor = [[self alloc] initWithRed:1.0 green:0.0 blue:1.0 alpha:1.0]);
}

+ (UIColor *)orangeColor
{
    return OrangeColor ?: (OrangeColor = [[self alloc] initWithRed:1.0 green:0.5 blue:0.0 alpha:1.0]);
}

+ (UIColor *)purpleColor
{
    return PurpleColor ?: (PurpleColor = [[self alloc] initWithRed:0.5 green:0.0 blue:0.5 alpha:1.0]);
}

+ (UIColor *)brownColor
{
    return BrownColor ?: (BrownColor = [[self alloc] initWithRed:0.6 green:0.4 blue:0.2 alpha:1.0]);
}

+ (UIColor *)clearColor
{
    return ClearColor ?: (ClearColor = [[self alloc] initWithRed:0.0 green:0.0 blue:0.0 alpha:0.0]);
}

#pragma mark - Accessors

- (void)set
{
    [self setFill];
    [self setStroke];
}

- (void)setFill
{
    //DLog(@"self: %@", self);
    //DLog(@"_color: %@", _color);
    CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), _color);
    //DLog();
}

- (void)setStroke
{
    CGContextSetStrokeColorWithColor(UIGraphicsGetCurrentContext(), _color);
}

- (CGColorRef)CGColor
{
    return _color;
}

- (UIColor *)colorWithAlphaComponent:(CGFloat)alpha
{
    //DLog();
    CGColorRef newColor = CGColorCreateCopyWithAlpha(_color, alpha);
    UIColor *resultingUIColor = [UIColor colorWithCGColor:newColor];
    //DLog(@"newColor: %@", newColor);
    CGColorRelease(newColor);
    //DLog(@"resultingUIColor: %@", resultingUIColor);
    return resultingUIColor;
}

- (NSString *)description
{
    // The color space string this gets isn't exactly the same as Apple's implementation.
    // For instance, Apple's implementation returns UIDeviceRGBColorSpace for [UIColor redColor]
    // This implementation returns kCGColorSpaceDeviceRGB instead.
    // Apple doesn't actually define UIDeviceRGBColorSpace or any of the other responses anywhere public,
    // so there isn't any easy way to emulate it.
    /*CGColorSpaceRef colorSpaceRef = CGColorGetColorSpace(self.CGColor);
    NSString *colorSpace = [NSString stringWithFormat:@"%@", [(NSString *)CGColorSpaceCopyName(colorSpaceRef) autorelease]];

    const size_t numberOfComponents = CGColorGetNumberOfComponents(self.CGColor);
    //DLog(@"numberOfComponents: %d", numberOfComponents);*/
    const CGFloat *components = CGColorGetComponents(self.CGColor);
    NSMutableString *componentsString = [NSMutableString stringWithString:@"{"];
    for (NSInteger index = 0; index < 4; index++) {
        if (index) {
            [componentsString appendString:@", "];
        }
        [componentsString appendFormat:@"%.2f", components[index]];
    }
    [componentsString appendString:@"}"];
    return [NSString stringWithFormat:@"<%@: %p; components = %@>", [self className], self, componentsString];
}

@end
