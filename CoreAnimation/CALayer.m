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

#import <CoreAnimation/CoreAnimation-private.h>
#import <CoreFoundation/CoreFoundation-private.h>

NSString *const kCAGravityResize = @"CAGravityResize";
NSString *const kCAGravityResizeAspect = @"CAGravityResizeAspect";
NSString *const kCAGravityResizeAspectFill = @"CAGravityResizeAspectFill";
NSString *const kCAGravityCenter = @"CAGravityCenter";
NSString *const kCAGravityTop = @"CAGravityTop";
NSString *const kCAGravityBottom = @"CAGravityBottom";
NSString *const kCAGravityLeft = @"CAGravityLeft";
NSString *const kCAGravityRight = @"CAGravityRight";
NSString *const kCAGravityTopLeft = @"CAGravityTopLeft";
NSString *const kCAGravityTopRight = @"CAGravityTopRight";
NSString *const kCAGravityBottomLeft = @"CAGravityBottomLeft";
NSString *const kCAGravityBottomRight = @"CAGravityBottomRight";
NSString *const kCATransition = @"CATransition";

static NSString *const _kCAStyle = @"style";
static NSArray *_CALayerAnimatableKeys = nil;
static NSMutableDictionary *_needDisplayKeys;

#pragma mark - Static functions

static NSString *_NSStringFromCGPoint(CGPoint p)
{
    return NSStringFromPoint(NSPointFromCGPoint(p));
}

@implementation CALayer

@synthesize delegate;
@synthesize cornerRadius=_cornerRadius;
@synthesize borderWidth=_borderWidth;
@synthesize borderColor=_borderColor;
@synthesize contentsRect=_contentsRect;
@synthesize contentsCenter=_contentsCenter;
@synthesize contentsGravity=_contentsGravity;
@synthesize needsDisplayOnBoundsChange=_needsDisplayOnBoundsChange;
@synthesize actions=_actions;
@synthesize style=_style;

#pragma mark - Life cycle

+ (void)initialize
{
    if (self == [CALayer class]) {
        _rootLayers = CFArrayCreateMutable(kCFAllocatorDefault, 5, &kCFTypeArrayCallBacks);
        //DLog(@"_rootLayers: %@", _rootLayers);
        _CALayerAnimatableKeys = [[NSArray alloc] initWithObjects:@"position", @"opacity", @"bounds", @"anchorPoint", @"contentsRect", @"contents", @"contentsScale", @"contentCenter", @"backgroundColor", @"cornerRadius", @"borderWidth", @"borderColor", @"shadowColor", @"shadowOpacity", @"shadowOffset", @"shadowRadius", nil];
        _needDisplayKeys = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                               @"YES", @"contents",
                               @"YES", @"backgroundColor",
                               @"YES", @"cornerRadius",
                               @"YES", @"borderWidth",
                               @"YES", @"borderColor",
                               @"YES", @"shadowColor",
                               @"YES", @"shadowOpacity",
                               @"YES", @"shadowOffset",
                               @"YES", @"shadowRadius",
                               @"YES", @"contentsScale", nil];
        _CATransactionInitialize();
        _CALayerObserverInitialize();
        //DLog(@"[NSThread currentThread]: %@", [NSThread currentThread]);
    }
}

+ (id)layer 
{
    return [[[self alloc] initWithBounds:CGRectZero] autorelease];
}

- (id)init
{
    self = [super init];
    if (self) {
        _sublayers = CFArrayCreateMutable(kCFAllocatorDefault, 20, &kCFTypeArrayCallBacks);
        if (![self isKindOfClass:[CARenderLayer class]]) {
            CALayerObserver *layerObserver = _CALayerObserverGetSharedObserver();
            for (NSString *key in _CALayerAnimatableKeys) {
                [self addObserver:layerObserver forKeyPath:key options:NSKeyValueObservingOptionPrior context:nil]; 
            }
        }
    }
    return self;
}

- (id)initWithLayer:(CALayer *)layer
{
    self = [self init];
    if (self) {
        _animations = nil;
        _CALayerCopy(self, layer);
    }
    return self;
}

