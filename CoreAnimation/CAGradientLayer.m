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

#import <CoreAnimation/CoreAnimation-private.h>

@implementation CAGradientLayer

@synthesize colors;
@synthesize locations;
@synthesize startPoint;
@synthesize endPoint;
@synthesize type;

#pragma mark - Life cycle

- (void)dealloc
{
    [colors release];
    [locations release];
    [type release];
    [super dealloc];
}

#pragma mark - Overridden methods

- (void)drawInContext:(CGContextRef)ctx
{
    CGContextSaveGState(ctx);
    
    CGRect aRect = self->_bounds;
    // Clipping the view for the gradient
    CGFloat myRadius = self->_cornerRadius;
    CGContextBeginPath(ctx);
    CGContextAddArc(ctx, aRect.size.width - myRadius, myRadius, myRadius, PI*1.5, 0 , NO);
    CGContextAddArc(ctx, aRect.size.width - myRadius, aRect.size.height - myRadius, myRadius, 0, PI/2 , NO);
    CGContextAddArc(ctx, myRadius, aRect.size.height - myRadius, myRadius, PI/2, PI, NO);
    CGContextAddArc(ctx, myRadius, myRadius, myRadius, PI, PI*1.5, NO);
    CGContextClip(ctx);
    
    // Drawing the gradient
    size_t numberOfLocations = [self->colors count];
    CGFloat *gLocations = (CGFloat *)malloc(numberOfLocations * sizeof(CGFloat));
    CGFloat *components = (CGFloat *)malloc(4 * numberOfLocations * sizeof(CGFloat));
    for (int i=0; i<numberOfLocations; i++) {
        gLocations[i] = 1.0/(numberOfLocations-1)*i;
        CGColor *aColor = [self->colors objectAtIndex:i];
        const CGFloat *aColorComponents = CGColorGetComponents(aColor);
        components[i*4] = aColorComponents[0];
        components[i*4+1] = aColorComponents[1];
        components[i*4+2] = aColorComponents[2];
        components[i*4+3] = aColorComponents[3];
    }
    CGColorSpaceRef myColorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef myGradient = CGGradientCreateWithColorComponents(myColorSpace, components, gLocations, numberOfLocations);
    CGPoint myStartPoint, myEndPoint;
    myStartPoint.x = 0.0;
    myStartPoint.y = 0.0;
    myEndPoint.x = 0.0;
    myEndPoint.y = aRect.size.height;
    CGContextDrawLinearGradient(ctx, myGradient, myStartPoint, myEndPoint, 0);
    free(gLocations);
    free(components);
    CGColorSpaceRelease(myColorSpace);
    CGGradientRelease(myGradient);
    CGContextRestoreGState(ctx);
    
    [super drawInContext:ctx];
}

@end
