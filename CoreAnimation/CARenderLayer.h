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

@class CALayer, CABackingStore;

// CARenderLayer is a node in the Render Tree.
// In animation thread world, Presentation Layer is the model, CARenderLayer is the view, CATransaction, CACompositor and CAAnimator are the controllers.
// Will use from CALayer superclass: opaque, position, anchorPoint, bounds, contentsRect, contentsCenter, masksToBounds, _displayContents, ...
// CARenderLayer has the n state of the animated window, while Presentation Layer has the n+1 state of the animated window.
@interface CARenderLayer : CALayer {
@package
    CABackingStore *_oldBackingStore;
    CABackingStore *_backingStore;
    CGRect _rectNeedsComposite;
}

@end

void _CARenderLayerCopy(CARenderLayer *renderLayer, CALayer *presentationLayer);
CARenderLayer *_CARenderLayerClosestOpaqueLayerFromLayer(CARenderLayer *layer);
CGRect _CARenderLayerApplyMasksToBoundsToRect(CALayer *layer, CALayer *ancestorLayer, CGRect rect);
void _CARenderLayerSetNeedsCompositeInRect(CARenderLayer *rootLayer, CARenderLayer *opaqueLayer, CGRect r);
void _CARenderLayerCompositeIfNeeded(CARenderLayer *layer);
void _CARenderLayerUnload(CARenderLayer *layer);

