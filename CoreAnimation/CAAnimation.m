/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <CoreAnimation/CoreAnimation-private.h>

NSString *const kCAAnimationDiscrete = @"CAAnimationDiscrete";

/* transition types */
NSString *const kCATransitionMoveIn = @"CATransitionMoveIn";

/* transition subtypes */
NSString *const kCATransitionFromTop = @"CATransitionFromTop";
NSString *const kCATransitionFromBottom = @"CATransitionFromBotton";
NSString *const kCATransitionFromLeft = @"CATransitionFromLeft";
NSString *const kCATransitionFromRight = @"CATransitionFromRight";

static NSMutableArray *_animationGroups = nil;

#define _kSmallTimeMargin 0.1

#pragma mark - Static C functions

static CFTimeInterval _CAAnimationGetProgressTime(CABasicAnimation *animation, CFTimeInterval time)
{
    CFTimeInterval localTime = (time - animation->beginTime) * animation->speed + animation->timeOffset;
    CFTimeInterval activeTime = localTime - animation->_startTime;
    //DLog(@"activeTime: %0.1f", activeTime);
    if (activeTime < 0) {
        return activeTime;
    }
    int k = floor(activeTime/animation->duration);
    CFTimeInterval progressTime = activeTime - k * animation->duration;
    if (animation->autoreverses && k % 2 == 1) {
        progressTime = animation->duration - progressTime;
    }
    if (animation->removedOnCompletion) {
        if (k-1 > animation->repeatCount || activeTime - animation->duration > animation->repeatDuration) {
            if (k % 2 == 1) {
                progressTime = animation->duration;
            } else {
                progressTime = 0;
            }
            animation->_remove = YES;
        }
    }
    //DLog(@"progressTime: %0.1f", progressTime);
    return progressTime;
}

static float _CAAnimationGetProgress(CABasicAnimation *animation, CFTimeInterval progressTime)
{
    if (progressTime < 0) {
        return 0;
    }
    float timeRatio = progressTime / animation->duration;
    //DLog(@"timeRatio: %0.2f", timeRatio);
    return _CAMediaTimingFunctionApply(animation->timingFunction, timeRatio);
}

static id _CAAnimationGetAnimatedFloatValue(CABasicAnimation *animation, float progress)
{
    //DLog(@"animation: %@", animation);
    float fromValue = [animation->fromValue floatValue];
    float toValue = [animation->toValue floatValue];
    float result = fromValue + (toValue - fromValue) * progress;
    return [NSNumber numberWithFloat:result];
}

static id _CAAnimationGetAnimatedPointValue(CABasicAnimation *animation, float progress)
{
    CGPoint fromPoint = [animation->fromValue CGPointValue];
    CGPoint toPoint = [animation->toValue CGPointValue];
    //DLog(@"toPoint: %@", NSStringFromCGPoint(toPoint));

    float resultX =  fromPoint.x + (toPoint.x - fromPoint.x) * progress;
    float resultY = fromPoint.y + (toPoint.y - fromPoint.y) * progress;
    CGPoint result = CGPointMake(resultX, resultY);
    return [NSValue valueWithCGPoint:result];
    //return [NSValue valueWithBytes:&result objCType:@encode(CGPoint)];
}

static id _CAAnimationGetAnimatedRectValue(CABasicAnimation *animation, float progress)
{
    CGRect fromRect = [animation->fromValue CGRectValue];
    CGRect toRect = [animation->toValue CGRectValue];
    float resultX =  fromRect.origin.x + (toRect.origin.x - fromRect.origin.x) * progress;
    float resultY = fromRect.origin.y + (toRect.origin.y - fromRect.origin.y) * progress;
    float resultWidth =  fromRect.size.width + (toRect.size.width - fromRect.size.width) * progress;
    float resultHeight = fromRect.size.height + (toRect.size.height - fromRect.size.height) * progress;
    CGRect result = CGRectMake(resultX, resultY, resultWidth, resultHeight);
    return [NSValue valueWithCGRect:result];
    //return [NSValue valueWithBytes:&result objCType:@encode(CGRect)];
}

static id _CAAnimationGetAnimatedColorValue(CABasicAnimation *animation, float progress)
{
    CGColorRef fromColor = animation->fromValue;
    CGColorRef toColor = animation->toValue;
    
    const CGFloat *fromComponents = CGColorGetComponents(fromColor);
    const CGFloat *toComponents = CGColorGetComponents(toColor);
    
    int numberOfComponents = CGColorGetNumberOfComponents(fromColor);
    float resultComponents[4] = {0,0,0,1};
    for (int i=0; i<numberOfComponents; i++) {
        resultComponents[i] =  fromComponents[i] + (toComponents[i] - fromComponents[i]) * progress;
    }
    return [(id)CGColorCreate(CGColorGetColorSpace(fromColor), resultComponents) autorelease];
}

@implementation CAAnimation

