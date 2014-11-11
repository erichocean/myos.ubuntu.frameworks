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

@interface CADisplayLink : NSObject {
@package
    CFTimeInterval _timestamp;
    CFTimeInterval _duration;
    BOOL _paused;
    NSInteger _frameInterval;
    id _target;
    SEL _selector;
    NSTimer *_timer;
}

@property (nonatomic, readonly) CFTimeInterval timestamp;
@property (nonatomic, readonly) CFTimeInterval duration;
@property (nonatomic, getter=isPaused) BOOL paused;
@property (nonatomic) NSInteger frameInterval;

+ (CADisplayLink *)displayLinkWithTarget:(id)target selector:(SEL)sel;

- (void)invalidate;

@end
