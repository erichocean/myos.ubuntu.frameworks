/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import <CoreGraphics/CoreGraphics.h>

@interface Layers : NSObject
{
    CGContextRef context;
    CGRect border;
}

@property (nonatomic, retain) CGContextRef context;
@property (nonatomic) CGRect border;

- (id)initWithContext:(CGContextRef)aContext andBorder:(CGRect)aBorder;
- (void)fillBorder;
- (void)draw;

@end