@synthesize delegate;
@synthesize timingFunction;
@synthesize removedOnCompletion;
@synthesize beginTime;
@synthesize timeOffset;
@synthesize duration;
@synthesize repeatCount;
@synthesize repeatDuration;
@synthesize autoreverses;
@synthesize fillMode;
@synthesize speed;

#pragma mark - Life cycle

+ (id)animation
{
    return [[[self alloc] init] autorelease];
}

- (id)init
{
    self = [super init];
    if (self) {
        beginTime = 0;
        _startTime = 0;
        duration = (CFTimeInterval)[(NSNumber *)[CATransaction valueForKey:kCATransactionAnimationDuration] doubleValue];
        timingFunction = [CATransaction valueForKey:kCATransactionAnimationTimingFunction] ? :
                        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
        [timingFunction retain];
        repeatCount = 0;
        repeatDuration = 0;
        autoreverses = NO;
        removedOnCompletion = YES;
        _remove = NO;
        fillMode = nil;
        speed = 1;
        timeOffset = 0;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[self class] allocWithZone:zone];
    if (copy) {
        static NSString *keys[] = {@"delegate", @"removedOnCompletion", @"timingFunction", @"duration", 
                                   @"speed", @"autoreverses", @"repeatCount"};
        for (int i=0; i<7; i++) {
            id value = [self valueForKey:keys[i]];
            if (value) {
                [copy setValue:value forKey:keys[i]];
            }
        }
    }
    return copy;
}

- (void)dealloc
{
    [delegate release];
    [timingFunction release];
    [super dealloc];
}

#pragma mark - Accessors

- (NSString *)description
{
    //return [NSString stringWithFormat:@"<%@: %p; beginTime: %0.1f; duration: %0.1f>", [self className], self, beginTime, duration];
    return [NSString stringWithFormat:@"<%@: %p; beginTime: %0.1f, duration: %0.1f>", [self className], self, beginTime, duration];
    //return [NSString stringWithFormat:@"<%@: %p; timingFunction: %@>", [self className], self, timingFunction];
    //return [NSString stringWithFormat:@"<%@: %p>", [self className], self];
}

#pragma mark - CAMediaTiming
/*
- (CFTimeInterval)beginTime
{
    return beginTime;
}

- (void)setBeginTime:(CFTimeInterval)theBeginTime
{
    beginTime = theBeginTime;
}

- (CFTimeInterval)duration
{
    return duration;
}

- (void)setDuration:(CFTimeInterval)theDuration
{
    duration = theDuration;
}

- (float)repeatCount
{
    return repeatCount;
}

- (void)setRepeatCount:(float)theRepeatCount
{
    repeatCount = theRepeatCount;
}

- (CFTimeInterval)repeatDuration
{
    return repeatDuration;
}

- (void)setRepeatDuration:(CFTimeInterval)theRepeatDuration
{
    repeatDuration = theRepeatDuration;
}

- (BOOL)autoreverses
{
    return autoreverses;
}

- (void)setAutoreverses:(BOOL)flag
{
    autoreverses = flag;
}

- (NSString *)fillMode
{
    return fillMode;
}

- (void)setFillMode:(NSString *)theFillMode
{
    fillMode = theFillMode;
}

- (float)speed
{
    return speed;
}

- (void)setSpeed:(float)theSpeed
{
    speed = theSpeed;
}

- (CFTimeInterval)timeOffset
{
    return timeOffset;
}

- (void)setTimeOffset:(CFTimeInterval)theTimeOffset
{
    timeOffset = theTimeOffset;
}
*/
#pragma mark - CAAction

- (void)runActionForKey:(NSString *)key object:(id)anObject arguments:(NSDictionary *)dict
{
    [(CALayer *)anObject addAnimation:self forKey:key];
}

@end

@implementation CAPropertyAnimation

@synthesize keyPath;
@synthesize additive;
@synthesize cumulative;

#pragma mark - Life cycle

- (id)initWithKeyPath:(NSString *)aKeyPath
{
    self = [super init];
    if (self) {
        keyPath = [aKeyPath copy];
    }
    return self;
}

+ (id)animationWithKeyPath:(NSString *)path
{
    return [[[self alloc] initWithKeyPath:path] autorelease];
}

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [super copyWithZone:zone];
    if (copy) {
        static NSString *keys[] = {@"additive", @"cumulative", @"keyPath"};
        for (int i=0; i<3; i++) {
            id value = [self valueForKey:keys[i]];
            if (value) {
                [copy setValue:value forKey:keys[i]];
            }
        }
    }
    return copy;
}

- (void)dealloc
{
    [keyPath release];
    [super dealloc];
}

@end

@implementation CABasicAnimation

@synthesize fromValue;
@synthesize toValue;
@synthesize byValue;

#pragma mark - Life cycle

- (void)dealloc
{
    [fromValue release];
    [toValue release];
    [byValue release];
    [super dealloc];
}

#pragma mark - Accessors

- (NSString *)description
{
    //return [NSString stringWithFormat:@"<%@: %p; duration: %0.1f; fromValue: %@; toValue: %@>", [self className], self, duration, fromValue, toValue];
    //return [NSString stringWithFormat:@"<%@: %p; beginTime: %f>", [self className], self, _beginTime];
    //return [NSString stringWithFormat:@"<%@: %p; timingFunction: %@>", [self className], self, timingFunction];
    return [super description];
}

