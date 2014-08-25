/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <CoreAnimation/CoreAnimation-private.h>

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

//static CFMutableArrayRef _rootLayers;
static NSString *const _kCAStyle = @"style";
static NSArray *_CALayerAnimatableKeys = nil;
static NSMutableDictionary *_needDisplayKeys;

@implementation CALayer

@synthesize delegate;
@synthesize layoutManager;
//@synthesize anchorPoint;
@synthesize cornerRadius;
@synthesize borderWidth;
@synthesize borderColor;
@synthesize contentsRect;
@synthesize contentsCenter;
@synthesize contentsGravity;
@synthesize needsDisplayOnBoundsChange;
@synthesize actions;
@synthesize style;

#pragma mark - Life cycle

+ (void)initialize
{
    if (self == [CALayer class]) {
        _rootLayers = CFArrayCreateMutable(kCFAllocatorDefault, 5, &kCFTypeArrayCallBacks);
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
                               @"YES", @"shadowRadius", nil];
        _CAAnimatorInitialize();
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
        sublayers = CFArrayCreateMutable(kCFAllocatorDefault, 20, &kCFTypeArrayCallBacks);
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
        modelLayer = self;
        bounds = theBounds;
        contentsScale = 1.0;
        needsLayout = NO;
        needsDisplay = YES;
        _needsComposite = YES;
        position = CGPointZero;
        anchorPoint = CGPointMake(0.5, 0.5);
        opacity = 1.0;
        shadowOpacity = 0;
        shadowOffset = CGSizeMake(0, 3);
        shadowRadius = 3;
        shadowPath = NULL;
        opaque = NO;
        masksToBounds = NO;
        _oldContents = nil;
        contents = nil;
        _displayContents = nil;
        contentsRect = CGRectMake(0.0, 0.0, 1.0, 1.0);
        _animations = [[NSMutableDictionary alloc] initWithCapacity:10];//CFDictionaryCreateMutable(kCFAllocatorDefault, 10, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        actions = CFDictionaryCreateMutable(kCFAllocatorDefault, 10, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        style = CFDictionaryCreateMutable(kCFAllocatorDefault, 10, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        presentationLayer = [[[self class] alloc] initWithModelLayer:self];
        _renderLayer = [[CARenderLayer alloc] initWithPresentationLayer:presentationLayer];
        presentationLayer->_renderLayer = _renderLayer;
        _CALayerSetNeedsDisplay(self);
        backgroundColor = nil;
        _needsUnload = NO;
        _contentsTransitionProgress = 1.0;
        beginTime = 0;
        duration = 0;
        repeatCount = 0;
        repeatDuration = 0;
        autoreverses = NO;
        fillMode = nil;
        speed = 1;
        timeOffset = 0;
    }
    return self;
}

- (void)dealloc
{
    [presentationLayer release];
    [contentsGravity release];
    CFRelease(actions);
    [_animations release];
    CFRelease(style);
    CFRelease(sublayers);
    CGColorRelease(backgroundColor);
    CGColorRelease(shadowColor);
    [_oldContents release];
    [contents release];
    [fillMode release];
    CGImageRelease(_displayContents);
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
    return opaque;
}

- (void)setOpaque:(BOOL)newValue
{
    opaque = newValue;
    _CALayerSetNeedsComposite(self);
}

- (BOOL)isGeometryFlipped
{
    return geometryFlipped;
}

- (void)setGeometryFlipped:(BOOL)newValue
{
    geometryFlipped = newValue;
}

- (BOOL)isHidden
{
    return hidden;
}

- (void)setHidden:(BOOL)newValue
{
    hidden = newValue;
    if (newValue == YES) {
        self.opacity = 0;
        _CALayerSetNeedsUnload(self);
    } else {
        self.opacity = 1;
        _CALayerSetNeedsDisplayWithRoot(self);
    }
    _CALayerSetNeedsComposite(self);
}

