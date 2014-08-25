/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <CoreAnimation/CoreAnimation-private.h>

CFMutableArrayRef _rootLayers;

#pragma mark - Static functions

static void _CALayerSetShadow(CALayer *layer, CGContextRef ctx)
{
    // Preparation for shadow if needed
    if (!layer->masksToBounds && layer->shadowOpacity > _kSmallValue) {
        // Set the translation for the above shadow
        CGContextSaveGState(ctx);
        CGContextTranslateCTM(ctx, layer->shadowOffset.width<0 ? -layer->shadowOffset.width + layer->shadowRadius : 0,
                              layer->shadowOffset.height<0 ? -layer->shadowOffset.height + layer->shadowRadius: 0);
        //CGContextSaveGState(ctx);
        CGContextSetShadow(ctx, layer->shadowOffset,layer->shadowRadius);
        CGContextRestoreGState(ctx);
    }
}

static void _CALayerSetClip(CALayer *layer, CGContextRef ctx)
{
    // clipping the view
    if (layer->masksToBounds) {
        CGContextSaveGState(ctx);
        CGContextBeginPath(ctx);
        if (layer->cornerRadius > _kSmallValue) {
            // Clip curved border for the view
            CGContextAddArc(ctx, layer->bounds.size.width - layer->cornerRadius, layer->cornerRadius, layer->cornerRadius, PI*1.5, 0 , NO);
            CGContextAddArc(ctx, layer->bounds.size.width - layer->cornerRadius, layer->bounds.size.height - layer->cornerRadius, layer->cornerRadius, 0, PI/2 , NO);
            CGContextAddArc(ctx, layer->cornerRadius, layer->bounds.size.height - layer->cornerRadius, layer->cornerRadius, PI/2, PI, NO);
            CGContextAddArc(ctx, layer->cornerRadius, layer->cornerRadius, layer->cornerRadius, PI, PI*1.5, NO);
        } else {
            CGContextAddRect(ctx, layer.bounds);
        }
        CGContextClip(ctx);
    }
}

static void _CALayerDrawBackground(CALayer *layer, CGContextRef ctx)
{
    if (layer->backgroundColor) {
        CGContextSaveGState(ctx);
        const CGFloat *components = CGColorGetComponents(layer->backgroundColor);
        CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], components[3]);
        CGContextFillRect(ctx, layer->bounds);
        CGContextRestoreGState(ctx);
    } /*else {
    }*/
}

static void _CALayerEndClip(CALayer *layer, CGContextRef ctx)
{
    // End the border clipping
    if (layer->masksToBounds) {
        CGContextRestoreGState(ctx);
    }
}

static void _CALayerDrawBorder(CALayer *layer, CGContextRef ctx)
{
    // Draw the border if needed
    if (layer->borderWidth > _kSmallValue) {
        CGContextSaveGState(ctx);
        CGContextSetLineWidth(ctx, layer->borderWidth);
        CGColorRef myBorderColor = layer->borderColor? : CGColorCreateGenericRGB(0,0,0,0); // default borderColor is clear color
        const CGFloat *components = CGColorGetComponents(myBorderColor);
        CGContextSetRGBStrokeColor(ctx, components[0], components[1], components[2], components[3]);
        if (layer->cornerRadius > _kSmallValue) { // draw a curved rectangle
            CGFloat buffer = 1;
            CGFloat maxX = floorf(CGRectGetMaxX(layer->bounds) - buffer);
            CGFloat maxY = floorf(CGRectGetMaxY(layer->bounds) - buffer);
            CGFloat minX = floorf(CGRectGetMinX(layer->bounds) + buffer);
            CGFloat minY = floorf(CGRectGetMinY(layer->bounds) + buffer);
            CGContextBeginPath(ctx);
            CGContextAddArc(ctx, maxX - layer->cornerRadius, minY + layer->cornerRadius, layer->cornerRadius, PI*1.5, 0 , NO);
            CGContextAddArc(ctx, maxX - layer->cornerRadius, maxY - layer->cornerRadius, layer->cornerRadius, 0, PI/2 , NO);
            CGContextAddArc(ctx, minX + layer->cornerRadius, maxY - layer->cornerRadius, layer->cornerRadius, PI/2, PI, NO);
            CGContextAddArc(ctx, minX + layer->cornerRadius, minY + layer->cornerRadius, layer->cornerRadius, PI, PI*1.5, NO);
            CGContextClosePath(ctx);
            CGContextStrokePath(ctx);
        } else {
            CGContextStrokeRect(ctx, layer->bounds);
        }
        if (!layer->borderColor) {
            CGColorRelease(myBorderColor);
        }
        CGContextRestoreGState(ctx);
    }
}

#pragma mark - Display

void _CALayerDisplayIfNeeded(CALayer *layer)
{
    if (layer->needsDisplay) {
        _CALayerDisplay(layer);
    }
}