- (id)initWithBounds:(CGRect)theBounds
{
    self = [self init];
    if (self) {
        _modelLayer = self;
        _bounds = theBounds;
        _contentsScale = 1.0;
        //DLog(@"_contentsScale: %0.2f", _contentsScale);
        _CALayerSetNeedsLayout(self);
        //_needsLayout = YES;
        _needsDisplay = YES;
        _needsComposite = YES;
        _position = CGPointZero;
        _anchorPoint = CGPointMake(0.5, 0.5);
        _opacity = 1.0;
        _shadowOpacity = 0;
        _shadowOffset = CGSizeMake(0, 3);
        _shadowRadius = 3;
        _shadowPath = NULL;
        _opaque = NO;
        _masksToBounds = NO;
        _oldContents = nil;
        _contents = nil;
        //DLog(@"_contentsWasSet: %d", _contentsWasSet);
        //_contentsWasSet = NO;
        _displayContents = nil;
        _keyframesContents = nil;
        _contentsRect = CGRectMake(0.0, 0.0, 1.0, 1.0);
        _animations = [[NSMutableDictionary alloc] initWithCapacity:10];//CFDictionaryCreateMutable(kCFAllocatorDefault, 10, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        _actions = CFDictionaryCreateMutable(kCFAllocatorDefault, 10, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        _style = CFDictionaryCreateMutable(kCFAllocatorDefault, 10, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        _presentationLayer = [[[self class] alloc] initWithModelLayer:self];
        _renderLayer = [[CARenderLayer alloc] init];//WithPresentationLayer:_presentationLayer];
        _presentationLayer->_renderLayer = [_renderLayer retain];
        _CALayerSetNeedsDisplay(self);
        _backgroundColor = nil;
        _needsUnload = NO;
        _contentsTransitionProgress = 1.0;
        _keyframesProgress = -1;
        _beginTime = 0;
        _duration = 0;
        _repeatCount = 0;
        _repeatDuration = 0;
        _autoreverses = NO;
        _fillMode = nil;
        _speed = 1;
        _timeOffset = 0;
    }
    return self;
}

- (void)dealloc
{
    //DLog(@"self: %@", self);
    [_presentationLayer release];
    //DLog(@"_renderLayer: %@, _renderLayer.retainCount: %d", _renderLayer, _renderLayer.retainCount);
    [_renderLayer release];
    [_contentsGravity release];
    if (_actions) {
        CFRelease(_actions);
    }
    //DLog();
    [_animations release];
    //DLog();
    if (_actions) {
        CFRelease(_style);
    }
    //DLog();
    CFRelease(_sublayers);
    //DLog();
    CGColorRelease(_backgroundColor);
    //DLog();
    CGColorRelease(_shadowColor);
    [_oldContents release];
    [_contents release];
    [_keyframesContents release];
    [_fillMode release];
    //DLog();
    CGImageRelease(_displayContents);
    //DLog();
    CALayerObserver *layerObserver = _CALayerObserverGetSharedObserver();
    for (NSString *key in _CALayerAnimatableKeys) {
        [self removeObserver:layerObserver forKeyPath:key]; 
    }
    [super dealloc];
}

#pragma mark - Class methods

+ (id)defaultValueForKey:(NSString *)key
{
    if ([key isEqualToString:@"anchorPoint"]) {
        return [NSValue valueWithCGPoint:CGPointMake(0.5,0.5)];
    } else if ([key isEqualToString:@"shouldRasterize"]) {
        return [NSNumber numberWithBool:NO];
    } else if ([key isEqualToString:@"opacity"]) {
        return [NSNumber numberWithFloat:1.0];
    } else if ([key isEqualToString:@"contentsRect"]) {
        return [NSValue valueWithCGRect:CGRectMake(0,0,1.0,1.0)];
    } else if ([key isEqualToString:@"shadowColor"]) {
        return [(id)CGColorCreateGenericRGB(0,0,0,1.0) autorelease];
    } else if ([key isEqualToString:@"shadowOffset"]) {
        return [NSValue valueWithCGSize:CGSizeMake(0,-3.0)];
    } else if ([key isEqualToString:@"shadowRadius"]) {
        return [NSNumber numberWithFloat:3.0];
    } else if ([key isEqualToString:@"backgroundColor"]) {
        return [CGColorCreateGenericRGB(0,0,0,0) autorelease];
    }
    return nil;
}

