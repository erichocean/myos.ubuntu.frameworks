/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <UIKit/UIGeometry.h>
#import <CoreAnimation/CALayer.h>
#import <CoreAnimation/CAAnimation.h>

extern CFMutableArrayRef _rootLayers;

void _CALayerSetNeedsComposite(CALayer *layer);
void _CALayerDisplayIfNeeded(CALayer *layer);
void _CALayerSetNeedsDisplay(CALayer *layer);
void _CALayerSetNeedsUnload(CALayer *layer);
void _CALayerSetNeedsDisplayWithRoot(CALayer *layer);
NSMutableArray *_CALayerGetRootLayers();
void _CALayerDisplay(CALayer *layer);
CALayer *_CALayerRootLayer();
CALayer *_CALayerRootOfLayer(CALayer *layer);
CFIndex _CALayerIndexOfLayer(CALayer *layer);
void _CALayerCopy(CALayer *toLayer, CALayer *fromLayer);
void _CALayerRemoveExpiredAnimations(CALayer *layer);
NSString *_StringFromRGBComponents(const CGFloat* components);
NSArray *_CALayerGetDictionaryKeys(CFDictionaryRef dictionary);
CFTimeInterval _CALayerGetLocalTimeWithRootLayer(CALayer *layer, CALayer *rootLayer, CFTimeInterval timeInRootLayer);

