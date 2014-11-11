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

#import <CoreAnimation/CALayer.h>

@interface CALayer (PresentationLayer)

- (id)initWithModelLayer:(CALayer *)layer;

@end

// CALayer

void _CALayerRemoveFromSuperlayer(CALayer *layer);
void _CALayerAddSublayer(CALayer *layer, CALayer *sublayer, CFIndex index);
void _CALayerCopyAnimations(CALayer *layer);
void _CALayerApplyAnimations(CALayer *layer);
