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

//#import <UIKit/UIPanGestureRecognizer.h>
//#import <UIKit/UIGestureRecognizerSubclass.h>
//#import <UIKit/UIGestureRecognizer-private.h>
//#import <UIKit/UITouch.h>
//#import <UIKit/UIEvent.h>
//#import <UIKit/UIGeometry.h>

#pragma mark - Static functions

BOOL _UIPanGestureRecognizerUpdate(UIPanGestureRecognizer *recognizer, CGPoint delta, UIEvent *event)
{
    NSTimeInterval timeDiff = event.timestamp - recognizer->_lastMovementTime;
    //DLog(@"delta: %@", NSStringFromCGPoint(delta));
    //DLog(@"timeDiff: %f", timeDiff);
    //DLog(@"recognizer->_lastMovementTime: %f", recognizer->_lastMovementTime);
    //DLog(@"event.timestamp: %f", event.timestamp);
    if (timeDiff > 0) { //!CGPointEqualToPoint(delta, CGPointZero) &&
        //DLog(@"recognizer->_translation: %@", NSStringFromCGPoint(recognizer->_translation));
        recognizer->_translation.x = delta.x;
        recognizer->_translation.y = delta.y;
        //CGPoint tempVelocity;
        //tempVelocity.x = delta.x / timeDiff;
        //tempVelocity.y = delta.y / timeDiff;
        
        if (delta.x * recognizer->_displacement.x >= 0) {
            recognizer->_displacement.x += delta.x;
            recognizer->_movementDuration += timeDiff;
            
            //recognizer->_velocity.x += tempVelocity.x;
            //recognizer->_velocityCountX++;
        } else { // changed direction
            //DLog(@"changed direction");
            recognizer->_displacement.x = delta.x;
            recognizer->_movementDuration = timeDiff;
            
            //recognizer->_velocity.x = tempVelocity.x;
            //recognizer->_velocityCountX = 1;
        }
        if (delta.y * recognizer->_displacement.y >= 0) {
            recognizer->_displacement.y += delta.y;
            recognizer->_movementDuration += timeDiff;
            
            //recognizer->_velocity.y += tempVelocity.y;
            //recognizer->_velocityCountY++;
        } else {
            //DLog(@"changed direction, tempVelocity: %@", NSStringFromCGPoint(tempVelocity));
            recognizer->_displacement.y = delta.y;
            recognizer->_movementDuration = timeDiff;
            
            //recognizer->_velocity.y = tempVelocity.y;
            //recognizer->_velocityCountY = 1;
        }
        //recognizer->_velocity.x = delta.x / timeDiff;
        //recognizer->_velocity.y = delta.y / timeDiff;
        recognizer->_lastMovementTime = event.timestamp;
        //DLog(@"_displacement: %@", NSStringFromCGPoint(recognizer->_displacement));
        //DLog(@"_movementDuration: %0.3f", recognizer->_movementDuration);
        //DLog(@"recognizer->_velocity: %@", NSStringFromCGPoint(recognizer->_velocity));
        //DLog(@"recognizer->_velocityCountX: %d, recognizer->_velocityCountY: %d", recognizer->_velocityCountX, recognizer->_velocityCountY);
        //DLog(@"recognizer->_translation: %@", NSStringFromCGPoint(recognizer->_translation));
        return YES;
    } else {
        return NO;
    }
}

@implementation UIPanGestureRecognizer

@synthesize maximumNumberOfTouches=_maximumNumberOfTouches;
@synthesize minimumNumberOfTouches=_minimumNumberOfTouches;

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
    //DLog(@"_translation: %@", NSStringFromCGPoint(_translation));
    return _translation;
}

- (void)setTranslation:(CGPoint)translation inView:(UIView *)view
{
    DLog(@"translation: %@", NSStringFromCGPoint(translation));
    _velocity = CGPointZero;
    _translation = translation;
}

