/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <CoreAnimation/CALayer.h>

@interface CALayer (PresentationLayer)

- (id)initWithModelLayer:(CALayer *)layer;

@end

// CALayer

void _CALayerRemoveFromSuperlayer(CALayer *layer);
void _CALayerAddSublayer(CALayer *layer, CALayer *sublayer, CFIndex index);
void _CALayerCopyAnimations(CALayer *layer);
void _CALayerApplyAnimations(CALayer *layer);
