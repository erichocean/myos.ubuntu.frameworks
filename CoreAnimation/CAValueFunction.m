/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <CoreAnimation/CAValueFunction.h>

NSString *const kCAValueFunctionTranslate = @"CAValueFunctionTranslate";
NSString *const kCAValueFunctionTranslateX = @"CAValueFunctionTranslateX";
NSString *const kCAValueFunctionTranslateY = @"CAValueFunctionTranslateY";
NSString *const kCAValueFunctionTranslateZ = @"CAValueFunctionTranslateZ";

NSString *const kCAValueFunctionScale = @"CAValueFunctionScale";
NSString *const kCAValueFunctionScaleX = @"CAValueFunctionScaleX";
NSString *const kCAValueFunctionScaleY = @"CAValueFunctionScaleY";
NSString *const kCAValueFunctionScaleZ = @"CAValueFunctionScaleZ";

NSString *const kCAValueFunctionRotate = @"CAValueFunctionRotate";
NSString *const kCAValueFunctionRotateX = @"CAValueFunctionRotateX";
NSString *const kCAValueFunctionRotateY = @"CAValueFunctionRotateY";
NSString *const kCAValueFunctionRotateZ = @"CAValueFunctionRotateZ";

@interface CAValueFunction ()

- (unsigned long)inputCount;
- (BOOL)apply:(const double*)value result:(double *)result;
- (unsigned long)outputCount;
- (BOOL)apply:(const double*)value result:(double *)result parameterFunction:(int (*)())func context:(void *)context;
- (void)encodeWithCoder:(id)coder;
- (id)initWithCoder:(id)coder;
- (struct Object {int (**X1)(); struct Atomic {struct {int x_1_2_1;} x_2_1_1;} X2;}*)CA_copyRenderValue;

@end

@implementation CAValueFunction

@synthesize name;

#pragma mark - Life cycle

- (id)initWithName:(NSString *)aName inputCount:(unsigned long)_inputCount outputCount:(unsigned long)_outputCount
{
    self = [self init];
    if (self) {
        name = [aName copy];
        inputCount = _inputCount;
        outputCount = _outputCount;
    }
    return self;
}

+ (id)functionWithName:(id)aName
{
    return [[[self alloc] initWithName:aName] autorelease];
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{

}

- (id) initWithCoder: (NSCoder*)aDecoder
{
	return nil;
}

- (unsigned long)inputCount
{
	return inputCount;
}

- (BOOL)apply:(const double*)value result:(double *)result
{
	return false;
}

- (unsigned long)outputCount
{
	return outputCount;
}

- (BOOL)apply:(const double*)value result:(double *)result parameterFunction:(int (*)())func context:(void *)context
{
	return false;
}

- (void)dealloc
{
    [name release];
    [super dealloc];
}

@end
