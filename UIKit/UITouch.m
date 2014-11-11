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
//#import <UIKit/UITouch-private.h>
//#import <UIKit/UIWindow.h>
//#import <UIKit/UIGestureRecognizerSubclass.h>

CGPoint _UITouchConvertLocationPoint(UITouch *touch, CGPoint thePoint, UIView *inView);

#pragma mark - Static functions

static NSArray *_GestureRecognizersForView(UIView *view)
{
    NSMutableArray *recognizers = [[NSMutableArray alloc] initWithCapacity:0];
    BOOL isUIControl = [view isKindOfClass:[UIControl class]];
    while (view) {
        [recognizers addObjectsFromArray:[view->_gestureRecognizers allObjects]];
        view = [view superview];
    }
    if (isUIControl) {
        int i=0;
        while (i<recognizers.count) {
            id recognizer = [recognizers objectAtIndex:i];
            if ([recognizer isKindOfClass:[UITapGestureRecognizer class]]) {
                [recognizers removeObject:recognizer];
            } else {
                i++;
            }
        }
    }
    return [recognizers autorelease];
}

@implementation UITouch

@synthesize timestamp=_timestamp;
@synthesize tapCount=_tapCount;
@synthesize phase=_phase;
@synthesize view=_view;
@synthesize window=_window;
@synthesize gestureRecognizers=_gestureRecognizers;

#pragma mark - Life cycle

- (id)init
{
    if ((self=[super init])) {
        _phase = UITouchPhaseCancelled;
        _gesture = _UITouchGestureUnknown;
        _delta = CGPointZero;
    }
    return self;
}

- (void)dealloc
{
    [_window release];
    [_view release];
    [_gestureRecognizers release];
    [super dealloc];
}

#pragma mark - Accessors

- (UIWindow *)window
{
    return _window;
}

- (CGPoint)locationInView:(UIView *)inView
{
    //DLog();
    return _UITouchConvertLocationPoint(self, _location, inView);
}

- (CGPoint)previousLocationInView:(UIView *)inView
{
    return _UITouchConvertLocationPoint(self, _previousLocation, inView);
}

- (NSString *)description
{
    NSString *phase = @"";
    switch (self.phase) {
        case UITouchPhaseBegan:
            phase = @"Began";
            break;
        case UITouchPhaseMoved:
            phase = @"Moved";
            break;
        case UITouchPhaseStationary:
            phase = @"Stationary";
            break;
        case UITouchPhaseEnded:
            phase = @"Ended";
            break;
        case UITouchPhaseCancelled:
            phase = @"Cancelled";
            break;
        case _UITouchPhaseGestureBegan:
            phase = @"GestureBegan";
            break;
        case _UITouchPhaseGestureChanged:
            phase = @"GestureChanged";
            break;
        case _UITouchPhaseGestureEnded:
            phase = @"GestureEnded";
            break;
        case _UITouchPhaseDiscreteGesture:
            phase = @"DiscreteGesture";
            break;
    }
    return [NSString stringWithFormat:@"<%@: %p; location: %@, tapCount = %d; phase = %@; view = <%@: %p>>",
            [self className], self, NSStringFromCGPoint(self->_location), self.tapCount, phase, [self.view className], self.view];
}

@end

#pragma mark - Shared functions

void _UITouchSetPhase(UITouch *touch, UITouchPhase phase, CGPoint screenLocation, NSUInteger tapCount, CGPoint delta, NSTimeInterval timestamp)
{
    //DLog(@"screenLocation: %@", NSStringFromCGPoint(screenLocation));
    //DLog(@"timestamp: %f", timestamp);
    //DLog(@"tapCount: %d", tapCount);
    touch->_phase = phase;
    touch->_gesture = _UITouchGestureUnknown;
    touch->_previousLocation = touch->_location = screenLocation;
    touch->_tapCount = tapCount;
    touch->_timestamp = timestamp;
    touch->_rotation = 0;
    touch->_magnification = 0;
}
 
void _UITouchUpdatePhase(UITouch *touch, UITouchPhase phase, CGPoint screenLocation, NSTimeInterval timestamp)
{
    //DLog(@"screenLocation: %@", NSStringFromCGPoint(screenLocation));
    //DLog(@"timestamp: %f", timestamp);
    //if (!CGPointEqualToPoint(screenLocation, touch->_location)) {
    touch->_previousLocation = touch->_location;
    touch->_location = screenLocation;
    //DLog(@"touch->_delta: %@", NSStringFromCGPoint(touch->_delta));
    touch->_delta = CGPointMake(screenLocation.x - touch->_previousLocation.x, screenLocation.y - touch->_previousLocation.y);
    //DLog(@"touch->_delta: %@", NSStringFromCGPoint(touch->_delta));
    touch->_phase = phase;
    touch->_timestamp = timestamp;
}

void _UITouchSetTouchedView(UITouch *touch, UIView *view)
{
    //DLog(@"touch: %@", touch);
    //DLog(@"view: %@", view);
    if (touch->_view != view) {
        [touch->_view release];
        touch->_view = [view retain];
    }
    if (touch->_window != view.window) {
        [touch->_window release];
        touch->_window = [view.window retain];
    }
    [touch->_gestureRecognizers release];
    touch->_gestureRecognizers = [_GestureRecognizersForView(touch->_view) copy];
    //DLog(@"_gestureRecognizers: %@", touch->_gestureRecognizers);
}

void _UITouchRemoveFromView(UITouch *touch)
{
    NSMutableArray *remainingRecognizers = [touch->_gestureRecognizers mutableCopy];

    // if the view is being removed from this touch, we need to remove/cancel any gesture recognizers that belong to the view
    // being removed. this kinda feels like the wrong place for this, but the touch itself has a list of potential gesture
    // recognizers attached to it so an active touch only considers the recongizers that were present at the point the touch
    // first touched the screen. it could easily have recognizers attached to it from superviews of the view being removed so
    // we can't just cancel them all. the view itself could cancel its own recognizers, but then it needs a way to remove them
    // from an active touch so in a sense we're right back where we started. so I figured we might as well just take care of it
    // here and see what happens.
    for (UIGestureRecognizer *recognizer in touch->_gestureRecognizers) {
        if (recognizer.view == touch->_view) {
            if (recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged) {
                recognizer.state = UIGestureRecognizerStateCancelled;
            }
            [remainingRecognizers removeObject:recognizer];
        }
    }
    [touch->_gestureRecognizers release];
    touch->_gestureRecognizers = [remainingRecognizers copy];
    [remainingRecognizers release];
    
    [touch->_view release];
    touch->_view = nil;
}

CGPoint _UITouchConvertLocationPoint(UITouch *touch, CGPoint thePoint, UIView *inView)
{
    UIWindow *window = touch->_window;
    // The stored location should always be in the coordinate space of the UIScreen that contains the touch's window.
    // So first convert from the screen to the window:
    CGPoint point = [window convertPoint:thePoint fromWindow:nil];
    // Then convert to the desired location (if any).
    if (inView) {
        point = [inView convertPoint:point fromView:window];
    }
    return point;
}
