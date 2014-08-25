/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <CoreAnimation/CoreAnimation-private.h>

static CGRect _compositeRect;
//static BOOL _needsFlush;

#pragma mark - Static C functions

// Copy Presentation Tree to Render Tree
static void _CACompositorCopyTree(CALayer *layer)
{
    CARenderLayer *renderLayer = (CARenderLayer *)layer->_renderLayer;
    if (layer->_needsComposite) {
        _CARenderLayerCopy(renderLayer, layer);
    }
    for (CALayer *sublayer in layer->sublayers) {
        _CACompositorCopyTree(sublayer);
    }
}

static void _CACompositorAddCompositeRectOfLayer(CARenderLayer *layer)
{
    CARenderLayer *rootLayer = (CARenderLayer *)_CALayerRootLayer()->_renderLayer;
    CGRect layerBounds = _CARenderLayerApplyMasksToBoundsToRect(layer, layer->superlayer, layer->bounds);
    CGRect rectInRootLayer = [layer convertRect:layerBounds toLayer:rootLayer];
    _compositeRect = CGRectUnion(_compositeRect, rectInRootLayer);
}

static void _CACompositorUpdateCompositeRect(CALayer *layer)
{
    if (layer->_needsComposite) {
        _CACompositorAddCompositeRectOfLayer((CARenderLayer *)layer->_renderLayer);
    }
    for (CALayer *sublayer in layer->sublayers) {
        _CACompositorUpdateCompositeRect(sublayer);
    }
}

static void _CACompositorAddCompositeRectToLayer(CARenderLayer *layer)
{
    //CARenderLayer *rootLayer = (CARenderLayer *)presentationLayer->_renderLayer;
    CARenderLayer *rootLayer = (CARenderLayer *)_CALayerRootLayer()->_renderLayer;
    //CGRect rectInRootLayer = [layer convertRect:layer->bounds toLayer:rootLayer];
    //_compositeRect = CGRectUnion(_compositeRect, rectInRootLayer);
    CARenderLayer *opaqueLayer = _CARenderLayerClosestOpaqueLayerFromLayer(layer);
    CGRect boundsInOpaqueLayer = [rootLayer convertRect:_compositeRect toLayer:opaqueLayer];
    while (!CGRectEqualToRect(opaqueLayer->bounds, CGRectUnion(opaqueLayer->bounds, boundsInOpaqueLayer)) && opaqueLayer->superlayer) {
        opaqueLayer = (CARenderLayer *)opaqueLayer->superlayer;
        boundsInOpaqueLayer = [rootLayer convertRect:_compositeRect toLayer:opaqueLayer];
    }
    _CARenderLayerSetNeedsCompositeInRect(rootLayer, opaqueLayer, boundsInOpaqueLayer);
}

static void _CACompositorUpdateCompositeRects(CALayer *layer)
{
    if (layer->_needsComposite) {
        //DLog(@"layer: %@", layer);
        _CACompositorAddCompositeRectToLayer((CARenderLayer *)layer->_renderLayer);
    }
    for (CALayer *sublayer in layer->sublayers) {
        _CACompositorUpdateCompositeRects(sublayer);
    }
}

// Traversing depth first search
static void _CACompositorCompositeTreeRecursive(CARenderLayer *layer)
{
    for (CARenderLayer *sublayer in layer->sublayers) {
        if (!sublayer->hidden) {
            _CARenderLayerCompositeIfNeeded(sublayer);
            _CACompositorCompositeTreeRecursive(sublayer);
        }
    }
}

static void _CACompositorCompositeTree(CARenderLayer *rootRenderLayer)
{
    //_needsFlush = NO;
    if (!rootRenderLayer->hidden) {
        _CARenderLayerCompositeIfNeeded(rootRenderLayer);
        _CACompositorCompositeTreeRecursive(rootRenderLayer);
    }
    /*if (_needsFlush) {
        //_CAAnimatorFrameCount++;
        //DLog(@"_needsFlush");
        _EAGLFlush();
    }*/
    //CGContextRestoreGState(_offlineWindowContext);
}

static void _CACompositorCleanPresentationTree(CALayer *layer)
{
    if (layer->_needsComposite) {
        if (![layer->_animations count]) {
            layer->_needsComposite = NO;
        }
    }
    for (CALayer *sublayer in layer->sublayers) {
        _CACompositorCleanPresentationTree(sublayer);
    }
}

static void _CACompositorCleanRenderTree(CARenderLayer *layer)
{
    layer->rectNeedsComposite = CGRectZero;
    for (CARenderLayer *sublayer in layer->sublayers) {
        _CACompositorCleanRenderTree(sublayer);
    }
}

// CACompositor composites Render Tree to the screen window
@implementation CACompositor

@end

#pragma mark - Private C functions

void _CACompositorPrepareComposite()
{
    CALayer *rootPresentationLayer = _CALayerRootLayer()->presentationLayer;
    _compositeRect = CGRectZero;
    _CACompositorUpdateCompositeRect(rootPresentationLayer);
    //DLog(@"CopyTreeWithRoot");
    _CACompositorCopyTree(rootPresentationLayer);
    _CACompositorUpdateCompositeRect(rootPresentationLayer);
    //DLog(@"_compositeRect: %@", NSStringFromCGRect(_compositeRect));
    _CACompositorUpdateCompositeRects(rootPresentationLayer);
    _CACompositorCleanPresentationTree(rootPresentationLayer);
}

void _CACompositorComposite()
{
    //DLog();
    CALayer *rootPresentationLayer = _CALayerRootLayer()->presentationLayer;
    CARenderLayer *rootRenderLayer = (CARenderLayer *)rootPresentationLayer->_renderLayer;
    //DLog(@"CompositeTree");
    _CACompositorCompositeTree(rootRenderLayer);
    //DLog(@"CleanTreeWithRoot");
    //_CACompositorCleanTree(rootPresentationLayer);
    _CACompositorCleanRenderTree(rootRenderLayer);
}
/*
void _CACompositorNeedsFlush(BOOL needsFlush)
{
    _needsFlush = needsFlush;
}*/

