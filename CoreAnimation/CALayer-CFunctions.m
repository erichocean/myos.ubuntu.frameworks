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
#import <CoreGraphics/CoreGraphics-private.h>

CFMutableArrayRef _rootLayers;

#pragma mark - Static functions

static void _CALayerSetShadow(CALayer *layer, CGContextRef ctx)
{
    // Preparation for shadow if needed
    if (!layer->_masksToBounds && layer->_shadowOpacity > _kSmallValue) {
        // Set the translation for the above shadow
        CGContextSaveGState(ctx);
        CGContextTranslateCTM(ctx, layer->_shadowOffset.width<0 ? -layer->_shadowOffset.width + layer->_shadowRadius : 0,
                              layer->_shadowOffset.height<0 ? -layer->_shadowOffset.height + layer->_shadowRadius: 0);
        CGContextSetShadow(ctx, layer->_shadowOffset,layer->_shadowRadius);
        CGContextRestoreGState(ctx);
    }
}

static void _CALayerSetClip(CALayer *layer, CGContextRef ctx)
{
    // clipping the view
    if (layer->_masksToBounds) {
        CGContextSaveGState(ctx);
        CGContextBeginPath(ctx);
        if (layer->_cornerRadius > _kSmallValue) {
            // Clip curved border for the view
            CGContextAddArc(ctx, layer->_bounds.size.width - layer->_cornerRadius, layer->_cornerRadius, layer->_cornerRadius, PI*1.5, 0 , NO);
            CGContextAddArc(ctx, layer->_bounds.size.width - layer->_cornerRadius, layer->_bounds.size.height - layer->_cornerRadius, layer->_cornerRadius, 0, PI/2 , NO);
            CGContextAddArc(ctx, layer->_cornerRadius, layer->_bounds.size.height - layer->_cornerRadius, layer->_cornerRadius, PI/2, PI, NO);
            CGContextAddArc(ctx, layer->_cornerRadius, layer->_cornerRadius, layer->_cornerRadius, PI, PI*1.5, NO);
        } else {
            CGContextAddRect(ctx, layer.bounds);
        }
        CGContextClip(ctx);
    }
}

static void _CALayerDrawBackground(CALayer *layer, CGContextRef ctx)
{
    if (layer->_backgroundColor) {
        CGContextSaveGState(ctx);
        const CGFloat *components = CGColorGetComponents(layer->_backgroundColor);
        CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], components[3]);
        CGContextFillRect(ctx, layer->_bounds);
        CGContextRestoreGState(ctx);
    }
}

static void _CALayerEndClip(CALayer *layer, CGContextRef ctx)
{
    // End the border clipping
    if (layer->_masksToBounds) {
        CGContextRestoreGState(ctx);
    }
}

static void _CALayerDrawBorder(CALayer *layer, CGContextRef ctx)
{
    // Draw the border if needed
    if (layer->_borderWidth > _kSmallValue) {
        CGContextSaveGState(ctx);
        CGContextSetLineWidth(ctx, layer->_borderWidth);
        CGColorRef myBorderColor = layer->_borderColor? : CGColorCreateGenericRGB(0,0,0,0); // default borderColor is clear color
        const CGFloat *components = CGColorGetComponents(myBorderColor);
        CGContextSetRGBStrokeColor(ctx, components[0], components[1], components[2], components[3]);
        if (layer->_cornerRadius > _kSmallValue) { // draw a curved rectangle
            CGFloat buffer = 1;
            CGFloat maxX = floorf(CGRectGetMaxX(layer->_bounds) - buffer);
            CGFloat maxY = floorf(CGRectGetMaxY(layer->_bounds) - buffer);
            CGFloat minX = floorf(CGRectGetMinX(layer->_bounds) + buffer);
            CGFloat minY = floorf(CGRectGetMinY(layer->_bounds) + buffer);
            CGContextBeginPath(ctx);
            CGContextAddArc(ctx, maxX - layer->_cornerRadius, minY + layer->_cornerRadius, layer->_cornerRadius, PI*1.5, 0 , NO);
            CGContextAddArc(ctx, maxX - layer->_cornerRadius, maxY - layer->_cornerRadius, layer->_cornerRadius, 0, PI/2 , NO);
            CGContextAddArc(ctx, minX + layer->_cornerRadius, maxY - layer->_cornerRadius, layer->_cornerRadius, PI/2, PI, NO);
            CGContextAddArc(ctx, minX + layer->_cornerRadius, minY + layer->_cornerRadius, layer->_cornerRadius, PI, PI*1.5, NO);
            CGContextClosePath(ctx);
            CGContextStrokePath(ctx);
        } else {
            CGContextStrokeRect(ctx, layer->_bounds);
        }
        if (!layer->_borderColor) {
            CGColorRelease(myBorderColor);
        }
        CGContextRestoreGState(ctx);
    }
}

