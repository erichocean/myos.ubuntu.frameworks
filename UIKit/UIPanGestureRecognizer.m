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

#import <UIKit/UIPanGestureRecognizer.h>
#import <UIKit/UIGestureRecognizerSubclass.h>
#import <UIKit/UIGestureRecognizer-private.h>
#import <UIKit/UITouch.h>
#import <UIKit/UIEvent.h>
#import <UIKit/UIGeometry.h>

// static UITouch *PanTouch(NSSet *touches)
// {
//     for (UITouch *touch in touches) {
//         if (touch->_gesture == _UITouchGesturePan) {
//             return touch;
//         }
//     }
//     return nil;
// }

BOOL _UIPanGestureRecognizerTranslate(UIPanGestureRecognizer *recognizer, CGPoint delta, UIEvent* event);

@implementation UIPanGestureRecognizer

@synthesize maximumNumberOfTouches=_maximumNumberOfTouches, minimumNumberOfTouches=_minimumNumberOfTouches;

#pragma mark - Life cycle

- (id)initWithTarget:(id)target action:(SEL)action
{
    if ((self=[super initWithTarget:target action:action])) {
        _minimumNumberOfTouches = 1;
        _maximumNumberOfTouches = NSUIntegerMax;
        _translation = CGPointZero;
        _velocity = CGPointZero;
    }
    return self;
}

#pragma mark - Accessors

- (CGPoint)translationInView:(UIView *)view
{
    return _translation;
}

- (void)setTranslation:(CGPoint)translation inView:(UIView *)view
{
    _velocity = CGPointZero;
    _translation = translation;
}

- (CGPoint)velocityInView:(UIView *)view
{
    return _velocity;
}
/*
- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@; translation = %@; velocity = %@; lastMovementTime: %f>>", [super description], NSStringFromCGPoint(_translation), NSStringFromCGPoint(_velocity), _lastMovementTime];
}*/

#pragma mark - Overridden methods

/*
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self->_state = UIGestureRecognizerStatePossible;
}*/

//- (void)_gesturesMoved:(NSSet *)touches withEvent:(UIEvent *)event
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    //UITouch *touch = PanTouch([event touchesForGestureRecognizer:self]);
    // note that we being the gesture here in the _gesturesMoved:withEvent: method instead of the _gesturesBegan:withEvent:
    // method because the pan gesture cannot be recognized until the user moves their fingers a bit and OSX won't tag the
    // gesture as a pan until that movement has actually happened so we have to do the checking here.
    if (self.state == UIGestureRecognizerStatePossible && touch) {
        [self setTranslation:touch->_delta inView:touch.view];
        _lastMovementTime = event.timestamp;
        self.state = UIGestureRecognizerStateBegan;
    } else if (self.state == UIGestureRecognizerStateBegan) { // || self.state == UIGestureRecognizerStateChanged) {
        if (touch) {
            //if (_UIPanGestureRecognizerTranslate(self, touch->_delta, event)) {
                self.state = UIGestureRecognizerStateChanged;
            //}
        } /*else {
            self->_state = UIGestureRecognizerStateCancelled;
        }*/
    }
    if (self.state == UIGestureRecognizerStateChanged) {
        _lastMovementTime = event.timestamp;
    }
    _UIGestureRecognizerPerformActions(self);
}

//- (void)_gesturesEnded:(NSSet *)touches withEvent:(UIEvent *)event
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.state == UIGestureRecognizerStateChanged) {
        self.state = UIGestureRecognizerStateEnded;
    } else {
        self.state = UIGestureRecognizerStateFailed;
    }
//        UITouch *touch = PanTouch([event touchesForGestureRecognizer:self]);
//        if (touch) {
            //_UIPanGestureRecognizerTranslate(self, touch->_delta, event);
          //self->_state = UIGestureRecognizerStatePossible;
        //  [self reset];
        //[self performSelector:@selector(reset) withObject:nil afterDelay:0];

//        } else {
//            self->_state = UIGestureRecognizerStateCancelled;
//        }
}

#pragma mark - Helpers

- (void)reset
{
    [super reset];
    _translation = CGPointZero;
    _velocity = CGPointZero;
}

@end

#pragma mark - Private C functions

BOOL _UIPanGestureRecognizerTranslate(UIPanGestureRecognizer *recognizer, CGPoint delta, UIEvent *event)
{
    const NSTimeInterval timeDiff = event.timestamp - recognizer->_lastMovementTime;
    if (!CGPointEqualToPoint(delta, CGPointZero) && timeDiff > 0) {
        recognizer->_translation.x += delta.x;
        recognizer->_translation.y += delta.y;
        recognizer->_velocity.x = delta.x / timeDiff;
        recognizer->_velocity.y = delta.y / timeDiff;
        recognizer->_lastMovementTime = event.timestamp;
        return YES;
    } else {
        return NO;
    }
}