- (id)presentationLayer
{
    if (modelLayer == self) {
        CALayer *result = [[[[self class] alloc] initWithModelLayer:self] autorelease];
        _CALayerApplyAnimations(result);
        return result;
    } else {
        return self;
    }
}

- (id)modelLayer
{
    return modelLayer;
}

- (CALayer *)superlayer
{
    if (modelLayer == self) {
        return superlayer;
    } else {
        return [modelLayer->superlayer presentationLayer];
    }
}

- (NSArray *)sublayers
{
    if (modelLayer == self) {
        return CFArrayCreateMutableCopy(kCFAllocatorDefault, 10, sublayers);
    } else {
      CFMutableArrayRef subPresentationLayers = CFArrayCreateMutable(kCFAllocatorDefault, 20, &kCFTypeArrayCallBacks);
      for (CALayer *modelSubLayer in modelLayer->sublayers) {
          CFArrayAppendValue(subPresentationLayers, [modelSubLayer presentationLayer]);
      }
      return subPresentationLayers;
    }
}

- (void)setSublayers:(NSArray *)theSublayers
{
    if (modelLayer == self) {
        if (sublayers) {
            CFRelease(sublayers);
        }
        sublayers = CFArrayCreateMutableCopy(kCFAllocatorDefault, 10, theSublayers);
    }
}

- (id)contents
{
    return contents;
}

- (void)setContents:(id)newContents
{
    //DLog(@"newContents: %@", newContents);
    [self willChangeValueForKey:@"contents"];
    //if (contents) {
    [contents release];
    //}
    contents = [newContents retain];
    [self didChangeValueForKey:@"contents"];
}

- (float)opacity
{
    return opacity;
}

- (void)setOpacity:(float)newOpacity
{
    [self willChangeValueForKey:@"opacity"];
    opacity = newOpacity;
    [self didChangeValueForKey:@"opacity"];
    if (opacity < 1.0) {
        opaque = NO;
    }
}

- (CGColorRef)backgroundColor
{
    return backgroundColor;
}

- (void)setBackgroundColor:(CGColorRef)newBackgroundColor
{
    [self willChangeValueForKey:@"backgroundColor"];
    CGColorRelease(backgroundColor);
    backgroundColor = CGColorRetain(newBackgroundColor);
    [self didChangeValueForKey:@"backgroundColor"];
}

- (CGPoint)position
{
    return position;
}

- (void)setPosition:(CGPoint)newPosition
{
    [self willChangeValueForKey:@"position"];
    position = newPosition;
    [self didChangeValueForKey:@"position"];
}

- (CGFloat)zPosition
{
    return zPosition;
}

- (void)setZPosition:(CGFloat)newZPosition
{
    zPosition = newZPosition;
    _CALayerSetNeedsComposite(self);
}

- (CGRect)bounds
{
    return bounds;
}

- (void)setBounds:(CGRect)newBounds
{
    [self willChangeValueForKey:@"bounds"];
    bounds = newBounds;
    [self didChangeValueForKey:@"bounds"];
    if (needsDisplayOnBoundsChange) {
        _CALayerSetNeedsDisplay(self);
    }
}

- (CGPoint)anchorPoint
{
    return anchorPoint;
}

- (void)setAnchorPoint:(CGPoint)newAnchorPoint
{
    [self willChangeValueForKey:@"anchorPoint"];
    anchorPoint = newAnchorPoint;
    [self didChangeValueForKey:@"anchorPoint"];
    //_CALayerSetNeedsComposite(self);
}

- (CGRect)frame
{
    return CGRectMake(position.x - bounds.size.width * anchorPoint.x,
                      position.y - bounds.size.height * (1 - anchorPoint.y),
                      bounds.size.width, bounds.size.height);
}

- (void)setFrame:(CGRect)newFrame
{
    [self setPosition:CGPointMake(newFrame.origin.x + newFrame.size.width * anchorPoint.x,
                                  newFrame.origin.y + newFrame.size.height * (1 - anchorPoint.y))];
    [self setBounds:CGRectMake(0, 0, newFrame.size.width, newFrame.size.height)];
}