#pragma mark - Layout

void _CALayerSetNeedsLayout(CALayer *layer)
{
    //DLog(@"layer: %@", layer);
    layer->_needsLayout = YES;
    _layersNeedLayout = YES;
    _CALayerSetNeedsComposite(layer);
}

#pragma mark - Display

void _CALayerDisplayIfNeeded(CALayer *layer)
{
    if (layer->_needsDisplay) {
        _CALayerDisplay(layer);
    }
}

void _CALayerSetNeedsDisplayWithRoot(CALayer *layer)
{
    if (!layer->_hidden) {
        //DLog(@"layer: %@", layer);
        _CALayerSetNeedsDisplay(layer);
        for (CALayer *sublayer in layer->_sublayers) {
            _CALayerSetNeedsDisplayWithRoot(sublayer);
        }
    }
}

void _CALayerSetNeedsUnload(CALayer *layer)
{
    //DLog(@"layer: %@", layer);
    layer->_needsUnload = YES;
    for (CALayer *sublayer in layer->_sublayers) {
        _CALayerSetNeedsUnload(sublayer);
    }
}

void _CALayerSetNeedsComposite(CALayer *layer)
{
    //DLog(@"layer: %@", layer);
    layer->_needsComposite = YES;
    _CATransactionCreateImplicitTransactionIfNeeded();
}

void _CALayerSetNeedsDisplay(CALayer *layer)
{
    //DLog(@"layer: %@", layer);
    layer->_needsDisplay = YES;
    //DLog(@"_needsDisplayLayers: %@", _needsDisplayLayers);
    CFSetAddValue(_needsDisplayLayers, layer);
    _CALayerSetNeedsComposite(layer);
}

void _CALayerDisplay(CALayer *layer)
{
    //DLog(@"layer: %@", layer);
    if (CGRectEqualToRect(layer->_bounds,CGRectZero)) {
        //DLog(@"CGRectZero layer: %@", layer);
        _CALayerSetNeedsUnload(layer);
        return;
    }
    if ([layer->delegate respondsToSelector:@selector(displayLayer:)]) {
        DLog();
        [layer->delegate displayLayer:layer];
    }
    //if (!layer->_contentsWasSet) {
    if (layer->_contents) {
        //DLog(@"layer: %@", layer);
        //DLog(@"layer->_contents: %@", layer->_contents);
        if (layer->_displayContents) {
            CGImageRelease(layer->_displayContents);
        }
        layer->_displayContents = CGImageCreateCopy(layer->_contents);
        //layer->_contents = nil;
        //layer->_contentsWasSet = YES;
    } else {
        //DLog(@"layer->_contentsScale: %0.2f", layer->_contentsScale);
        CGContextRef context = _CGBitmapContextCreateWithOptions(layer->_bounds.size, layer->_opaque, layer->_contentsScale);
        //DLog(@"layer->_contentsScale 2: %0.2f", layer->_contentsScale);
        CGContextScaleCTM(context, layer->_contentsScale, layer->_contentsScale);
        //DLog();
        _CALayerSetShadow(layer, context);
        //DLog();
        _CALayerSetClip(layer, context);
        _CALayerDrawBackground(layer, context);
        [layer drawInContext:context];
        _CALayerEndClip(layer, context);
        _CALayerDrawBorder(layer, context);
        
        //DLog();
        CGImageRelease(layer->_displayContents);
        layer->_displayContents = CGBitmapContextCreateImage(context);
        //DLog(@"layer->_displayContents: %@", layer->_displayContents);
        CGContextRelease(context);
    }
    layer->_needsDisplay = NO;
}

#pragma mark - Public methods

NSMutableArray *_CALayerGetRootLayers()
{
    return _rootLayers;
}

CALayer *_CALayerRootLayer()
{
    //DLog(@"_rootLayers: %@", _rootLayers);
    return CFArrayGetValueAtIndex(_rootLayers, 0);
}

