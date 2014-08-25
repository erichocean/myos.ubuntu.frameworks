/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import "CAMediaTiming.h"

NSString *const kCAFillModeForwards = @"CAFillModeForwards";
NSString *const kCAFillModeBackwards = @"CAFillModeBackwards";
NSString *const kCAFillModeBoth = @"CAFillModeBoth";
NSString *const kCAFillModeRemoved = @"CAFillModeRemoved";
NSString *const kCAFillModeFrozen = @"CAFillModeFrozen";

CFTimeInterval CACurrentMediaTime() 
{
    return (CFTimeInterval)[NSDate timeIntervalSinceReferenceDate];
}

