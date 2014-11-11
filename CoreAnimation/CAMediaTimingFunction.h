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

#import <Foundation/NSObject.h> 

extern NSString *const kCAMediaTimingFunctionLinear;
extern NSString *const kCAMediaTimingFunctionEaseIn;
extern NSString *const kCAMediaTimingFunctionEaseOut;
extern NSString *const kCAMediaTimingFunctionEaseInEaseOut;
extern NSString *const kCAMediaTimingFunctionDefault;

@interface CAMediaTimingFunction : NSObject {
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