CALayer *_CALayerRootOfLayer(CALayer *layer)
{
    while (layer->_superlayer) {
        layer = layer->_superlayer;
    }
    return layer;
}

CFIndex _CALayerIndexOfLayer(CALayer *layer)
{
    CFArrayRef sublayers = layer->_superlayer->_sublayers;
    CFRange range = {0, CFArrayGetCount(sublayers)};
    return CFArrayGetFirstIndexOfValue(sublayers, range, layer);
}

void _CALayerCopy(CALayer *toLayer, CALayer *fromLayer)
{
    //DLog(@"toLayer1: %@", toLayer);
    //DLog(@"fromLayer: %@", fromLayer);
    toLayer->delegate = fromLayer->delegate;
    toLayer->_layoutManager = fromLayer->_layoutManager;
    toLayer->_geometryFlipped = fromLayer->_geometryFlipped;
    toLayer->_opacity = fromLayer->_opacity;
    toLayer->_opaque = fromLayer->_opaque;
    toLayer->_position = fromLayer->_position;
    toLayer->_zPosition = fromLayer->_zPosition;
    toLayer->_bounds = fromLayer->_bounds;
    toLayer->_anchorPoint = fromLayer->_anchorPoint;
    toLayer->_backgroundColor = fromLayer->_backgroundColor;
    toLayer->_cornerRadius = fromLayer->_cornerRadius;
    toLayer->_borderWidth = fromLayer->_borderWidth;
    toLayer->_borderColor = fromLayer->_borderColor;
    toLayer->_shadowColor = fromLayer->_shadowColor;
    toLayer->_shadowOpacity = fromLayer->_shadowOpacity;
    toLayer->_shadowOffset = fromLayer->_shadowOffset;
    toLayer->_shadowRadius = fromLayer->_shadowRadius;
    toLayer->_shadowPath = fromLayer->_shadowPath;
    toLayer->_masksToBounds = fromLayer->_masksToBounds;
    toLayer->_contentsRect = fromLayer->_contentsRect;
    toLayer->_hidden = fromLayer->_hidden;
    toLayer->_contentsGravity = fromLayer->_contentsGravity;
    toLayer->_contentsScale = fromLayer->_contentsScale;
    toLayer->_transform = fromLayer->_transform;
    toLayer->_needsComposite = fromLayer->_needsComposite;
    toLayer->_contentsTransitionProgress = fromLayer->_contentsTransitionProgress;
    toLayer->_keyframesProgress = fromLayer->_keyframesProgress;
    
    toLayer->_beginTime = fromLayer->_beginTime;
    toLayer->_duration = fromLayer->_duration;
    toLayer->_repeatCount = fromLayer->_repeatCount;
    toLayer->_repeatDuration = fromLayer->_repeatDuration;
    toLayer->_autoreverses = fromLayer->_autoreverses;
    toLayer.fillMode = fromLayer->_fillMode;
    toLayer->_speed = fromLayer->_speed;
    toLayer->_timeOffset = fromLayer->_timeOffset;
    //DLog(@"toLayer: %@", toLayer);
}

void _CALayerRemoveExpiredAnimations(CALayer *layer)
{
    NSArray *keys = [layer->_animations allKeys];
    for (NSString *key in keys) {
        CAAnimation *animation = [layer animationForKey:key];
        if ([animation isKindOfClass:[CAPropertyAnimation class]]) {
            CAPropertyAnimation *propertyAnimation = (CAPropertyAnimation *)animation;
            if (propertyAnimation->_remove) {
                [layer removeAnimationForKey:propertyAnimation->keyPath];
            }
        }
    }
}

CFTimeInterval _CALayerGetLocalTimeWithRootLayer(CALayer *layer, CALayer *rootLayer, CFTimeInterval timeInRootLayer)
{
    if (layer->_superlayer) {
        CFTimeInterval tp = _CALayerGetLocalTimeWithRootLayer(layer->_superlayer, rootLayer, timeInRootLayer);
        return (tp - layer->_beginTime) * layer->_speed + layer->_timeOffset;
    } else {
        if (layer == rootLayer) {
            return timeInRootLayer;
        } else {
            return 0;
        }
    }
}

NSString *_StringFromRGBComponents(const CGFloat *components)
{
    return [NSString stringWithFormat:@"<%0.1f, %0.1f, %0.1f, %0.1f>", components[0], components[1], components[2], components[3]];
}
