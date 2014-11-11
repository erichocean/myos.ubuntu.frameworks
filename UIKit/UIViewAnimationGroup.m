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
#import <CoreAnimation/CoreAnimation-private.h>

static CAMediaTimingFunction *CAMediaTimingFunctionFromUIViewAnimationCurve(UIViewAnimationCurve curve)
{
    switch (curve) {
        case UIViewAnimationCurveEaseInOut:	return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        case UIViewAnimationCurveEaseIn:	return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        case UIViewAnimationCurveEaseOut:	return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        case UIViewAnimationCurveLinear:	return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    }
    return nil;
}

@implementation UIViewAnimationGroup

#pragma mark - Life cycle

+ (id)animationGroupWithName:(NSString *)theName context:(void *)theContext
{
    return [[[self alloc] initWithGroupName:theName context:theContext] autorelease];
}

- (id)initWithGroupName:(NSString *)theName context:(void *)theContext
{
    //DLog();
    if ((self=[super init])) {
        _name = [theName copy];
        _context = theContext;
        _waitingAnimations = 1;
        _animationCurve = UIViewAnimationCurveEaseInOut;
        _animationBeginsFromCurrentState = NO;
        _animatingViews = [[NSMutableSet alloc] initWithCapacity:0];
        _animationGroup = _CAAnimationGroupNew();
        _animationGroup.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    [_name release];
    [_animationDelegate release];
    [_animatingViews release];
    [_animationGroup release];
    [super dealloc];
}

#pragma mark - Accessors

- (id)actionForView:(UIView *)view forKey:(NSString *)keyPath
{
    [_animatingViews addObject:view];
    CALayer *layer = view.layer;
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:keyPath];
    animation.fromValue = _animationBeginsFromCurrentState? [layer.presentationLayer valueForKey:keyPath] : [layer valueForKey:keyPath];
    return [self addAnimation:animation];
}

- (void)setAnimationBeginsFromCurrentState:(BOOL)beginFromCurrentState
{
    _animationBeginsFromCurrentState = beginFromCurrentState;
}

- (void)setAnimationCurve:(UIViewAnimationCurve)curve
{
    //_animationCurve = curve;
    _animationGroup.timingFunction = CAMediaTimingFunctionFromUIViewAnimationCurve(curve);

}

- (void)setAnimationDelay:(NSTimeInterval)delay
{
    _animationGroup.beginTime = delay;
}

- (void)setAnimationDelegate:(id)delegate
{
    if (delegate != _animationDelegate) {
        [_animationDelegate release];
        _animationDelegate = [delegate retain];
    }
}

- (void)setAnimationDidStopSelector:(SEL)selector
{
    _animationDidStopSelector = selector;
}

- (void)setAnimationDuration:(NSTimeInterval)newDuration
{
    //DLog();
    [_animationGroup setDuration:newDuration];
}

- (void)setAnimationRepeatAutoreverses:(BOOL)repeatAutoreverses
{
    [_animationGroup setAutoreverses:repeatAutoreverses];
}

- (void)setAnimationRepeatCount:(float)repeatCount
{
    //repeatCount = 2.0;
    //DLog(@"self: %@", self);
    //int repeat = 255;
    /*char *repeat = &repeatCount;
    //DLog(@"sizeof(repeat): %d", sizeof(repeat));
    DLog(@"repeat[0]: %d", repeat[0]);
    DLog(@"repeat[1]: %d", repeat[1]);
    DLog(@"repeat[2]: %d", repeat[2]);
    DLog(@"repeat[3]: %d", repeat[3]);*/
    
    /*DLog(@"repeat & intRepeat[0]: %d", repeat & intRepeat[0];
    DLog(@"repeat & intRepeat[1]: %d", repeat & intRepeat[1];
    DLog(@"repeat & intRepeat[2]: %d", repeat & intRepeat[2];
    DLog(@"repeat & intRepeat[3]: %d", repeat & intRepeat[3];
    DLog(@"repeatCount d: %d", (int)repeatCount);
    DLog(@"repeatCount f: %f", repeatCount);
    DLog(@"repeatCount g: %g", repeatCount);*/
    [_animationGroup setRepeatCount:repeatCount];
}

- (void)setAnimationTransition:(UIViewAnimationTransition)transition forView:(UIView *)view cache:(BOOL)cache
{
    _transitionLayer = view.layer;
    _transitionType = transition;
    _transitionShouldCache = cache;
}

- (void)setAnimationWillStartSelector:(SEL)selector
{
    _animationWillStartSelector = selector;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; _animationGroup = %@>", [self className], self, _animationGroup];
}

#pragma mark - Delegates

