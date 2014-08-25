/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import "CABase.h"

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

extern CFTimeInterval CACurrentMediaTime();

extern NSString *const kCAFillModeForwards;
extern NSString *const kCAFillModeBackwards;
extern NSString *const kCAFillModeBoth;
extern NSString *const kCAFillModeRemoved;
extern NSString *const kCAFillModeFrozen;