- (CGColorRef)shadowColor
{
    return shadowColor;
}

- (void)setShadowColor:(CGColorRef)aColor
{
    [self willChangeValueForKey:@"shadowColor"];
    CGColorRelease(shadowColor);
    shadowColor = CGColorRetain(aColor);
    [self didChangeValueForKey:@"shadowColor"];
    _CALayerSetNeedsDisplay(self);
}

- (CGFloat)shadowOpacity
{
    return shadowOpacity;
}

- (void)setShadowOpacity:(CGFloat)anOpacity
{
    shadowOpacity = anOpacity;
    _CALayerSetNeedsDisplay(self);
}

- (CGSize)shadowOffset
{
    return shadowOffset;
}
 
- (void)setShadowOffset:(CGSize)anOffset
{
    shadowOffset = CGSizeMake(anOffset.width, -anOffset.height); // to keep with the standard of Apple that -3 means going down
    _CALayerSetNeedsDisplay(self);
}

- (BOOL)masksToBounds
{
    return masksToBounds;
}

- (void)setMasksToBounds:(BOOL)newValue
{
    masksToBounds = newValue;
    _CALayerSetNeedsDisplay(self);
}

- (CGFloat)shadowRadius
{
    return shadowRadius;
}

- (void)setShadowRadius:(CGFloat)aRadius
{
    shadowRadius = aRadius;
    _CALayerSetNeedsDisplay(self);
}

- (CGPathRef)shadowPath
{
    return shadowPath;
}

- (void)setShadowPath:(CGPathRef)aPath
{
    shadowPath = aPath;
    _CALayerSetNeedsDisplay(self);
}

- (CGAffineTransform)affineTransform
{
    return CATransform3DGetAffineTransform(transform);
}

- (void)setAffineTransform:(CGAffineTransform)m
{
    transform = CATransform3DMakeAffineTransform(m);
    _CALayerSetNeedsDisplay(self);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; frame:%@; _animations:%@>", [self className], self, NSStringFromCGRect(self.frame), _animations];
}

#pragma mark - Display

- (BOOL)needsDisplay
{
    return needsDisplay;
}

- (void)setNeedsDisplay
{
    _CALayerSetNeedsDisplay(self);
}

// display here means draw
- (void)setNeedsDisplayInRect:(CGRect)r
{
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
    return beginTime;
}

- (void)setBeginTime:(CFTimeInterval)theBeginTime
{
    beginTime = theBeginTime;
    _CALayerSetNeedsComposite(self);
}

- (CFTimeInterval)duration
{
    return duration;
}

- (void)setDuration:(CFTimeInterval)theDuration
{
    duration = theDuration;
    _CALayerSetNeedsComposite(self);
}

- (float)repeatCount
{
    return repeatCount;
}

- (void)setRepeatCount:(float)theRepeatCount
{
    repeatCount = theRepeatCount;
    _CALayerSetNeedsComposite(self);
}

- (CFTimeInterval)repeatDuration
{
    return repeatDuration;
}

- (void)setRepeatDuration:(CFTimeInterval)theRepeatDuration
{
    repeatDuration = theRepeatDuration;
    _CALayerSetNeedsComposite(self);
}

- (BOOL)autoreverses
{
    return autoreverses;
}

- (void)setAutoreverses:(BOOL)flag
{
    autoreverses = flag;
    _CALayerSetNeedsComposite(self);
}

- (NSString *)fillMode
{
    return fillMode;
}

- (void)setFillMode:(NSString *)theFillMode
{
    [fillMode release];
    fillMode = [theFillMode copy];
    _CALayerSetNeedsComposite(self);
}

- (float)speed
{
    return speed;
}

- (void)setSpeed:(float)theSpeed
{
    speed = theSpeed;
    _CALayerSetNeedsComposite(self);
}

- (CFTimeInterval)timeOffset
{
    return timeOffset;
}

