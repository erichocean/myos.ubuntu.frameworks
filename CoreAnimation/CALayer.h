/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <CoreAnimation/CABase.h>
#import <CoreAnimation/CAAction.h>
#import <CoreAnimation/CATransform3D.h>
#import "CAMediaTiming.h"

extern NSString *const kCAGravityResize;
extern NSString *const kCAGravityResizeAspect;
extern NSString *const kCAGravityResizeAspectFill;
extern NSString *const kCAGravityCenter;
extern NSString *const kCAGravityTop;
extern NSString *const kCAGravityBottom;
extern NSString *const kCAGravityLeft;
extern NSString *const kCAGravityRight;
extern NSString *const kCAGravityTopLeft;
extern NSString *const kCAGravityTopRight;
extern NSString *const kCAGravityBottomLeft;
extern NSString *const kCAGravityBottomRight;
extern NSString *const kCATransition;

@class CAAnimation;

@interface CALayer : NSObject <CAMediaTiming>
{
@package
    id delegate;
    CALayer *modelLayer;
    CALayer *presentationLayer;
    CALayer *_renderLayer;
    CALayer *superlayer;
    CFMutableArrayRef sublayers;
    id layoutManager;
    BOOL geometryFlipped;
    float opacity;
    BOOL opaque;
    id _oldContents;
    id contents;
    id _displayContents;
    CGPoint position;
    CGFloat zPosition;
    CGPoint anchorPoint;
    CGRect bounds;
    CGColorRef backgroundColor;
    CGFloat cornerRadius;
    CGFloat borderWidth;
    CGColorRef borderColor;
    CGColorRef shadowColor;
    CGFloat shadowOpacity;
    CGSize shadowOffset;
    CGFloat shadowRadius;
    CGPathRef shadowPath;
    BOOL masksToBounds;
    CGRect contentsRect;
    float _contentsTransitionProgress;
    BOOL hidden;
    NSString *contentsGravity;
    CGRect contentsCenter;
    BOOL needsDisplayOnBoundsChange;
    CGFloat contentsScale;
    CATransform3D transform;
    CFMutableDictionaryRef _animations; // any variable not tied with property we use _ in its name
    CFDictionaryRef actions;
    CFDictionaryRef style;
    BOOL needsLayout;
    BOOL needsDisplay; // to render / draw layer content
    BOOL _needsComposite; // needs just to show content without redrawing
    BOOL _needsUnload;
    CGRect visibleRect;
    
    CFTimeInterval beginTime;
    CFTimeInterval duration;
    float repeatCount;
    CFTimeInterval repeatDuration;
    BOOL autoreverses;
    NSString *fillMode;
    float speed;
    CFTimeInterval timeOffset;
}

@property (assign) id delegate;
@property (retain) id contents;
@property (assign) id layoutManager;
@property (readonly) CALayer *superlayer;
@property (copy) NSMutableArray *sublayers;
@property CGPoint position;
@property CGFloat zPosition;
@property CGPoint anchorPoint;
@property CGRect bounds;
@property CGRect frame;
@property float opacity;
@property (getter=isOpaque) BOOL opaque;
@property (getter=isGeometryFlipped) BOOL geometryFlipped;
@property (assign) CGColorRef backgroundColor;
@property (assign) CGFloat cornerRadius;
@property (assign) CGFloat borderWidth;
@property (assign) CGColorRef borderColor;
@property (assign) CGColorRef shadowColor;
@property CGFloat shadowOpacity;
@property CGSize shadowOffset;
@property CGFloat shadowRadius;
@property (assign) CGPathRef shadowPath;
@property BOOL masksToBounds;
@property CGRect contentsRect;
@property (getter=isHidden) BOOL hidden;
@property (copy) NSString *contentsGravity;
@property CGRect contentsCenter;
@property BOOL needsDisplayOnBoundsChange;
@property (copy) NSDictionary *actions;
@property (copy) NSDictionary *style;

+ (id)layer;
+ (id<CAAction>)defaultActionForKey:(NSString *)key;
+ (BOOL)needsDisplayForKey:(NSString *)key;
+ (id)defaultValueForKey:(NSString *)key;
+ (BOOL)needsDisplayForKey:(NSString *)key;
- (id)initWithLayer:(id)layer;
- (id)initWithBounds:(CGRect)theBounds;
- (id)presentationLayer;
- (id)modelLayer;
- (void)addAnimation:(CAAnimation *)anim forKey:(NSString *)key;
- (void)removeAnimationForKey:(NSString *)key;
- (CAAnimation *)animationForKey:(NSString *)key;
- (CGAffineTransform)affineTransform;
- (void)setAffineTransform:(CGAffineTransform)m;
- (void)addSublayer:(CALayer *)layer;

- (CGPoint)convertPoint:(CGPoint)p toLayer:(CALayer *)l;
- (CGPoint)convertPoint:(CGPoint)p fromLayer:(CALayer *)l;
- (CGRect)convertRect:(CGRect)aRect fromLayer:(CALayer *)layer;
- (CGRect)convertRect:(CGRect)aRect toLayer:(CALayer *)layer;

- (CFTimeInterval)convertTime:(CFTimeInterval)t fromLayer:(CALayer *)l;
- (CFTimeInterval)convertTime:(CFTimeInterval)t toLayer:(CALayer *)l;

- (void)removeFromSuperlayer;
- (void)insertSublayer:(CALayer *)layer atIndex:(unsigned)index;
- (void)insertSublayer:(CALayer *)layer below:(CALayer *)sibling;
- (void)insertSublayer:(CALayer *)layer above:(CALayer *)sibling;
- (void)replaceSublayer:(CALayer *)oldLayer with:(CALayer *)newLayer;
- (void)setNeedsDisplay;
- (void)setNeedsDisplayInRect:(CGRect)r;
- (void)setNeedsLayout;
- (void)layoutIfNeeded;
- (void)displayIfNeeded;
- (void)display;
- (BOOL)needsDisplay;
- (void)drawInContext:(CGContextRef)ctx;
- (CALayer *)hitTest:(CGPoint)thePoint;
- (BOOL)containsPoint:(CGPoint)thePoint;
- (BOOL)contentsAreFlipped;

- (void)removeAllAnimations;
- (NSArray *)animationKeys;
- (void)renderInContext:(CGContextRef)ctx;
- (CGSize)preferredFrameSize;
- (BOOL)shouldArchiveValueForKey:(NSString *)key;
- (id<CAAction>)actionForKey:(NSString *)key;

@end

@interface CALayer (UIKitCompatibility)

- (CGFloat)contentsScale;
- (void)setContentsScale:(CGFloat)newContentsScale;

@end

@interface NSObject (CALayerDelegate)

- (void)displayLayer:(CALayer *)layer;
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context;

@end