+ (BOOL)needsDisplayForKey:(NSString *)key
{
    if ([_needDisplayKeys objectForKey:key]) {
        return YES;
    }
    return NO;
}

#pragma mark - Accessors

- (BOOL)isOpaque
{
    return _opaque;
}

- (void)setOpaque:(BOOL)newValue
{
    _opaque = newValue;
    _CALayerSetNeedsComposite(self);
}

- (BOOL)isGeometryFlipped
{
    return _geometryFlipped;
}

- (void)setGeometryFlipped:(BOOL)newValue
{
    _geometryFlipped = newValue;
}

- (BOOL)isHidden
{
    return _hidden;
}

- (void)setHidden:(BOOL)newValue
{
    //DLog(@"self: %@", self);
    BOOL oldValue = _hidden;
    _hidden = newValue;
    if (newValue == YES) {
        //DLog(@"newValue == YES");
        self.opacity = 0;
        //_CALayerSetNeedsUnload(self);
        /*if (_superlayer == nil || _superlayer->_superlayer == nil) {
            _CALayerSetNeedsUnload(self);
        }*/
    } else {
        self.opacity = 1;
        /*if (oldValue && (_superlayer == nil || _superlayer->_superlayer == nil)) {
            //DLog(@"_hidden && (_superlayer== nil || _superlayer->_superlayer == nil)");
            _CALayerSetNeedsDisplayWithRoot(self);
        } else {*/
        _CALayerSetNeedsComposite(self);
        //}
    }
}

- (id)presentationLayer
{
    if (_modelLayer == self) {
        CALayer *result = [[[[self class] alloc] initWithModelLayer:self] autorelease];
        _CALayerApplyAnimations(result);
        return result;
    } else {
        return self;
    }
}

- (id)modelLayer
{
    return _modelLayer;
}

- (CALayer *)superlayer
{
    if (_modelLayer == self) {
        return _superlayer;
    } else {
        return [_modelLayer->_superlayer presentationLayer];
    }
}

- (NSArray *)sublayers
{
    if (_modelLayer == self) {
        return CFArrayCreateMutableCopy(kCFAllocatorDefault, 10, _sublayers);
    } else {
      CFMutableArrayRef subPresentationLayers = CFArrayCreateMutable(kCFAllocatorDefault, 20, &kCFTypeArrayCallBacks);
      for (CALayer *modelSubLayer in _modelLayer->_sublayers) {
          CFArrayAppendValue(subPresentationLayers, [modelSubLayer presentationLayer]);
      }
      return subPresentationLayers;
    }
}

- (void)setSublayers:(NSArray *)theSublayers
{
    if (_modelLayer == self) {
        if (_sublayers) {
            CFRelease(_sublayers);
        }
        _sublayers = CFArrayCreateMutableCopy(kCFAllocatorDefault, 10, theSublayers);
    }
}

- (id)contents
{
    return _contents;
}

- (void)setContents:(id)newContents
{
    //DLog(@"newContents: %@", newContents);
    [self willChangeValueForKey:@"contents"];
    //if (_bounds.size.height > 500) {
        //DLog(@"_contents: %@", _contents);
    //}
    [_contents release];
    _contents = [newContents retain];
    //_contentsWasSet = NO;
    [self didChangeValueForKey:@"contents"];
}

- (float)opacity
{
    return _opacity;
}

- (void)setOpacity:(float)newOpacity
{
    [self willChangeValueForKey:@"opacity"];
    _opacity = newOpacity;
    [self didChangeValueForKey:@"opacity"];
    if (_opacity < 1.0) {
        _opaque = NO;
    }
}

- (CGColorRef)backgroundColor
{
    return _backgroundColor;
}

- (void)setBackgroundColor:(CGColorRef)newBackgroundColor
{
    [self willChangeValueForKey:@"backgroundColor"];
    CGColorRelease(_backgroundColor);
    _backgroundColor = CGColorRetain(newBackgroundColor);
    [self didChangeValueForKey:@"backgroundColor"];
}

- (CGPoint)position
{
    return _position;
}

