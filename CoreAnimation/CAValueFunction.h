/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
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

@interface CAValueFunction : NSObject <NSCoding>
{
    NSString *name;
    void * _impl;
    unsigned long inputCount;
    unsigned long outputCount;
}

@property(readonly) NSString *name;

+ (id)functionWithName:(id)name;

@end
