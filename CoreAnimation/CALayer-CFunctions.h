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

#import <UIKit/UIGeometry.h>
#import <CoreAnimation/CALayer.h>
#import <CoreAnimation/CAAnimation.h>

extern CFMutableArrayRef _rootLayers;

void _CALayerSetNeedsComposite(CALayer *layer);
void _CALayerDisplayIfNeeded(CALayer *layer);
void _CALayerSetNeedsLayout(CALayer *layer);
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