- (void)animationDidStart:(CAAnimation *)theAnimation
{
    if (!_didSendStartMessage) {
        if ([_animationDelegate respondsToSelector:_animationWillStartSelector]) {
            NSMethodSignature *signature = [_animationDelegate methodSignatureForSelector:_animationWillStartSelector];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setSelector:_animationWillStartSelector];
            NSInteger remaining = [signature numberOfArguments] - 2;
            if (remaining > 0) {
                [invocation setArgument:&_name atIndex:2];
                remaining--;
            }
            if (remaining > 0) {
                [invocation setArgument:&_context atIndex:3];
            }
            [invocation invokeWithTarget:_animationDelegate];
        }
        _didSendStartMessage = YES;
    }
}

- (void)animationDidStop:(CAAnimationGroup *)animationGroup finished:(BOOL)finished
{
    //DLog();
    _waitingAnimations--;
    //[self notifyAnimationsDidStopIfNeededUsingStatus:flag];
    
    //DLog(@"animationDidStop: %d", finished);
    if (_waitingAnimations == 0) {
        if ([_animationDelegate respondsToSelector:_animationDidStopSelector]) {
            NSMethodSignature *signature = [_animationDelegate methodSignatureForSelector:_animationDidStopSelector];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setSelector:_animationDidStopSelector];
            NSInteger remaining = [signature numberOfArguments] - 2;
            NSNumber *finishedArgument = [NSNumber numberWithBool:finished];
            if (remaining > 0) {
                [invocation setArgument:&_name atIndex:2];
                remaining--;
            }
            if (remaining > 0) {
                [invocation setArgument:&finishedArgument atIndex:3];
                remaining--;
            }
            if (remaining > 0) {
                [invocation setArgument:&_context atIndex:4];
            }
            [invocation invokeWithTarget:_animationDelegate];
        }
        [_animatingViews removeAllObjects];
    }
    
    /*UIViewAnimationGroup *viewAnimationGroup = nil;
    for (UIViewAnimationGroup *aViewAnimationGroup in _animationGroups) {
        if (aViewAnimationGroup->_animationGroup == animationGroup) {
            viewAnimationGroup = aViewAnimationGroup;
            break;
        }
    }*/
    //DLog(@"_animationGroups: %@", _animationGroups);
    [_animationGroups removeObject:animationGroup.delegate];
    //DLog(@"_animationGroups2: %@", _animationGroups);
}

#pragma mark - Public methods

- (CAAnimation *)addAnimation:(CAAnimation *)animation
{
    animation.timingFunction = CAMediaTimingFunctionFromUIViewAnimationCurve(_animationCurve);
    animation.duration = [_animationGroup duration];
    animation.beginTime = [_animationGroup beginTime];
    animation.repeatCount = [_animationGroup repeatCount];
    animation.autoreverses = [_animationGroup autoreverses];
    animation.fillMode = kCAFillModeBackwards;
    animation.delegate = self;
    animation.removedOnCompletion = YES;
    _waitingAnimations++;
    DLog(@"animation: %@", animation);
    return animation;
}
/*
- (void)notifyAnimationsDidStopIfNeededUsingStatus:(BOOL)animationsDidFinish
{

}*/

- (void)commit
{
    //DLog();
    if (_transitionLayer) {
        //DLog(@"_transitionLayer: %@", _transitionLayer);
        CATransition *trans = [CATransition animation];
        trans.type = kCATransitionMoveIn;
        switch (_transitionType) {
            case UIViewAnimationTransitionNone:	
                trans.subtype = nil;						
                break;
            case UIViewAnimationTransitionCurlUp:
                trans.subtype = kCATransitionFromTop;
                break;
            case UIViewAnimationTransitionCurlDown:
                trans.subtype = kCATransitionFromBottom;
                break;
            case UIViewAnimationTransitionFlipFromLeft:
                trans.subtype = kCATransitionFromLeft;
                break;
            case UIViewAnimationTransitionFlipFromRight:
                trans.subtype = kCATransitionFromRight;
                break;
        }
        [_transitionLayer addAnimation:[self addAnimation:trans] forKey:kCATransition];
    }
    //[self animationDidStop:nil finished:YES];
    //_waitingAnimations--;
    //[self notifyAnimationsDidStopIfNeededUsingStatus:YES];
    _CAAnimationGroupCommit();
}

@end

#pragma mark - shared functions

UIViewAnimationGroup *UIViewAnimationGroupGetCurrent()
{
    //DLog();
    for (UIViewAnimationGroup *viewAnimationGroup in [_animationGroups reverseObjectEnumerator]) {
        if (!viewAnimationGroup->_animationGroup->_committed) {
            return viewAnimationGroup;
        }
    }
    /*
     int arrayCount = CFArrayGetCount(_animationGroups);
     if (arrayCount) {
     return CFArrayGetValueAtIndex(_animationGroups, arrayCount-1);
     }*/
    return nil;
}