- (void)setPosition:(CGPoint)newPosition
{
    [self willChangeValueForKey:@"position"];
    _position = newPosition;
    //DLog(@"self: %@, newPosition: %@", self, _NSStringFromCGPoint(newPosition));
    if (_superlayer) {
        //DLog(@"self: %@", self);
        _CALayerSetNeedsLayout(_superlayer);
    }
    [self didChangeValueForKey:@"position"];
}

- (CGFloat)zPosition
{
    return _zPosition;
}

- (void)setZPosition:(CGFloat)newZPosition
{
    _zPosition = newZPosition;
    _CALayerSetNeedsComposite(self);
}

- (CGRect)bounds
{
    return _bounds;
}

- (void)setBounds:(CGRect)newBounds
{
    //DLog(@"self: %@", self);
    [self willChangeValueForKey:@"bounds"];
    _bounds = newBounds;
    [self didChangeValueForKey:@"bounds"];
    //DLog(@"self: %@", self);
    _CALayerSetNeedsLayout(self);
    if (_needsDisplayOnBoundsChange) {
        _CALayerSetNeedsDisplay(self);
    }
}

- (CGPoint)anchorPoint
{
    return _anchorPoint;
}

- (void)setAnchorPoint:(CGPoint)newAnchorPoint
{
    [self willChangeValueForKey:@"anchorPoint"];
    _anchorPoint = newAnchorPoint;
    [self didChangeValueForKey:@"anchorPoint"];
}

- (CGRect)frame
{
    return CGRectMake(_position.x - _bounds.size.width * _anchorPoint.x,
                      _position.y - _bounds.size.height * (1 - _anchorPoint.y),
                      _bounds.size.width, _bounds.size.height);
}

- (void)setFrame:(CGRect)newFrame
{
    [self setPosition:CGPointMake(newFrame.origin.x + newFrame.size.width * _anchorPoint.x,
                                  newFrame.origin.y + newFrame.size.height * (1 - _anchorPoint.y))];
    [self setBounds:CGRectMake(0, 0, newFrame.size.width, newFrame.size.height)];
}

- (CGColorRef)shadowColor
{
    return _shadowColor;
}

- (void)setShadowColor:(CGColorRef)aColor
{
    //DLog(@"self: %@", self);
    [self willChangeValueForKey:@"shadowColor"];
    CGColorRelease(_shadowColor);
    _shadowColor = CGColorRetain(aColor);
    [self didChangeValueForKey:@"shadowColor"];
    _CALayerSetNeedsDisplay(self);
}

- (CGFloat)shadowOpacity
{
    return _shadowOpacity;
}

- (void)setShadowOpacity:(CGFloat)anOpacity
{
    //DLog(@"self: %@", self);
    _shadowOpacity = anOpacity;
    _CALayerSetNeedsDisplay(self);
}

- (CGSize)shadowOffset
{
    return _shadowOffset;
}
 
- (void)setShadowOffset:(CGSize)anOffset
{
    _shadowOffset = CGSizeMake(anOffset.width, -anOffset.height); // to keep with the standard of Apple that -3 means going down
    _CALayerSetNeedsDisplay(self);
}

- (BOOL)masksToBounds
{
    return _masksToBounds;
}

- (void)setMasksToBounds:(BOOL)newValue
{
    //DLog(@"self: %@", self);
    _masksToBounds = newValue;
    _CALayerSetNeedsDisplay(self);
}

- (CGFloat)shadowRadius
{
    return _shadowRadius;
}

- (void)setShadowRadius:(CGFloat)aRadius
{
    //DLog(@"self: %@", self);
    _shadowRadius = aRadius;
    _CALayerSetNeedsDisplay(self);
}

- (CGPathRef)shadowPath
{
    return _shadowPath;
}

- (void)setShadowPath:(CGPathRef)aPath
{
    //DLog(@"self: %@", self);
    _shadowPath = aPath;
    _CALayerSetNeedsDisplay(self);
}

- (CGAffineTransform)affineTransform
{
    return CATransform3DGetAffineTransform(_transform);
}

- (void)setAffineTransform:(CGAffineTransform)m
{
    //DLog(@"self: %@", self);
    _transform = CATransform3DMakeAffineTransform(m);
    _CALayerSetNeedsDisplay(self);
}

