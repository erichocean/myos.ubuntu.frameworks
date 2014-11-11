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

#import <UIKit/UIEvent-private.h>
#import <UIKit/UITouch.h>

@implementation UIEvent

@synthesize timestamp=_timestamp;
@synthesize type=_type;

#pragma mark - Life cycle

- (id)initWithEventType:(UIEventType)type
{
    if ((self=[super init])) {
        _type = type;
    }
    return self;
}

- (void)dealloc
{
    [_touch release];
    [super dealloc];
}

#pragma mark - Accessors

- (NSSet *)allTouches
{
    //DLog(@"_touch: %@", _touch);
    return [NSSet setWithObject:_touch];
}

- (NSSet *)touchesForView:(UIView *)view
{
    NSMutableSet *touches = [NSMutableSet setWithCapacity:1];
    for (UITouch *touch in [self allTouches]) {
        if (touch.view == view) {
            [touches addObject:touch];
        }
    }
    return touches;
}

- (NSSet *)touchesForWindow:(UIWindow *)window
{
    NSMutableSet *touches = [NSMutableSet setWithCapacity:1];
    for (UITouch *touch in [self allTouches]) {
        if (touch.window == window) {
            [touches addObject:touch];
        }
    }
    return touches;
}

- (NSSet *)touchesForGestureRecognizer:(UIGestureRecognizer *)gesture
{
    NSMutableSet *touches = [NSMutableSet setWithCapacity:1];
    for (UITouch *touch in [self allTouches]) {
        if ([touch->_gestureRecognizers containsObject:gesture]) {
            [touches addObject:touch];
        }
    }
    return touches;
}

- (UIEventSubtype)subtype
{
    return UIEventSubtypeNone;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; touch: <%@>; timestamp = %f>", [self className], self, self->_touch, self.timestamp];
}

@end

#pragma mark - Shared functions

void _UIEventSetTouch(UIEvent *event, UITouch *t)
{
    if (event->_touch != t) {
        [event->_touch release];
        event->_touch = [t retain];
    }
}
