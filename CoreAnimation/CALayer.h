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

#import <CoreAnimation/CABase.h>
#import <CoreAnimation/CAAction.h>
#import <CoreAnimation/CATransform3D.h>
#import <CoreAnimation/CAMediaTiming.h>

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

@interface CALayer : NSObject <CAMediaTiming> {
@public
    id delegate;
    CALayer *_modelLayer;
    CALayer *_presentationLayer;
    CALayer *_renderLayer;
    CALayer *_superlayer;
    CFMutableArrayRef _sublayers;
    id _layoutManager;
    BOOL _geometryFlipped;
    float _opacity;
    BOOL _opaque;
    id _oldContents;
    id _contents;
    //BOOL _contentsWasSet;
    id _displayContents;
    NSArray *_keyframesContents;
    CGPoint _position;
    CGFloat _zPosition;
    CGPoint _anchorPoint;
    CGRect _bounds;
    CGColorRef _backgroundColor;
    CGFloat _cornerRadius;
    CGFloat _borderWidth;
    CGColorRef _borderColor;
    CGColorRef _shadowColor;
    CGFloat _shadowOpacity;
    CGSize _shadowOffset;
    CGFloat _shadowRadius;
    CGPathRef _shadowPath;
    BOOL _masksToBounds;
    CGRect _contentsRect;
    float _contentsTransitionProgress;
    float _keyframesProgress;
    BOOL _hidden;
    NSString *_contentsGravity;
    CGRect _contentsCenter;
    BOOL _needsDisplayOnBoundsChange;
    CGFloat _contentsScale;
    CATransform3D _transform;
    CFMutableDictionaryRef _animations;
    CFDictionaryRef _actions;
    CFDictionaryRef _style;
    BOOL _needsLayout;
    BOOL _needsDisplay; // to render / draw layer content
    BOOL _needsComposite; // needs just to show content without redrawing
    BOOL _needsUnload;
    CGRect _visibleRect;
    
    CFTimeInterval _beginTime;
    CFTimeInterval _duration;
    float _repeatCount;
    CFTimeInterval _repeatDuration;
    BOOL _autoreverses;
    NSString *_fillMode;
    float _speed;
    CFTimeInterval _timeOffset;
}

@property (assign) id delegate;
@property (retain) id contents;
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
@property (retain) CGColorRef backgroundColor;
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

- (void)layoutSublayersOfLayer:(CALayer *)layer;
- (void)displayLayer:(CALayer *)layer;
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context;

@end

