/*
 * Copyright (c) 2011, The Iconfactory. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of The Iconfactory nor the names of its contributors may
 *    be used to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE ICONFACTORY BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <UIKit/UIKit-private.h>

//#import <UIKit/UILongPressGestureRecognizer.h>
//#import <UIKit/UIGestureRecognizerSubclass.h>
//#import <UIKit/UITouch.h>

//#define _KLongPressGestureDelay	0.25

BOOL canEnd = YES;

@implementation UILongPressGestureRecognizer

@synthesize minimumPressDuration=_minimumPressDuration;
@synthesize allowableMovement=_allowableMovement;
@synthesize numberOfTapsRequired=_numberOfTapsRequired;
@synthesize numberOfTouchesRequired=_numberOfTouchesRequired;

#pragma mark - Life cycle

- (id)initWithTarget:(id)target action:(SEL)action
{
    if ((self=[super initWithTarget:target action:action])) {
        _allowableMovement = 10;
        _minimumPressDuration = 0.5;
        _numberOfTapsRequired = 0;
        _numberOfTouchesRequired = 1;
        _timePassed = NO;
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark - Accessors

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@; _minimumPressDuration = %d>", [super description], _minimumPressDuration];
}

#pragma mark - Overridden methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //DLog(@"self: %@", self);
    if (self->_state == UIGestureRecognizerStatePossible) {
        self.state = UIGestureRecognizerStateBegan;
        [NSTimer scheduledTimerWithTimeInterval:_minimumPressDuration
                                         target:self
                                       selector:@selector(_timerCheckStatus)
                                       userInfo:nil
                                        repeats:NO];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //DLog();
    [self _changeStatus];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    //DLog(@"self: %@", self);
    if (self->_state == UIGestureRecognizerStateBegan) {
        self.state = UIGestureRecognizerStateCancelled;
    }
}

// called when _failureRequirements gestures changed its status
- (void)_changeStatus
{
    //DLog();
    UITouch *touch = nil;
    if ([_trackingTouches count]) {
        touch = [_trackingTouches objectAtIndex:0];
    } else {
        return;
    }
    if (touch->_tapCount >= _numberOfTapsRequired) {
        //DLog();
        if (_state == UIGestureRecognizerStateBegan) {
            if (!_timePassed) {
                //DLog();
                self.state = UIGestureRecognizerStateFailed;
            }
        }
    }
    if (_timePassed) {
        //DLog();
        //self.state = UIGestureRecognizerStateRecognized;
        _timePassed = NO;
    }
}

#pragma mark - Delegates

// called when timer is fired
- (void)_timerCheckStatus
{
    if (self->_state == UIGestureRecognizerStateBegan) {
        //DLog();
        _timePassed = YES;
        self.state = UIGestureRecognizerStateRecognized;
    }
}

#pragma mark - Public methods

@end
