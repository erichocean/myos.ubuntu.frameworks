/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <CoreAnimation/CABase.h>

@interface CADisplayLink : NSObject
{
@package
    CFTimeInterval timestamp;
    CFTimeInterval duration;
    BOOL paused;
    NSInteger frameInterval;
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

//void _CAAnimatorInitialize();
