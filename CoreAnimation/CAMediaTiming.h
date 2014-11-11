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

#import <CoreAnimation/CABase.h>

@protocol CAMediaTiming

@property CFTimeInterval beginTime;
@property CFTimeInterval timeOffset;
@property CFTimeInterval duration;
@property CFTimeInterval repeatDuration;
@property float repeatCount;
@property BOOL autoreverses;
@property (copy) NSString *fillMode;
@property float speed;

- (CFTimeInterval)timeOffset;
- (void)setTimeOffset:(CFTimeInterval)theTimeOffset;

@end 

CFTimeInterval CACurrentMediaTime();

extern NSString *const kCAFillModeForwards;
extern NSString *const kCAFillModeBackwards;
extern NSString *const kCAFillModeBoth;
extern NSString *const kCAFillModeRemoved;
extern NSString *const kCAFillModeFrozen;