- (CGPoint)velocityInView:(UIView *)view
{
    //DLog(@"_velocity: %@", NSStringFromCGPoint(_velocity));
    return _velocity;
}
/*
- (void)setState:(UIGestureRecognizerState)state
{
    [super setState:state];
    //_UIGestureRecognizerPerformActions(self);
}*/

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@; translation = %@; velocity = %@; lastMovementTime: %f>>", [super description], NSStringFromCGPoint(_translation), NSStringFromCGPoint(_velocity), _lastMovementTime];
}

#pragma mark - Overridden methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //DLog(@"self: %@", self);
    self->_state = UIGestureRecognizerStatePossible;
    _lastMovementTime = event->_timestamp;
}

//- (void)_gesturesMoved:(NSSet *)touches withEvent:(UIEvent *)event
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    //DLog(@"self: %@", self);
    //UITouch *touch = PanTouch([event touchesForGestureRecognizer:self]);
    // note that we being the gesture here in the _gesturesMoved:withEvent: method instead of the _gesturesBegan:withEvent:
    // method because the pan gesture cannot be recognized until the user moves their fingers a bit and OSX won't tag the
    // gesture as a pan until that movement has actually happened so we have to do the checking here.
    if (self->_state == UIGestureRecognizerStatePossible && touch) {
        //[self setTranslation:touch->_delta inView:touch.view];
        self.state = UIGestureRecognizerStateBegan;
        _startLocation = touch->_location;
        _startTime = event.timestamp;
        _UIGestureRecognizerPerformActions(self);
        //DLog(@"UIGestureRecognizerStateBegan");
    }
    if (self->_state == UIGestureRecognizerStateBegan || self->_state == UIGestureRecognizerStateChanged) {
        if (touch) {
            if (_UIPanGestureRecognizerUpdate(self, touch->_delta, event)) {
                //DLog();
                //_lastMovementTime = event.timestamp;
                self.state = UIGestureRecognizerStateChanged;
                _UIGestureRecognizerPerformActions(self);
            }
        } /*else {
           self->_state = UIGestureRecognizerStateCancelled;
           }*/
    }
    /*if (self.state == UIGestureRecognizerStateChanged) {
        _lastMovementTime = event.timestamp;
    }*/
    //_UIGestureRecognizerPerformActions(self);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //DLog(@"self: %@", self);
    UITouch *touch = [touches anyObject];
    if (self.state == UIGestureRecognizerStateChanged) {
        NSTimeInterval timeDiff = event.timestamp - _lastMovementTime;// - _startTime;
        //DLog(@"timeDiff: %0.3f", timeDiff);
        if (timeDiff > 0.2) {
            //CGPoint myDelta = CGPointMake(touch->_location.x - touch->_previousLocation.x, touch->_location.y - touch->_previousLocation.y);
            //DLog(@"myDelta: %@", NSStringFromCGPoint(myDelta));
            //DLog(@"touch->_delta: %@", NSStringFromCGPoint(touch->_delta));
            //_UIPanGestureRecognizerUpdate(self, touch->_delta, event);
            _velocity.x = 0;//_velocity.x / _velocityCountX;//(touch->_location.x - _startLocation.x) / timeDiff;
            _velocity.y = 0;//_velocity.y / _velocityCountY;//(touch->_location.y - _startLocation.y) / timeDiff;
        } else {
            _velocity.x = _displacement.x / (_movementDuration?:0.001);//_velocity.x / _velocityCountX;//(touch->_location.x - _startLocation.x) / timeDiff;
            _velocity.y = _displacement.y / (_movementDuration?:0.001);//_velocity.y / _velocityCountY;//(touch->_location.y - _startLocation.y) / timeDiff;
        }
        //DLog(@"recognizer->_velocity: %@", NSStringFromCGPoint(_velocity));
        self.state = UIGestureRecognizerStateEnded;
    } else {
        self.state = UIGestureRecognizerStateFailed;
    }
}

#pragma mark - Public methods

- (void)reset
{
    [super reset];
    //DLog();
    _translation = CGPointZero;
    _velocity = CGPointZero;
    _movementDuration = 0;
    _displacement = CGPointZero;
    //_velocityCountX = 0;
    //_velocityCountY = 0;
}

@end

#pragma mark - Shared functions

