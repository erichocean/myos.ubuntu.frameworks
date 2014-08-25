/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import "CAMediaTiming.h"

@class CAMediaTimingFunction;

@interface CAAnimation : NSObject <CAMediaTiming, CAAction>
{
@package
    id delegate;
    CAMediaTimingFunction *timingFunction;
    BOOL removedOnCompletion;
    CFTimeInterval _startTime;
    CFTimeInterval beginTime;
    CFTimeInterval timeOffset;
    CFTimeInterval duration;
    float repeatCount;
    CFTimeInterval repeatDuration;
    BOOL autoreverses;
    NSString *fillMode;
    float speed;
    BOOL _remove;
}

+ (id)animation;

@property (retain) id delegate;
@property (retain) CAMediaTimingFunction *timingFunction;
@property BOOL removedOnCompletion;

@end

@interface CAPropertyAnimation : CAAnimation
{
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

@interface CABasicAnimation : CAPropertyAnimation
{
@package
    id fromValue;
    id toValue;
    id byValue;
}

@property(retain) id fromValue;
@property(retain) id toValue;
@property(retain) id byValue;

@end

@interface CAKeyframeAnimation : CAPropertyAnimation
{
@package
    NSString *calculationMode;
    NSArray *values;
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

@interface CATransition : CAAnimation
{
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

@interface CAAnimationGroup : CAAnimation
{
@package
    NSMutableArray *animations;
    BOOL _committed;
}

@property(copy) NSArray *animations;

@end
