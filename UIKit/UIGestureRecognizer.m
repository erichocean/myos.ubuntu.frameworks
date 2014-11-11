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

#import <UIKit/UIGestureRecognizer-private.h>
//#import <UIKit/UIGestureRecognizerSubclass.h>
#import <UIKit/UITouch.h>
#import <UIKit/UIAction.h>
#import <UIKit/UIApplication.h>
 
@implementation UIGestureRecognizer

@synthesize delegate=_delegate;
@synthesize delaysTouchesBegan=_delaysTouchesBegan;
@synthesize delaysTouchesEnded=_delaysTouchesEnded;
@synthesize cancelsTouchesInView=_cancelsTouchesInView;
@synthesize state=_state;
@synthesize enabled=_enabled;
@synthesize view=_view;

#pragma mark - Life cycle

- (id)init
{
    if ((self=[super init])) {
        _state = UIGestureRecognizerStatePossible;
        _cancelsTouchesInView = YES;
        _delaysTouchesBegan = NO;
        _delaysTouchesEnded = YES;
        _enabled = YES;
        _registeredActions = [[NSMutableArray alloc] initWithCapacity:1];
        _trackingTouches = [[NSMutableArray alloc] initWithCapacity:1];
        _failureRequirements = [[NSMutableSet alloc] initWithCapacity:2];
        //_didFailFlags = [[NSMutableArray alloc] initWithCapacity:2];
        
        //_failureDependents = [[NSMutableSet alloc] initWithCapacity:1];
        //_requiresToFail = nil;
        _failureCount = 0;
    }
    return self;
}

- (id)initWithTarget:(id)target action:(SEL)action
{
    if ((self=[self init])) {
        [self addTarget:target action:action];
    }
    return self;
}

- (void)dealloc
{
    [_registeredActions release];
    [_trackingTouches release];
    for (UIGestureRecognizer *recognizer in _failureRequirements) {
        [recognizer removeObserver:self forKeyPath:@"state"];
    }
    //[_requiresToFail release];
    [_failureRequirements release];
    //[_didFailFlags release];
    //[_failureDependents release];
    [super dealloc];
}

#pragma mark - Accessors

- (void)setDelegate:(id<UIGestureRecognizerDelegate>)aDelegate
{
    if (aDelegate != _delegate) {
        _delegate = aDelegate;
        _delegateHas.shouldBegin = [_delegate respondsToSelector:@selector(gestureRecognizerShouldBegin:)];
        _delegateHas.shouldReceiveTouch = [_delegate respondsToSelector:@selector(gestureRecognizer:shouldReceiveTouch:)];
        _delegateHas.shouldRecognizeSimultaneouslyWithGestureRecognizer = [_delegate respondsToSelector:@selector(gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)];
    }
}

- (NSUInteger)numberOfTouches
{
    return [_trackingTouches count];
}

- (CGPoint)locationInView:(UIView *)view
{
    // by default, this should compute the centroid of all the involved points
    // of course as of this writing, Chameleon only supports one point but at least
    // it may be semi-correct if that ever changes. :D YAY FOR COMPLEXITY!
    
    CGFloat x = 0;
    CGFloat y = 0;
    CGFloat k = 0;
    
    for (UITouch *touch in _trackingTouches) {
        const CGPoint p = [touch locationInView:view];
        x += p.x;
        y += p.y;
        k++;
    }
    if (k > 0) {
        return CGPointMake(x/k, y/k);
    } else {
        return CGPointZero;
    }
}

- (CGPoint)locationOfTouch:(NSUInteger)touchIndex inView:(UIView *)view
{
    return [[_trackingTouches objectAtIndex:touchIndex] locationInView:view];
}

