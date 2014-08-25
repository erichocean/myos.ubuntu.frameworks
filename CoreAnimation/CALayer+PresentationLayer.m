/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <CoreGraphics/CGBitmapContext-private.h>
#import <CoreAnimation/CoreAnimation-private.h>

// Presentation Layer is a node in the Presentation Tree
@implementation CALayer (PresentationLayer)

#pragma mark - Life cycle

- (id)initWithModelLayer:(CALayer *)layer
{
    self = [self initWithLayer:layer];
    if (self) {
        _needsComposite = NO;
        modelLayer = layer;
        modelLayer->presentationLayer = self;
        _renderLayer = nil;//[[CARenderLayer alloc] initWithPresentationLayer:self];
        _CALayerCopyAnimations(self);
    }
    return self;
}

@end

#pragma mark - Private C functions

#pragma mark - CALayer

void _CALayerRemoveFromSuperlayer(CALayer *layer)
{
    if (layer->superlayer) {
        //[layer->superlayer->sublayers removeObject:layer];
        _CFArrayRemoveValue(layer->superlayer->sublayers, layer);
        layer->superlayer = nil;
    }
}

void _CALayerAddSublayer(CALayer *layer, CALayer *sublayer, CFIndex index)
{
    //if (sublayer) { // && sublayer->superlayer != layer) {
        //DLog(@"sublayer: %@", sublayer);
    _CALayerRemoveFromSuperlayer(sublayer);

    if (index >= CFArrayGetCount(layer->sublayers)) {
        CFArrayAppendValue(layer->sublayers, sublayer);
    } else {
        CFArrayInsertValueAtIndex(layer->sublayers, index, sublayer);
    }
    sublayer->superlayer = layer;
}

void _CALayerCopyAnimations(CALayer *layer)
{
    //if (CFDictionaryGetCount(layer->modelLayer->_animations)) {
        //DLog(@"count: %d", CFDictionaryGetCount(layer->modelLayer->_animations));
    if ([layer->modelLayer->_animations count]) {
        if (layer->_animations) {
            [layer->_animations release];
        }
        layer->_animations = [[NSMutableDictionary alloc] initWithDictionary:layer->modelLayer->_animations]; //CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 10, layer->modelLayer->_animations);
        CFArrayRef keys = [layer animationKeys];
        for (NSString *key in keys) {
            CAAnimation *theAnimation = [layer animationForKey:key];
            if ([theAnimation isKindOfClass:[CABasicAnimation class]]) {
                CABasicAnimation *animation = (CABasicAnimation *)theAnimation;
                if (!animation->toValue) {
                    animation.toValue = [layer->modelLayer valueForKeyPath:animation->keyPath];
                }
            }
        }
    }
    //DLog(@"_animations: %@", layer->_animations);
}

void _CALayerApplyAnimations(CALayer *layer)
{
    //CGRect bounds = layer->bounds;
    CFTimeInterval time = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
    //if (CFDictionaryGetCount(layer->_animations)) {
    if ([layer->_animations count]) {
        //DLog(@"layer->_animations: %@", layer->_animations);
        CFArrayRef keys = [layer animationKeys];
        //DLog(@"keys: %@", keys);
        for (NSString *key in keys) {
            // Adjust animation begin time
            CAAnimation *animation = [layer animationForKey:key];
            _CAAnimationApplyAnimationForLayer(animation, layer, time);
        }
    }
}

