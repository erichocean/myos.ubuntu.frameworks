/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <CoreAnimation/CABase.h>

typedef enum {
    _CAAnimatorConditionLockHasNoWork,
    _CAAnimatorConditionLockHasWork
} _CAAnimatorConditionLockTypes;

extern NSConditionLock *_CAAnimatorConditionLock;
extern int _CAAnimatorFrameCount;

@interface CAAnimator : NSObject

+ (void)run;

@end

void _CAAnimatorInitialize();