- (NSString *)description
{
    //return [NSString stringWithFormat:@"<%@: %p; frame:%@; _animations:%@>", [self className], self, NSStringFromRect(NSRectFromCGRect(self.frame)), _animations];
    return [NSString stringWithFormat:@"<%@: %p; frame:%@>", [self className], self, NSStringFromRect(NSRectFromCGRect(self.frame))];
}

#pragma mark - Layout

- (BOOL)needsLayout
{
    return _needsLayout;
}

- (void)setNeedsLayout
{
    //DLog(@"self: %@", self);
    _CALayerSetNeedsLayout(self);
}

- (void)layoutIfNeeded
{
    if (_needsLayout) {
        //DLog(@"self: %@", self);
        if ([delegate respondsToSelector:@selector(layoutSublayersOfLayer:)]) {
            [delegate layoutSublayersOfLayer:self];
        } else if ([_layoutManager respondsToSelector:@selector(layoutSublayersOfLayer:)]) {
            [_layoutManager layoutSublayersOfLayer:self];
        }
        _needsLayout = NO;
    }
}

#pragma mark - Display

- (BOOL)needsDisplay
{
    return _needsDisplay;
}

- (void)setNeedsDisplay
{
    DLog(@"self: %@", self);
    _CALayerSetNeedsDisplay(self);
}

// display here means draw
- (void)setNeedsDisplayInRect:(CGRect)r
{
    //DLog(@"self: %@", self);
    _CALayerSetNeedsDisplay(self);
}

- (void)displayIfNeeded
{
    _CALayerDisplayIfNeeded(self);
}

- (void)display
{
    _CALayerDisplay(self);
}

- (void)drawInContext:(CGContextRef)ctx
{
    if ([delegate respondsToSelector:@selector(drawLayer:inContext:)]) {
        [delegate drawLayer:self inContext:ctx];
    }
}

#pragma mark - CAMediaTiming

- (CFTimeInterval)beginTime
{
    return _beginTime;
}

- (void)setBeginTime:(CFTimeInterval)theBeginTime
{
    _beginTime = theBeginTime;
    _CALayerSetNeedsComposite(self);
}

- (CFTimeInterval)duration
{
    return _duration;
}

- (void)setDuration:(CFTimeInterval)theDuration
{
    _duration = theDuration;
    _CALayerSetNeedsComposite(self);
}

- (float)repeatCount
{
    return _repeatCount;
}

- (void)setRepeatCount:(float)theRepeatCount
{
    _repeatCount = theRepeatCount;
    _CALayerSetNeedsComposite(self);
}

- (CFTimeInterval)repeatDuration
{
    return _repeatDuration;
}

- (void)setRepeatDuration:(CFTimeInterval)theRepeatDuration
{
    _repeatDuration = theRepeatDuration;
    _CALayerSetNeedsComposite(self);
}

- (BOOL)autoreverses
{
    return _autoreverses;
}

- (void)setAutoreverses:(BOOL)flag
{
    _autoreverses = flag;
    _CALayerSetNeedsComposite(self);
}

- (NSString *)fillMode
{
    return _fillMode;
}

- (void)setFillMode:(NSString *)theFillMode
{
    [_fillMode release];
    _fillMode = [theFillMode copy];
    _CALayerSetNeedsComposite(self);
}

- (float)speed
{
    return _speed;
}

- (void)setSpeed:(float)theSpeed
{
    _speed = theSpeed;
    _CALayerSetNeedsComposite(self);
}

- (CFTimeInterval)timeOffset
{
    return _timeOffset;
}

- (void)setTimeOffset:(CFTimeInterval)theTimeOffset
{
    _timeOffset = theTimeOffset;
    _CALayerSetNeedsComposite(self);
}

#pragma mark - Animation

- (id<CAAction>)actionForKey:(NSString *)key
{
    if ([CATransaction disableActions]) {
        return nil;
    }
    if ([delegate respondsToSelector:@selector(actionForLayer:forKey:)]) {
        return [delegate performSelector:@selector(actionForLayer:forKey:) withObject:self withObject:key];
    }
    id<CAAction> action = CFDictionaryGetValue(_actions, key);
    if (action == nil) {
        NSDictionary *tmpStyle = _style;
        while (tmpStyle != nil) {
            action = CFDictionaryGetValue(tmpStyle, key);
            if (action != nil) {
                return action;
            }
            tmpStyle = CFDictionaryGetValue(tmpStyle, _kCAStyle);
        }
    }
    return [CALayer defaultActionForKey:key];
}

