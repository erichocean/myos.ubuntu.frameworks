/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

@class CALayer, CABackingStore;

// CARenderLayer is a node in the Render Tree.
// In animation thread world, Presentation Layer is the model, CARenderLayer is the view, CATransaction, CACompositor and CAAnimator are the controllers.
// Will use from CALayer superclass: opaque, position, anchorPoint, bounds, contentsRect, contentsCenter, masksToBounds, _displayContents, ...
// CARenderLayer has the n state of the animated window, while Presentation Layer has the n+1 state of the animated window.
@interface CARenderLayer : CALayer
{
@package
    CABackingStore *oldBackingStore;
    CABackingStore *backingStore;
    CGRect rectNeedsComposite;
}

//@property (nonatomic, retain) id oldBackingStore;

- (id)initWithPresentationLayer:(CALayer *)layer;

@end

void _CARenderLayerCopy(CARenderLayer *renderLayer, CALayer *presentationLayer);
CARenderLayer *_CARenderLayerClosestOpaqueLayerFromLayer(CARenderLayer *layer);
CGRect _CARenderLayerApplyMasksToBoundsToRect(CALayer *layer, CALayer *ancestorLayer, CGRect rect);
void _CARenderLayerSetNeedsCompositeInRect(CARenderLayer *rootLayer, CARenderLayer *opaqueLayer, CGRect r);
void _CARenderLayerCompositeIfNeeded(CARenderLayer *layer);
void _CARenderLayerUnload(CARenderLayer *layer);