- (void)setState:(UIGestureRecognizerState)state
{
    // the docs didn't say explicitly if these state transitions were verified, but I suspect they are. if anything, a check like this
    // should help debug things. it also helps me better understand the whole thing, so it's not a total waste of time :)

    //DLog(@"state: %d", state);
    typedef struct { UIGestureRecognizerState fromState, toState; BOOL shouldNotify, shouldReset; } StateTransition;

    #define _kNumberOfStateTransitions 10
    static const StateTransition allowedTransitions[_kNumberOfStateTransitions] = {
        // discrete gestures
        {UIGestureRecognizerStatePossible,	UIGestureRecognizerStateRecognized,	YES,   YES},
        {UIGestureRecognizerStatePossible,	UIGestureRecognizerStateFailed,     NO,    YES},

        // continuous gestures
        {UIGestureRecognizerStatePossible,	UIGestureRecognizerStateBegan,      NO,    NO },
        {UIGestureRecognizerStateBegan,		UIGestureRecognizerStateChanged,    NO,    NO },
        {UIGestureRecognizerStateBegan,		UIGestureRecognizerStateCancelled,  NO,    YES},
        {UIGestureRecognizerStateBegan,		UIGestureRecognizerStateFailed,     NO,    YES},
        {UIGestureRecognizerStateBegan,		UIGestureRecognizerStateEnded,      YES,   YES},
        {UIGestureRecognizerStateChanged,	UIGestureRecognizerStateChanged,    NO,    NO },
        {UIGestureRecognizerStateChanged,	UIGestureRecognizerStateCancelled,  NO,    YES},
        {UIGestureRecognizerStateChanged,	UIGestureRecognizerStateEnded,      YES,   YES}
    };
    
    const StateTransition *transition = NULL;

    for (NSUInteger t=0; t<_kNumberOfStateTransitions; t++) {
        if (allowedTransitions[t].fromState == _state && allowedTransitions[t].toState == state) {
            transition = &allowedTransitions[t];
            break;
        }
    }
    if (!transition) {
        //NSAssert2((transition != NULL), @"invalid state transition from %d to %d", _state, state);
        if (_state != state) {
            DLog(@"self: %@, invalid state transition from %d to %d", self, _state, state);
        }
    } else {
        //DLog(@"self: %@, _state: %d, state: %d", self, _state, state);
        [self willChangeValueForKey:@"state"];
        _state = transition->toState;
        [self didChangeValueForKey:@"state"];
        if (transition->shouldNotify) {
            //DLog(@"transition->shouldNotify");
            _UIGestureRecognizerPerformActions(self);
        }
        if (transition->shouldReset) {
            //[self reset];
            [self performSelector:@selector(reset) withObject:nil afterDelay:0];
        }
    }
}

- (NSString *)description
{
    NSString *state = @"";
    switch (self.state) {
        case UIGestureRecognizerStatePossible:
            state = @"Possible";
            break;
        case UIGestureRecognizerStateBegan:
            state = @"Began";
            break;
        case UIGestureRecognizerStateChanged:
            state = @"Changed";
            break;
        case UIGestureRecognizerStateEnded:
            state = @"Ended";
            break;
        case UIGestureRecognizerStateCancelled:
            state = @"Cancelled";
            break;
        case UIGestureRecognizerStateFailed:
            state = @"Failed";
            break;
    }
    return [NSString stringWithFormat:@"<%@: %p; state = %@; view = <%@: %p>>", [self className], self, state, [self.view className], self.view];
}

#pragma mark - Overriden methods

- (void)ignoreTouch:(UITouch *)touch forEvent:(UIEvent*)event
{
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
}

#pragma mark - Delegates

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //DLog(@"self: %@, object: %@", self, object);
    if ([keyPath isEqualToString:@"state"]) {
        [self _changeStatus];
    }
}

- (void)_changeStatus
{

}

#pragma mark - Public methods

- (void)addTarget:(id)target action:(SEL)action
{
    NSAssert(target != nil, @"target must not be nil");
    NSAssert(action != NULL, @"action must not be NULL");
    
    UIAction *actionRecord = [[UIAction alloc] init];
    actionRecord.target = target;
    actionRecord.action = action;
    [_registeredActions addObject:actionRecord];
    [actionRecord release];
}