void _CALayerSetNeedsDisplayWithRoot(CALayer *layer)
{
    _CALayerSetNeedsDisplay(layer);
    for (CALayer *sublayer in layer->sublayers) {
        _CALayerSetNeedsDisplayWithRoot(sublayer);
    }
}

void _CALayerSetNeedsUnload(CALayer *layer)
{
    layer->_needsUnload = YES;
    for (CALayer *sublayer in layer->sublayers) {
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
    layer->needsDisplay = YES;
    CFSetAddValue(_needsDisplayLayers, layer);
    //_CARendererAddToDisplayLayers(layer);
    _CALayerSetNeedsComposite(layer);
}

void _CALayerDisplay(CALayer *layer)
{
    if (CGRectEqualToRect(layer->bounds,CGRectZero)) {
        _CALayerSetNeedsUnload(layer);
        return;
    }
    if ([layer->delegate respondsToSelector:@selector(displayLayer:)]) {
        [layer->delegate displayLayer:layer];
    }
    if (layer->contents) {
        if (layer->_displayContents) {
            CGImageRelease(layer->_displayContents);
        }
        layer->_displayContents = CGImageCreateCopy(layer->contents);
    } else {
        CGContextRef context = _CGBitmapContextCreateWithOptions(layer->bounds.size, layer->opaque, layer->contentsScale);

        _CALayerSetShadow(layer, context);
        _CALayerSetClip(layer, context);
        _CALayerDrawBackground(layer, context);
        [layer drawInContext:context];
        _CALayerEndClip(layer, context);
        _CALayerDrawBorder(layer, context);

        CGImageRelease(layer->_displayContents);
        layer->_displayContents = CGBitmapContextCreateImage(context);
        CGContextRelease(context);
    }
    layer->needsDisplay = NO;
}

#pragma mark - Helpers

NSMutableArray *_CALayerGetRootLayers()
{
    return _rootLayers;
}

CALayer *_CALayerRootLayer()
{
    return CFArrayGetValueAtIndex(_rootLayers, 0);
}

CALayer *_CALayerRootOfLayer(CALayer *layer)
{
    while (layer->superlayer) {
        layer = layer->superlayer;
    }
    return layer;
}

CFIndex _CALayerIndexOfLayer(CALayer *layer)
{
    CFArrayRef sublayers = layer->superlayer->sublayers;
    CFRange range = {0, CFArrayGetCount(sublayers)};
    return CFArrayGetFirstIndexOfValue(sublayers, range, layer);
}

void _CALayerCopy(CALayer *toLayer, CALayer *fromLayer)
{
    toLayer->delegate = fromLayer->delegate;
    toLayer->layoutManager = fromLayer->layoutManager;
    toLayer->geometryFlipped = fromLayer->geometryFlipped;
    toLayer->opacity = fromLayer->opacity;
    toLayer->opaque = fromLayer->opaque;
    toLayer->position = fromLayer->position;
    toLayer->zPosition = fromLayer->zPosition;
    toLayer->bounds = fromLayer->bounds;
    toLayer->anchorPoint = fromLayer->anchorPoint;
    toLayer->backgroundColor = fromLayer->backgroundColor;
    toLayer->cornerRadius = fromLayer->cornerRadius;
    toLayer->borderWidth = fromLayer->borderWidth;
    toLayer->borderColor = fromLayer->borderColor;
    toLayer->shadowColor = fromLayer->shadowColor;
    toLayer->shadowOpacity = fromLayer->shadowOpacity;
    toLayer->shadowOffset = fromLayer->shadowOffset;
    toLayer->shadowRadius = fromLayer->shadowRadius;
    toLayer->shadowPath = fromLayer->shadowPath;
    toLayer->masksToBounds = fromLayer->masksToBounds;
    toLayer->contentsRect = fromLayer->contentsRect;
    toLayer->hidden = fromLayer->hidden;
    toLayer->contentsGravity = fromLayer->contentsGravity;
    toLayer->contentsScale = fromLayer->contentsScale;
    toLayer->transform = fromLayer->transform;
    toLayer->_needsComposite = fromLayer->_needsComposite;
    toLayer->_contentsTransitionProgress = fromLayer->_contentsTransitionProgress;
    
    toLayer->beginTime = fromLayer->beginTime;
    toLayer->duration = fromLayer->duration;
    toLayer->repeatCount = fromLayer->repeatCount;
    toLayer->repeatDuration = fromLayer->repeatDuration;
    toLayer->autoreverses = fromLayer->autoreverses;
    toLayer.fillMode = fromLayer->fillMode;
    toLayer->speed = fromLayer->speed;
    toLayer->timeOffset = fromLayer->timeOffset;
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
    if (layer->superlayer) {
        CFTimeInterval tp = _CALayerGetLocalTimeWithRootLayer(layer->superlayer, rootLayer, timeInRootLayer);
        return (tp - layer->beginTime) * layer->speed + layer->timeOffset;
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

