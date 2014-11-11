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

typedef enum {
    _CAAnimatorConditionLockStartup,
    _CAAnimatorConditionLockHasNoWork,
    _CAAnimatorConditionLockHasWork
} _CAAnimatorConditionLockTypes;

extern NSConditionLock *_CAAnimatorConditionLock;
#ifdef NA
extern NSConditionLock *_CAAnimatorNAConditionLock;
#endif
//extern BOOL _CAAnimatorCaptureScreen;
extern CGImageRef _CAAnimatorScreenCapture;

@interface CAAnimator : NSObject

+ (void)run;
+ (void)display;

@end

void _CAAnimatorInitialize();