+ (id<CAAction>)defaultActionForKey:(NSString *)key
{
    if ([key isEqualToString:kCATransition]) {
        return [[[CATransition alloc] init] autorelease];
    } else {
        return [CABasicAnimation animationWithKeyPath:key];
    }
}

- (void)addAnimation:(CAAnimation *)anim forKey:(NSString *)key
{
    CAAnimation *animation = [anim copy];
    CFDictionarySetValue(_animations, key, animation);
    [animation release];
    if (!animation->_duration) {
        animation.duration = [CATransaction animationDuration];
    }
    animation->_startTime = [self convertTime:CACurrentMediaTime() fromLayer:nil];
    if ([animation isKindOfClass:[CABasicAnimation class]]) {
        CABasicAnimation *basicAnimation = (CABasicAnimation *)animation;
        if (!basicAnimation->fromValue) {
            basicAnimation.fromValue = [self valueForKeyPath:basicAnimation->keyPath];
        }
    } else if ([animation isKindOfClass:[CAKeyframeAnimation class]]) {
        //DLog(@"[animation isKindOfClass:[CAKeyframeAnimation class]]");
        CAKeyframeAnimation *keyframeAnimation = (CAKeyframeAnimation *)animation;
        if ([keyframeAnimation->keyPath isEqualToString:@"contents"]) {
            if (_keyframesContents) {
                [_keyframesContents release];
            }
            _keyframesContents = [keyframeAnimation->_values copy];
            //DLog(@"_keyframesContents: %@", _keyframesContents);
        }
    }
}

- (CAAnimation *)animationForKey:(NSString *)key
{
    return CFDictionaryGetValue(_animations, key);
}

- (void)removeAllAnimations
{
    CFDictionaryRemoveAllValues(_animations);
}

- (void)removeAnimationForKey:(NSString *)key
{
    //DLog(@"layer: %p, modelLayer: %d", self, self==modelLayer);
    //DLog(@"_animations1: %@", _animations);
    CFDictionaryRemoveValue(_animations, key);
    if ([key isEqualToString:@"contents"]) {
        _CABackingStoreUnload(((CARenderLayer *)_renderLayer)->_oldBackingStore);
    }
}

- (NSArray *)animationKeys
{
    return [_animations allKeys];
//    return _CALayerGetDictionaryKeys(_animations);
}

#pragma mark - Layer actions

- (void)addSublayer:(CALayer *)layer
{
    //DLog(@"layer: %@", layer);
    if (layer && layer->_superlayer != self) {
        [layer removeFromSuperlayer];
        //DLog(@"_sublayers: %@", _sublayers);
        CFArrayAppendValue(_sublayers, layer);
        //DLog(@"_sublayers: %@", _sublayers);
        layer->_superlayer = self;
        if (layer->_superlayer->_superlayer == nil) { // if superlayer is the window
            //DLog(@"layer->_superlayer->_superlayer == nil");
            _CALayerSetNeedsDisplayWithRoot(layer);
        } else {
            _CALayerSetNeedsComposite(layer);
        }
    }
}

- (void)removeFromSuperlayer
{
    if (_superlayer) {
        //DLog(@"self: %@", self);
        _CATransactionAddToRemoveLayers(self);
        _CFArrayRemoveValue(_superlayer->_sublayers, self);
        if (self->_superlayer->_superlayer == nil) { // if superlayer is the window
            _CALayerSetNeedsUnload(self);
        }
        _CALayerSetNeedsComposite(_superlayer);
        _superlayer = nil;
    }
}

- (void)insertSublayer:(CALayer *)layer atIndex:(unsigned)index
{
    //DLog(@"layer: %@", layer);
    if (!layer) {
        return;
    }
    [layer retain];
    if (layer->_superlayer != self) {
        //DLog();
        [layer removeFromSuperlayer];
        layer->_superlayer = self;
    } else {
        //DLog();
        _CFArrayRemoveValue(_sublayers, layer);
    }
    CFArrayInsertValueAtIndex(_sublayers, index, layer);
    [layer release];
    if (layer->_superlayer->_superlayer == nil) { // if superlayer is the window
        //DLog();
        _CALayerSetNeedsDisplayWithRoot(layer);
    } else {
        //DLog(@"layer: %@", layer);
        _CALayerSetNeedsComposite(layer);
    }
}

