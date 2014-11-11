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

 #import "CABase.h"

extern NSString *const kCAValueFunctionTranslate;
extern NSString *const kCAValueFunctionTranslateX;
extern NSString *const kCAValueFunctionTranslateY;
extern NSString *const kCAValueFunctionTranslateZ;

extern NSString *const kCAValueFunctionScale;
extern NSString *const kCAValueFunctionScaleX;
extern NSString *const kCAValueFunctionScaleY;
extern NSString *const kCAValueFunctionScaleZ;

extern NSString *const kCAValueFunctionRotate;
extern NSString *const kCAValueFunctionRotateX;
extern NSString *const kCAValueFunctionRotateY;
extern NSString *const kCAValueFunctionRotateZ;

@interface CAValueFunction : NSObject <NSCoding> {
    NSString *name;
    void * _impl;
    unsigned long inputCount;
    unsigned long outputCount;
}

@property(readonly) NSString *name;

+ (id)functionWithName:(id)name;

@end
