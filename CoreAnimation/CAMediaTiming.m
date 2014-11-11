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

#import <CoreAnimation/CAMediaTiming.h>

NSString *const kCAFillModeForwards = @"CAFillModeForwards";
NSString *const kCAFillModeBackwards = @"CAFillModeBackwards";
NSString *const kCAFillModeBoth = @"CAFillModeBoth";
NSString *const kCAFillModeRemoved = @"CAFillModeRemoved";
NSString *const kCAFillModeFrozen = @"CAFillModeFrozen";

CFTimeInterval CACurrentMediaTime() 
{
    CFTimeInterval result = (CFTimeInterval)[NSDate timeIntervalSinceReferenceDate];
    //DLog(@"result: %f", result);
    return result;
}

