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

#import <CoreAnimation/CAMediaTiming.h>

@class CAMediaTimingFunction, CAAnimationGroup;

@interface CAAnimation : NSObject <CAMediaTiming, CAAction> {
@package
    id _delegate;
    CAMediaTimingFunction *_timingFunction;
    BOOL _removedOnCompletion;
    CFTimeInterval _startTime;
    CFTimeInterval _beginTime;
    CFTimeInterval _timeOffset;
    CFTimeInterval _duration;
    float _repeatCount;
    CFTimeInterval _repeatDuration;
    BOOL _autoreverses;
    NSString *_fillMode;
    float _speed;
    BOOL _remove;
    CAAnimationGroup *_animationGroup;
}

@property (retain) id delegate;
@property (retain) CAMediaTimingFunction *timingFunction;
@property BOOL removedOnCompletion;

+ (id)animation;

@end

@protocol CAAnimationDelegate <NSObject>
@optional
- (void)animationDidStart:(CAAnimation *)animation;
- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)finished;

@end

@interface CAPropertyAnimation : CAAnimation {
@package
    NSString *keyPath;
    BOOL additive;
    BOOL cumulative;
}

+ (id)animationWithKeyPath:(NSString *)path;

@property (copy) NSString *keyPath;
@property (getter=isAdditive) BOOL additive;
@property (getter=isCumulative) BOOL cumulative;

@end

@interface CABasicAnimation : CAPropertyAnimation {
@package
    id fromValue;
    id toValue;
    id byValue;
}

@property(retain) id fromValue;
@property(retain) id toValue;
@property(retain) id byValue;

@end

@interface CAKeyframeAnimation : CAPropertyAnimation {
@package
    NSString *_calculationMode;
    NSArray *_values;
}

@property(copy) NSString *calculationMode;
@property(copy) NSArray *values;

@end

/* calculationMode constants */
extern NSString *const kCAAnimationDiscrete;

/* transition types */
extern NSString *const kCATransitionMoveIn;

/* transition subtypes */
extern NSString *const kCATransitionFromTop;
extern NSString *const kCATransitionFromBottom;
extern NSString *const kCATransitionFromLeft;
extern NSString *const kCATransitionFromRight;

@interface CATransition : CAAnimation {
@package
    NSString *type;
    NSString *subtype;
    float startProgress;
    float endProgress;
}

@property(copy) NSString *type;
@property(copy) NSString *subtype;
@property float startProgress;
@property float endProgress;

@end

@interface CAAnimationGroup : CAAnimation {
@public
    NSMutableArray *_animations;
    BOOL _committed;
}

@property(copy) NSArray *animations;

@end
