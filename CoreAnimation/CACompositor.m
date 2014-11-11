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
#import <IOKit/IOKit.h>

static CGRect _compositeRect;

#pragma mark - Static functions

// Copy Presentation Tree to Render Tree
static void _CACompositorCopyTree(CALayer *layer)
{
    //DLog(@"layer: %@", layer);
    CARenderLayer *renderLayer = (CARenderLayer *)layer->_renderLayer;
    if (layer->_needsComposite) {
        _CARenderLayerCopy(renderLayer, layer);
    }
    for (CALayer *sublayer in layer->_sublayers) {
        _CACompositorCopyTree(sublayer);
    }
}

static void _CACompositorAddCompositeRectOfLayer(CARenderLayer *layer)
{
    CARenderLayer *rootLayer = (CARenderLayer *)_CALayerRootLayer()->_renderLayer;
    CGRect layerBounds = _CARenderLayerApplyMasksToBoundsToRect(layer, layer->_superlayer, layer->_bounds);
    CGRect rectInRootLayer = [layer convertRect:layerBounds toLayer:rootLayer];
    _compositeRect = CGRectUnion(_compositeRect, rectInRootLayer);
}

static void _CACompositorUpdateCompositeRect(CALayer *layer)
{
    if (layer->_needsComposite) {
        _CACompositorAddCompositeRectOfLayer((CARenderLayer *)layer->_renderLayer);
    }
    for (CALayer *sublayer in layer->_sublayers) {
        _CACompositorUpdateCompositeRect(sublayer);
    }
}

static void _CACompositorAddCompositeRectToLayer(CARenderLayer *layer)
{
    CARenderLayer *rootLayer = (CARenderLayer *)_CALayerRootLayer()->_renderLayer;
    CARenderLayer *opaqueLayer = _CARenderLayerClosestOpaqueLayerFromLayer(layer);
    CGRect boundsInOpaqueLayer = [rootLayer convertRect:_compositeRect toLayer:opaqueLayer];
    while (!CGRectEqualToRect(opaqueLayer->_bounds, CGRectUnion(opaqueLayer->_bounds, boundsInOpaqueLayer)) && opaqueLayer->_superlayer) {
        opaqueLayer = (CARenderLayer *)opaqueLayer->_superlayer;
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
    for (CALayer *sublayer in layer->_sublayers) {
        _CACompositorUpdateCompositeRects(sublayer);
    }
}

// Traversing depth first search
static void _CACompositorCompositeTreeRecursive(CARenderLayer *layer)
{
    for (CARenderLayer *sublayer in layer->_sublayers) {
        //DLog(@"sublayer: %@", sublayer);
        if (!sublayer->_hidden) {
            _CARenderLayerCompositeIfNeeded(sublayer);
            _CACompositorCompositeTreeRecursive(sublayer);
        }
    }
}

static void _CACompositorCompositeTree(CARenderLayer *rootRenderLayer)
{
    if (!rootRenderLayer->_hidden) {
        //DLog(@"rootRenderLayer: %@", rootRenderLayer);
        _CARenderLayerCompositeIfNeeded(rootRenderLayer);
        _CACompositorCompositeTreeRecursive(rootRenderLayer);
    }
}

static void _CACompositorCleanPresentationTree(CALayer *layer)
{
    if (layer->_needsComposite) {
        //DLog();
        if (![layer->_animations count]) {
            layer->_needsComposite = NO;
        }
    }
    for (CALayer *sublayer in layer->_sublayers) {
        _CACompositorCleanPresentationTree(sublayer);
    }
}

static void _CACompositorCleanRenderTree(CARenderLayer *layer)
{
    layer->_rectNeedsComposite = CGRectZero;
    for (CARenderLayer *sublayer in layer->_sublayers) {
        _CACompositorCleanRenderTree(sublayer);
    }
}

// CACompositor composites Render Tree to the screen window
@implementation CACompositor

@end

#pragma mark - Shared functions

void _CACompositorInitialize()
{
    IOWindow *screenWindow = IOWindowGetSharedWindow();
    _compositeRect = CGRectMake(0,0,screenWindow->_rect.size.width, screenWindow->_rect.size.height);
}

void _CACompositorPrepareComposite()
{
    //DLog();
    CALayer *rootPresentationLayer = _CALayerRootLayer()->_presentationLayer;
    //if (_firstBuffer) {
    //CGRect _tempRect = _compositeRect;
    //_compositeRect = CGRectZero;
    //_oldCompositeRect = _tempRect;
    //_CACompositorUpdateCompositeRect(rootPresentationLayer);
    //}
    //DLog(@"_CACompositorCopyTree");
    _CACompositorCopyTree(rootPresentationLayer);
    //_CACompositorUpdateCompositeRect(rootPresentationLayer);
    //DLog(@"_CACompositorUpdateCompositeRects");
    _CACompositorUpdateCompositeRects(rootPresentationLayer);
    //if (!_firstBuffer) {
    //DLog(@"_CACompositorCleanPresentationTree");
    _CACompositorCleanPresentationTree(rootPresentationLayer);
    //}
    //DLog(@"_compositeRect: %@", NSStringFromRect(NSRectFromCGRect(_compositeRect)));
    //_firstBuffer = !_firstBuffer;
}

void _CACompositorComposite()
{
    //DLog();
    CARenderLayer *rootRenderLayer = (CARenderLayer *)_CALayerRootLayer()->_renderLayer;
    _CACompositorCompositeTree(rootRenderLayer);
    //DLog();
    _CACompositorCleanRenderTree(rootRenderLayer);
    //DLog();
}
