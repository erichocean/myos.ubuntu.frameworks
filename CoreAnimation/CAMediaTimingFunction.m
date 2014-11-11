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

NSString *const kCAMediaTimingFunctionLinear = @"CAMediaTimingFunctionLinear";
NSString *const kCAMediaTimingFunctionEaseIn = @"CAMediaTimingFunctionEaseIn";
NSString *const kCAMediaTimingFunctionEaseOut = @"CAMediaTimingFunctionEaseOut";
NSString *const kCAMediaTimingFunctionEaseInEaseOut = @"CAMediaTimingFunctionEaseInEaseOut";
NSString *const kCAMediaTimingFunctionDefault = @"CAMediaTimingFunctionDefault";

static CAMediaTimingFunction *_defaultMediaTimingFunction = nil;

#define _kCAMTFSmallValue   0.001

#pragma mark - Static functions

static float _CAMTFSolveCubicPolynomialBetweenValues(float t0, float t1, float x, float b, float c, float d)
{
    float tm; 
    float xm = -x;
    int count=0;
    while (t1-t0 > _kCAMTFSmallValue) {
        tm = (t1 + t0) / 2.0;
        count++;
        float ts = tm*tm;
        float wm = xm + b*tm + c*ts + d*ts*tm;
        ts = t0*t0;
        float w0 = xm + b*t0 + c*ts + d*ts*t0;
        if (w0 * wm <= 0) {
            t1=tm;
        } else {
            t0=tm;
        }
    }
    return tm;
}

@implementation CAMediaTimingFunction

#pragma mark - Life cycle

+ (void)initialize
{
    if (self == [CAMediaTimingFunction class]) {
        _defaultMediaTimingFunction = [[self alloc] initWithControlPoints:0.25:0.1:0.25:1];
    }
}

+ (id)functionWithName:(NSString *const)name
{
    if (name == kCAMediaTimingFunctionDefault) {
        return _defaultMediaTimingFunction;
    } else if (name == kCAMediaTimingFunctionLinear) {
        return [[[self alloc] initWithControlPoints:0:0:1:1] autorelease];
    } else if (name == kCAMediaTimingFunctionEaseIn) {
        return [[[self alloc] initWithControlPoints:0.5:0:1:1] autorelease];
    } else if (name == kCAMediaTimingFunctionEaseOut) {
        return [[[self alloc] initWithControlPoints:0:0:0.5:1] autorelease];
    } else if (name == kCAMediaTimingFunctionEaseInEaseOut) {
        return [[[self alloc] initWithControlPoints:0.5:0:0.5:1] autorelease];
    } else {
        return nil;
    }
}

+ (id)functionWithControlPoints:(float)c1x :(float)c1y :(float)c2x :(float)c2y
{
    return [[[self alloc] initWithControlPoints:c1x:c1y:c2x:c2y] autorelease];
}

- (id)initWithControlPoints:(float)c1x :(float)c1y :(float)c2x :(float)c2y
{
    self = [super init];
    if (self) {
        _c1x = c1x;
        _c1y = c1y;
        _c2x = c2x;
        _c2y = c2y;
        
        _b = 3*c1x;
        _c = 3*c2x-6*c1x;
        _d = 1+3*c1x-3*c2x;
        //DLog(@"_b: %0.2f, _c:%0.2f, _d:%0.2f", _b, _c, _d);
    }
    return self;
}

#pragma mark - Accessors

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; _c1x:%0.2f; _c1y:%0.2f; _c2x:%0.2f; _c2y:%0.2f>", [self className], self, _c1x, _c1y, _c2x, _c2y];
}

#pragma mark - Public methods

- (void)getControlPointAtIndex:(size_t)idx values:(float[2])ptr
{
    //_CAMediaTimingFunctionGetControlPointAtIndex(self, idx, ptr);
    switch (idx) {
        case 0:
            ptr[0]=0;
            ptr[1]=0;
            break;
        case 1:
            ptr[0]=_c1x;
            ptr[1]=_c1y;
            break;
        case 2:
            ptr[0]=_c2x;
            ptr[1]=_c2y;
            break;
        case 3:
            ptr[0]=1;
            ptr[1]=1;
            break;
        default:
            break;
    }
}

@end

float _CAMediaTimingFunctionApply(CAMediaTimingFunction *func, float x)
{
//    return x;
    
    //double x=cubed(1.0-t)*0.0+3*squared(1-t)*t*cp1[0]+3*(1-t)*squared(t)*cp2[0]+cubed(t)*1.0;
    //double y=cubed(1.0-t)*0.0+3*squared(1-t)*t*cp1[1]+3*(1-t)*squared(t)*cp2[1]+cubed(t)*1.0;
    
    float t = _CAMTFSolveCubicPolynomialBetweenValues(0, 1.0, x, func->_b, func->_c, func->_d);
    //DLog(@"x: %0.1f", x);   
    //DLog(@"t: %0.2f", t);
    float tr = 1-t;
    float t3 = 3*tr;
    float ts = t*t;
    float y = t3*tr*t*func->_c1y + t3*ts*func->_c2y + ts*t;
    //DLog(@"y: %0.1f", y);
    return y;
}