- (void)removeTarget:(id)target action:(SEL)action
{
    UIAction *actionRecord = [[UIAction alloc] init];
    actionRecord.target = target;
    actionRecord.action = action;
    [_registeredActions removeObject:actionRecord];
    [actionRecord release];
}

- (void)requireGestureRecognizerToFail:(UIGestureRecognizer *)otherGestureRecognizer
{
    //DLog(@"otherGestureRecognizer: %@", otherGestureRecognizer);
    [_failureRequirements addObject:otherGestureRecognizer];
    [otherGestureRecognizer addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionOld context:nil];
}

- (void)reset
{
    //BOOL canChangeToPossible = YES;
    /*_failureCount = 0;
    for (UIGestureRecognizer *recognizer in self->_failureDependents) {
        _failureCount++;
        [recognizer _changeStatus];
    }*/
    //if (!_failureCount || _state == UIGestureRecognizerStateEnded) {
    
    //[self willChangeValueForKey:@"state"];
    //DLog(@"self: %@", self);
    _state = UIGestureRecognizerStatePossible;
    //[self didChangeValueForKey:@"state"];
    //}
    [_trackingTouches removeAllObjects];
    /*for (UIGestureRecognizer *recognizer in self->_failureRequirements) {
        recognizer->_failureCount--;
        if (!recognizer->_failureCount && (recognizer->_state == UIGestureRecognizerStateFailed || recognizer->_state == UIGestureRecognizerStateCancelled)) {
            recognizer->_state = UIGestureRecognizerStatePossible;
        }
    }*/
}
/*
- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer
{
    return YES;
}

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer
{
    return YES;
}*/

@end

#pragma mark - Shared functions

void _UIGestureRecognizerSetView(UIGestureRecognizer *recognizer, UIView *v)
{
    [recognizer reset];	// not sure about this, but it kinda makes sense
    recognizer->_view = v;
}

BOOL _UIGestureRecognizerShouldAttemptToRecognize(UIGestureRecognizer *recognizer)
{
    BOOL result = (recognizer->_enabled &&
            recognizer->_state != UIGestureRecognizerStateFailed &&
            recognizer->_state != UIGestureRecognizerStateCancelled && 
            recognizer->_state != UIGestureRecognizerStateEnded);
    return result;
}

void _UIGestureRecognizerRecognizeTouches(UIGestureRecognizer *recognizer, NSSet *touches, UIEvent *event)
{
    //DLog();
    if (_UIGestureRecognizerShouldAttemptToRecognize(recognizer)) {
        [recognizer->_trackingTouches setArray:[touches allObjects]];
        for (UITouch *touch in recognizer->_trackingTouches) {
            //DLog(@"touch: %@", touch);
            switch (touch->_phase) {
                case UITouchPhaseBegan:
                    [recognizer touchesBegan:touches withEvent:event];
                    break;
                case UITouchPhaseMoved:
                    [recognizer touchesMoved:touches withEvent:event];
                    break;
                case UITouchPhaseEnded:
                    [recognizer touchesEnded:touches withEvent:event];
                    break;
                case UITouchPhaseCancelled:
                    [recognizer touchesCancelled:touches withEvent:event];
                    break;
                default:
                    break;
            }
        }
    }
    //DLog(@"recognizer: %@", recognizer);
}

void _UIGestureRecognizerPerformActions(UIGestureRecognizer *recognizer)
{
    //DLog(@"recognizer: %@", recognizer);
    for (UIAction *actionRecord in recognizer->_registeredActions) {
        //DLog(@"recognizer: %@", recognizer);
        // docs mention that the action messages are sent on the next run loop, so we'll do that here.
        // note that this means that reset can't happen until the next run loop, either otherwise
        // the state property is going to be wrong when the action handler looks at it, so as a result
        // I'm also delaying the reset call (if necessary) just below here.
        [actionRecord.target performSelector:actionRecord.action withObject:recognizer];
    }
    //for (UIGestureRecognizer *failureRecognizer in recognizer->_failureDependents) {
    //    failureRecognizer->_state = UIGestureRecognizerStateCancelled;
    //}
}