- (void)moveLayerToTop:(CALayer *)layer
{
    //DLog(@"layer: %@", layer);
    if (!layer) {
        return;
    }
    if (layer->_superlayer != self) {
        return;
    }
    _CFArrayMoveValueToTop(_sublayers, layer);
    //DLog();
    _CALayerSetNeedsComposite(layer);
}

- (void)insertSublayer:(CALayer *)layer below:(CALayer *)sibling
{
    //DLog(@"layer: %@", layer);
    if (!layer || !sibling) {
        return;
    }
    [layer retain];
    if (layer->_superlayer != self) {
        [layer removeFromSuperlayer];
        layer->_superlayer = self;
    } else {
        _CFArrayRemoveValue(_sublayers, layer);
    }
    CFIndex siblingIndex = [self indexOfLayer:sibling];
    if (siblingIndex != -1) { // sibling found
        CFArrayInsertValueAtIndex(_sublayers, siblingIndex, layer);
    }
    [layer release];
    if (layer->_superlayer->_superlayer == nil) { // if superlayer is the window
        _CALayerSetNeedsDisplayWithRoot(layer);
    } else {
        _CALayerSetNeedsComposite(self);
    }
}

- (void)insertSublayer:(CALayer *)layer above:(CALayer *)sibling
{
    //DLog(@"layer: %@", layer);
    if (!layer || !sibling) {
        return;
    }
    [layer retain];
    if (layer->_superlayer != self) {
        [layer removeFromSuperlayer];
        layer->_superlayer = self;
    } else {
        _CFArrayRemoveValue(_sublayers, layer);
    }
    CFIndex siblingIndex = [self indexOfLayer:sibling];
    if (siblingIndex != -1) { // sibling found
        CFArrayInsertValueAtIndex(_sublayers, siblingIndex+1, layer);
    }
    [layer release];
    if (layer->_superlayer->_superlayer == nil) { // if superlayer is the window
        _CALayerSetNeedsDisplayWithRoot(layer);
    } else {
        _CALayerSetNeedsComposite(self);
    }
    //}
}

- (void)replaceSublayer:(CALayer *)oldLayer with:(CALayer *)newLayer
{
    //DLog(@"newLayer: %@", newLayer);
    if (oldLayer && newLayer && newLayer->_superlayer != self) {
        [newLayer removeFromSuperlayer];
        CFIndex oldLayerIndex = [self indexOfLayer:oldLayer];
        CFRange replaceRange = {oldLayerIndex, 1};
        if (oldLayerIndex != -1) {
            CFArrayReplaceValues(_sublayers, replaceRange, (const void **)&newLayer,1);
            _CALayerSetNeedsUnload(oldLayer);
        }
        newLayer->_superlayer = self;
        if (newLayer->_superlayer->_superlayer == nil) { // if superlayer is the window
            _CALayerSetNeedsDisplayWithRoot(newLayer);
        } else {
            _CALayerSetNeedsComposite(self);
        }
    }
}

#pragma mark - Conversions

- (CGPoint)convertPoint:(CGPoint)p toLayer:(CALayer *)l
{
    CGPoint output = CGPointZero;

    CALayer *grandSuperLayer = self;
    while (grandSuperLayer->_superlayer) {
        p.x += grandSuperLayer.frame.origin.x;
        p.y += grandSuperLayer.frame.origin.y;
        grandSuperLayer = grandSuperLayer->_superlayer;
    }
    CALayer *foreignGrandSuperLayer = l;
    CGPoint lOrigin = CGPointZero;
    while (foreignGrandSuperLayer->_superlayer) {
        lOrigin.x += foreignGrandSuperLayer.frame.origin.x;
        lOrigin.y += foreignGrandSuperLayer.frame.origin.y;
        foreignGrandSuperLayer = foreignGrandSuperLayer->_superlayer;
    }
    if (grandSuperLayer == foreignGrandSuperLayer) {
        output.x = p.x - lOrigin.x;
        output.y = p.y - lOrigin.y;
    }
    return output;
}

