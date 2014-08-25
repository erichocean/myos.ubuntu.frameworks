/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <CoreAnimation/CoreAnimation-private.h>

#pragma mark - Static C functions

void CADisplayLinkStartTimer(CADisplayLink *displayLink)
{
    CFTimeInterval previousDelay = 0;
    CFTimeInterval delay;
    CFTimeInterval timestamp;
    if (displayLink->_timer) {
        [displayLink->_timer invalidate];
        //[displayLink->_timer release];
    }
    for (int i=0; i<5; i++) {
        timestamp = CACurrentMediaTime();
        _EAGLSwapBuffers();
        delay = CACurrentMediaTime() - timestamp;
        //if ((previousDelay-delay)/delay > 5 && delay < 0.01) {
        if (delay < 0.01) {
            break;
        }
        previousDelay = delay;
    }
    //DLog(@"delay: %f", delay);
    float interval = (displayLink->frameInterval * 1.0) / 60.0;
    //DLog(@"interval: %f", interval);
    displayLink->_timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                             target:displayLink
                                           selector:@selector(displayFrame)
                                           userInfo:nil
                                            repeats:YES];
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addTimer:displayLink->_timer forMode:NSDefaultRunLoopMode];
    [displayLink performSelector:@selector(displayFrame)];
}

@implementation CADisplayLink

@synthesize timestamp;
@synthesize duration;

#pragma mark - Life cycle

+ (CADisplayLink *)displayLinkWithTarget:(id)target selector:(SEL)sel
{
    //DLog(@"target: %@, selector: %@", target, NSStringFromSelector(sel));
    CADisplayLink *displayLink = [[[CADisplayLink alloc] init] autorelease];
    displayLink->_target = [target retain];
    displayLink->_selector = sel;
    EAGLContext *context = [EAGLContext currentContext];
    if (!context->_vSyncEnabled) {
        CADisplayLinkStartTimer(displayLink);
    }
    return displayLink;
}

- (id)init
{
    self = [super init];
    if (self) {
        frameInterval = 1;
    }
    return self;
}

- (void)dealloc
{
    [_target release];
    [_timer invalidate];
    [super dealloc];
}

#pragma mark - Accessors

- (NSInteger)frameInterval
{
    return frameInterval;
}

- (void)setFrameInterval:(NSInteger)newFrameInterval
{
    //DLog();
    frameInterval = newFrameInterval;
    EAGLContext *context = [EAGLContext currentContext];
    if (context->_vSyncEnabled) {
        _EAGLSetSwapInterval(frameInterval);
    } else {
        CADisplayLinkStartTimer(self);
    }
}

- (BOOL)isPaused
{
    return paused;
}

- (void)setPaused:(BOOL)isPaused
{
    paused=isPaused;
}

#pragma mark - Delegates

- (void)displayFrame
{
    //DLog();
    //NSTimeInterval timeBefore = CACurrentMediaTime();
    _CAAnimatorFrameCount++;
    _EAGLSwapBuffers();
    //NSTimeInterval delay = CACurrentMediaTime() - timeBefore;
    //DLog(@"delay: %f", delay);
    [_target performSelector:_selector];
}

#pragma mark - Helpers

- (void)invalidate
{
    
}

@end
