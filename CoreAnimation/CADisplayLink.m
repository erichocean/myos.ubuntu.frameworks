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

#import <CoreAnimation/CoreAnimation-private.h>
#import <OpenGLES/EAGL-private.h>

#pragma mark - Static functions

void CADisplayLinkStartTimer(CADisplayLink *displayLink)
{
    CFTimeInterval previousDelay = 0;
    CFTimeInterval delay;
    CFTimeInterval timestamp;
    if (displayLink->_timer) {
        //DLog();
        [displayLink->_timer invalidate];
    }
    
    float interval = (displayLink->_frameInterval * 1.0) / 60.0;
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

@synthesize timestamp=_timestamp;
@synthesize duration=_duration;

#pragma mark - Life cycle

+ (CADisplayLink *)displayLinkWithTarget:(id)target selector:(SEL)sel
{
    //DLog(@"target: %@, selector: %@", target, NSStringFromSelector(sel));
    /*CADisplayLink *displayLink = [[[CADisplayLink alloc] init] autorelease];
    displayLink->_target = [target retain];
    displayLink->_selector = sel;
    EAGLContext *context = [EAGLContext currentContext];
    if (!context->_vSyncEnabled) {
        CADisplayLinkStartTimer(displayLink);
    }*/
    return [[[CADisplayLink alloc] initWithTarget:target selector:sel] autorelease];
}

- (id)initWithTarget:(id)target selector:(SEL)sel
{
    self = [self init];
    if (self) {
        //DLog(@"target: %@, selector: %@", target, NSStringFromSelector(sel));
        //CADisplayLink *displayLink = [[CADisplayLink alloc] init];
        _target = target;
        _selector = sel;
        //EAGLContext *context = [EAGLContext currentContext];
        //if (!context->_vSyncEnabled) {
            CADisplayLinkStartTimer(self);
        //}
        //return displayLink;
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        _frameInterval = 1;
    }
    return self;
}

- (void)dealloc
{
    //[_target release];
    [_timer invalidate];
    [super dealloc];
}

#pragma mark - Accessors

- (NSInteger)frameInterval
{
    return _frameInterval;
}

- (void)setFrameInterval:(NSInteger)newFrameInterval
{
    //DLog();
    _frameInterval = newFrameInterval;
    EAGLContext *context = [EAGLContext currentContext];
    if (context->_vSyncEnabled) {
        _EAGLSetSwapInterval(_frameInterval);
    } else {
        CADisplayLinkStartTimer(self);
    }
}

- (BOOL)isPaused
{
    return _paused;
}

- (void)setPaused:(BOOL)isPaused
{
    DLog();
    _paused=isPaused;
    //DLog(@"_paused: %d", _paused);
    if (_paused) {
        if (_timer) {
            [_timer invalidate];
            _timer = nil;
        }
        //DLog(@"_timer: %@", _timer);
    } else {
        CADisplayLinkStartTimer(self);
    }
}

#pragma mark - Delegates

- (void)displayFrame
{
    //DLog();
    //NSTimeInterval timeBefore = CACurrentMediaTime();
    //_CAAnimatorFrameCount++;
    //_EAGLSwapBuffers();
    //NSTimeInterval delay = CACurrentMediaTime() - timeBefore;
    //DLog(@"delay: %f", delay);
    [_target performSelector:_selector];
}

#pragma mark - Public methods

- (void)invalidate
{
    [_timer invalidate];
    _timer = nil;
    [self release];
}

@end