- (CGPoint)convertPoint:(CGPoint)p fromLayer:(CALayer *)l
{
    CGPoint output = CGPointZero;

    CALayer *grandSuperLayer = self;
    CGPoint localOrigin = CGPointZero;
    while (grandSuperLayer->_superlayer) {
        localOrigin.x += grandSuperLayer.frame.origin.x;
        localOrigin.y += grandSuperLayer.frame.origin.y;
        grandSuperLayer = grandSuperLayer->_superlayer;
    }
    CALayer *foreignGrandSuperLayer = l;
    while (foreignGrandSuperLayer->_superlayer) {
        p.x += foreignGrandSuperLayer.frame.origin.x;
        p.y += foreignGrandSuperLayer.frame.origin.y;

        foreignGrandSuperLayer = foreignGrandSuperLayer->_superlayer;
    }
    if (grandSuperLayer == foreignGrandSuperLayer) {
        output.x = p.x - localOrigin.x;
        output.y = p.y - localOrigin.y;
    }
    return output;
}

- (CGRect)convertRect:(CGRect)aRect fromLayer:(CALayer *)layer
{
    CGRect output = CGRectZero;
    output.origin = [self convertPoint:aRect.origin fromLayer:layer];
    output.size = aRect.size;
    return output;
}

- (CGRect)convertRect:(CGRect)aRect toLayer:(CALayer *)layer
{
    CGRect output = CGRectZero;
    output.origin = [self convertPoint:aRect.origin toLayer:layer];
    output.size = aRect.size;
    return output;
}

- (CFTimeInterval)convertTime:(CFTimeInterval)t fromLayer:(CALayer *)l
{
    if (!l) {
        if (_superlayer) {
            CFTimeInterval tp = [_superlayer convertTime:t fromLayer:l];
            return (tp - _beginTime) * _speed + _timeOffset;
        } else {
            return (t - _beginTime) * _speed + _timeOffset;
        }
    }
    CALayer *rootLayer = l;
    CFTimeInterval tr = t;
    while (rootLayer->_superlayer) {
        tr = (tr - rootLayer->_timeOffset) / rootLayer->_speed + rootLayer->_beginTime;
        rootLayer = rootLayer->_superlayer;
    }
    return _CALayerGetLocalTimeWithRootLayer(self, rootLayer, tr);
}

- (CFTimeInterval)convertTime:(CFTimeInterval)t toLayer:(CALayer *)l
{
    if (!l) {
        return 0;
    }
    CALayer *rootLayer = self;
    CFTimeInterval tr = t;
    while (rootLayer->_superlayer) {
        tr = (tr - rootLayer->_timeOffset) / rootLayer->_speed + rootLayer->_beginTime;
        rootLayer = rootLayer->_superlayer;
    }
    return _CALayerGetLocalTimeWithRootLayer(l, rootLayer, tr);
}

#pragma mark - Public methods

- (CFIndex)indexOfLayer:(CALayer *)layer
{
    return _CALayerIndexOfLayer(layer);
}

- (BOOL)contentsAreFlipped
{
    return NO;
}

- (BOOL)containsPoint:(CGPoint)thePoint
{
    return CGRectContainsPoint(_bounds, thePoint);
}

- (CALayer *)hitTest:(CGPoint)thePoint
{
    //DLog();
    if (_hidden || _opacity < _kSmallValue || ![self containsPoint:thePoint]) {
        return NULL;
    } else {
        CFIndex count = CFArrayGetCount(_sublayers);
        for (int i = count - 1; i >= 0; --i) {
            CALayer *layer = CFArrayGetValueAtIndex(_sublayers, i);
            CALayer *hitLayer = [layer hitTest:[layer convertPoint:thePoint fromLayer:self]];
            if (hitLayer) {
                return hitLayer;
            }
        }
        return self;
    }
}

- (CGSize)preferredFrameSize
{
    return _bounds.size;
}

- (void)renderInContext:(CGContextRef)ctx
{
}

- (BOOL)shouldArchiveValueForKey:(NSString *)key
{
    return YES;
}

@end

@implementation CALayer(UIKitCompatibility)

- (CGFloat)contentsScale
{
    return _contentsScale;
}

- (void)setContentsScale:(CGFloat)newContentsScale
{
    _contentsScale = newContentsScale;
}

@end
