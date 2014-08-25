/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <Foundation/NSObject.h> 

extern NSString *const kCAMediaTimingFunctionLinear;
extern NSString *const kCAMediaTimingFunctionEaseIn;
extern NSString *const kCAMediaTimingFunctionEaseOut;
extern NSString *const kCAMediaTimingFunctionEaseInEaseOut;
extern NSString *const kCAMediaTimingFunctionDefault;

@interface CAMediaTimingFunction : NSObject
{
@package
    float _c1x;
    float _c1y;
    float _c2x;
    float _c2y;

    float _b;
    float _c;
    float _d;
}

+ (id)functionWithName:(NSString *)name;
+ (id)functionWithControlPoints:(float)c1x :(float)c1y :(float)c2x :(float)c2y;
- (id)initWithControlPoints:(float)c1x :(float)c1y :(float)c2x :(float)c2y;
- (void)getControlPointAtIndex:(size_t)idx values:(float[2])ptr;

@end