@end

@implementation CAKeyframeAnimation

@synthesize calculationMode;
@synthesize values;

#pragma mark - Life cycle

- (void)dealloc
{
    [calculationMode release];
    [values release];
    [super dealloc];
}

@end

@implementation CATransition

@synthesize type;
@synthesize subtype;
@synthesize startProgress;
@synthesize endProgress;

#pragma mark - Life cycle

- (void)dealloc
{
    [type release];
    [subtype release];
    [super dealloc];
}

@end

@implementation CAAnimationGroup

@synthesize animations;

#pragma mark - Life cycle

- (id)init
{
    self = [super init];
    if (self) {
        animations = CFArrayCreateMutable(kCFAllocatorDefault, 5, &kCFTypeArrayCallBacks);
        //_committed = NO;
    }
    return self;
}

- (void)dealloc
{
    [animations release];
    [super dealloc];
}

@end

#pragma mark - Private C functions 
#pragma mark - C - Life cycle

void _CAAnimationInitialize()
{
    _animationGroups = CFArrayCreateMutable(kCFAllocatorDefault, 2, &kCFTypeArrayCallBacks);
}

#pragma mark - C - Animation

void _CAAnimationApplyAnimationForLayer(CAAnimation *theAnimation, CALayer *layer, CFTimeInterval time)
{
    if (![theAnimation isKindOfClass:[CABasicAnimation class]]) {
        return;
    }
    CABasicAnimation *animation = (CABasicAnimation *)theAnimation;
    CFTimeInterval progressTime = _CAAnimationGetProgressTime(animation, time);
    //if (progressTime < 0) {
    //    return;
    //}
    id result = nil;
    float progress = _CAAnimationGetProgress(animation, progressTime);
    id localValue = [layer valueForKeyPath:animation->keyPath];
    if ([localValue isKindOfClass:[NSNumber class]]) {
        result = _CAAnimationGetAnimatedFloatValue(animation, progress);
    } else if ([localValue isKindOfClass:[NSValue class]]) {
        if (strcmp([localValue objCType], @encode(CGPoint)) == 0) {
            result = _CAAnimationGetAnimatedPointValue(animation, progress);
        } else if (strcmp([localValue objCType], @encode(CGRect)) == 0) {
            result = _CAAnimationGetAnimatedRectValue(animation, progress);
        }
    } else if ([localValue isKindOfClass:NSClassFromString(@"CGColor")]) {
        result = _CAAnimationGetAnimatedColorValue(animation, progress);
    }
    if (result) {
        [layer setValue:result forKeyPath:animation->keyPath];
    }
    //DLog(@"animation: %@", animation);
    if ([animation->keyPath isEqualToString:@"contents"]) {
        layer->_contentsTransitionProgress = progress;
        if (animation->_remove) {
            layer->_contentsTransitionProgress = 1.0;
        }
    }
    if (animation->_remove) {
        //DLog(@"animation1: %@", animation);
        [layer removeAnimationForKey:animation->keyPath];
        //DLog(@"animation2: %@", animation);
    }
}

#pragma mark - C - Animation groups

CAAnimationGroup *_CAAnimationNewAnimationGroup()
{
    //DLog();
    CAAnimationGroup *animationGroup = [[[CAAnimationGroup alloc] init] autorelease];
    CFArrayAppendValue(_animationGroups, animationGroup);
    return animationGroup;
}

CAAnimationGroup *_CAAnimationCurrentAnimationGroup()
{
    int arrayCount = CFArrayGetCount(_animationGroups);
    if (arrayCount) {
        return CFArrayGetValueAtIndex(_animationGroups, arrayCount-1);
    }
    return nil;
}

void _CAAnimationCommitAnimationGroup()
{
    CAAnimationGroup *animationGroup = _CAAnimationCurrentAnimationGroup();
    if (animationGroup) {
        [_animationGroups removeObject:animationGroup];
        //animationGroup->_committed = YES;
    }
}

void _CAAnimationAddToAnimationGroup(CAAnimation *animation)
{
    CAAnimationGroup *animationGroup = _CAAnimationCurrentAnimationGroup();
    CFArrayAppendValue((CFMutableArrayRef)animationGroup->animations, animation);
}

#pragma mark - C - Helpers

void _CAAnimationCopy(CAAnimation *toAnimation, CAAnimation *fromAnimation)
{
    toAnimation->beginTime = fromAnimation->beginTime;
    toAnimation.timingFunction = fromAnimation.timingFunction;
    //DLog(@"toAnimation.timingFunction: %@", toAnimation.timingFunction);
    toAnimation->duration = fromAnimation->duration;
    toAnimation->repeatCount = fromAnimation->repeatCount;
    toAnimation->autoreverses = fromAnimation->autoreverses;
    toAnimation->fillMode = fromAnimation->fillMode;
}