- (void)setTimeOffset:(CFTimeInterval)theTimeOffset
{
    timeOffset = theTimeOffset;
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
    id<CAAction> action = CFDictionaryGetValue(actions, key);
    if (action == nil) {
        NSDictionary *tmpStyle = style;
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
    if (!animation->duration) {
        animation.duration = [CATransaction animationDuration];
    }
    animation->_startTime = [self convertTime:CACurrentMediaTime() fromLayer:nil];
    if ([animation isKindOfClass:[CABasicAnimation class]]) {
        CABasicAnimation *basicAnimation = (CABasicAnimation *)animation;
        if (!basicAnimation->fromValue) {
            basicAnimation.fromValue = [self valueForKeyPath:basicAnimation->keyPath];
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
    //CABasicAnimation *animation = CFDictionaryGetValue(_animations, key);
    //_CAAnimationRemoveFromAnimationGroup(animation);
    //DLog(@"layer: %p, modelLayer: %d", self, self==modelLayer);
    //DLog(@"_animations1: %@", _animations);
    CFDictionaryRemoveValue(_animations, key);
    if ([key isEqualToString:@"contents"]) {
        _CABackingStoreUnload(((CARenderLayer *)_renderLayer)->oldBackingStore);
    }
}

- (NSArray *)animationKeys
{
    return [_animations allKeys];
//    return _CALayerGetDictionaryKeys(_animations);

/*
    CFIndex animationsCount = CFDictionaryGetCount(_animations);
    CFTypeRef *keys = (CFTypeRef *) malloc(animationsCount * sizeof(CFTypeRef));
    CFDictionaryGetKeysAndValues(_animations, (const void **)&keys, NULL);
    CFArrayRef animationKeys = CFArrayCreate(kCFAllocatorDefault,(const void **)&keys, animationsCount, &kCFTypeArrayCallBacks);
    return [(NSArray *)animationKeys autorelease];*/
}

#pragma mark - Layer actions

- (void)addSublayer:(CALayer *)layer
{
    if (layer && layer->superlayer != self) {
        [layer removeFromSuperlayer];
        CFArrayAppendValue(sublayers, layer);
        layer->superlayer = self;
        _CALayerSetNeedsDisplayWithRoot(layer);
    }
}

- (void)removeFromSuperlayer
{
    if (superlayer) {
        _CATransactionAddToRemoveLayers(self);
        //[superlayer->sublayers removeObject:self];
        _CFArrayRemoveValue(superlayer->sublayers, self);
        _CALayerSetNeedsComposite(superlayer);
        superlayer = nil;
    }
}

- (void)insertSublayer:(CALayer *)layer atIndex:(unsigned)index
{
    if (layer && layer->superlayer != self) {
        [layer removeFromSuperlayer];
        CFArrayInsertValueAtIndex(sublayers, index, layer);
        layer->superlayer = self;
        _CALayerSetNeedsDisplayWithRoot(layer);
    }
}

- (void)insertSublayer:(CALayer *)layer below:(CALayer *)sibling
{
    if (sibling && layer && layer->superlayer != self) {
        [layer removeFromSuperlayer];
        CFIndex siblingIndex = [self indexOfLayer:sibling];
        if (siblingIndex != -1) { // sibling found
            CFArrayInsertValueAtIndex (sublayers, siblingIndex, layer);
        }
        layer->superlayer = self;
        _CALayerSetNeedsDisplayWithRoot(layer);
    }
}

- (void)insertSublayer:(CALayer *)layer above:(CALayer *)sibling
{
    if (sibling && layer && layer->superlayer != self) {
        [layer removeFromSuperlayer];
        CFIndex siblingIndex = [self indexOfLayer:sibling];
        if (siblingIndex != -1) { // sibling found
            CFArrayInsertValueAtIndex(sublayers, siblingIndex+1, layer);
        }
        layer->superlayer = self;
        _CALayerSetNeedsDisplayWithRoot(layer);
    }
}

- (void)replaceSublayer:(CALayer *)oldLayer with:(CALayer *)newLayer
{
    if (oldLayer && newLayer && newLayer->superlayer != self) {
        [newLayer removeFromSuperlayer];
        CFIndex oldLayerIndex = [self indexOfLayer:oldLayer];
        CFRange replaceRange = {oldLayerIndex, 1};
        if (oldLayerIndex != -1) {
            CFArrayReplaceValues(sublayers, replaceRange, (const void **)&newLayer,1);
            _CALayerSetNeedsUnload(oldLayer);
        }
        newLayer->superlayer = self;
        _CALayerSetNeedsDisplayWithRoot(newLayer);
    }
}

#pragma mark - Conversions

- (CGPoint)convertPoint:(CGPoint)p toLayer:(CALayer *)l
{
    CGPoint output = CGPointZero;

    CALayer *grandSuperLayer = self;
    while (grandSuperLayer->superlayer) {
        p.x += grandSuperLayer.frame.origin.x;
        p.y += grandSuperLayer.frame.origin.y;
        grandSuperLayer = grandSuperLayer->superlayer;
    }
    CALayer *foreignGrandSuperLayer = l;
    CGPoint lOrigin = CGPointZero;
    while (foreignGrandSuperLayer->superlayer) {
        lOrigin.x += foreignGrandSuperLayer.frame.origin.x;
        lOrigin.y += foreignGrandSuperLayer.frame.origin.y;
        foreignGrandSuperLayer = foreignGrandSuperLayer->superlayer;
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
    while (grandSuperLayer->superlayer) {
        localOrigin.x += grandSuperLayer.frame.origin.x;
        localOrigin.y += grandSuperLayer.frame.origin.y;
        grandSuperLayer = grandSuperLayer->superlayer;
    }
    CALayer *foreignGrandSuperLayer = l;
    while (foreignGrandSuperLayer->superlayer) {
        p.x += foreignGrandSuperLayer.frame.origin.x;
        p.y += foreignGrandSuperLayer.frame.origin.y;

        foreignGrandSuperLayer = foreignGrandSuperLayer->superlayer;
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
        if (superlayer) {
            CFTimeInterval tp = [superlayer convertTime:t fromLayer:l];
            return (tp - beginTime) * speed + timeOffset;
        } else {
            return (t - beginTime) * speed + timeOffset;
        }
    }
    CALayer *rootLayer = l;
    CFTimeInterval tr = t;
    while (rootLayer->superlayer) {
        tr = (tr - rootLayer->timeOffset) / rootLayer->speed + rootLayer->beginTime;
        rootLayer = rootLayer->superlayer;
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
    while (rootLayer->superlayer) {
        tr = (tr - rootLayer->timeOffset) / rootLayer->speed + rootLayer->beginTime;
        rootLayer = rootLayer->superlayer;
    }
    return _CALayerGetLocalTimeWithRootLayer(l, rootLayer, tr);
}

#pragma mark - Helpers

- (CFIndex)indexOfLayer:(CALayer *)layer
{
    return _CALayerIndexOfLayer(layer);
}

- (void)setNeedsLayout
{
    needsLayout = YES;
}

- (void)layoutIfNeeded
{
    if (needsLayout) {
        // TODO: call delegate's needs layerout
    }
}

- (BOOL)contentsAreFlipped
{
    return NO;
}

- (BOOL)containsPoint:(CGPoint)thePoint
{
    return CGRectContainsPoint(bounds, thePoint);
}

- (CALayer *)hitTest:(CGPoint)thePoint
{
    if (hidden || opacity < _kSmallValue || ![self containsPoint:thePoint]) {
        return NULL;
    } else {
        CFIndex count = CFArrayGetCount(sublayers);
        for (int i = count - 1; i >= 0; --i) {
            CALayer *layer = CFArrayGetValueAtIndex(sublayers, i);
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
    return bounds.size;
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
    return contentsScale;
}

- (void)setContentsScale:(CGFloat)newContentsScale
{
    contentsScale = newContentsScale;
}

@end
