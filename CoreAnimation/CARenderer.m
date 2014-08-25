/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <CoreAnimation/CoreAnimation-private.h>

CFMutableSetRef _needsDisplayLayers;
CFMutableSetRef _needsDisplayPresentationLayers;
static CFMutableSetRef _needsLoadRenderLayers;

// CARenderer draws Layer Tree content by calling its layers' display.
// CALayer is the model, Presentation Layer is the view, CATransaction, CARenderer, CACompositor and CAAnimator are the controllers.
@implementation CARenderer

@end

#pragma mark - Private C functions

void _CARendererInitialize()
{
    _needsDisplayLayers = CFSetCreateMutable(kCFAllocatorDefault, 10, &kCFTypeSetCallBacks);
    _needsDisplayPresentationLayers = CFSetCreateMutable(kCFAllocatorDefault, 10, &kCFTypeSetCallBacks);
    _needsLoadRenderLayers = CFSetCreateMutable(kCFAllocatorDefault, 10, &kCFTypeSetCallBacks);
}

void _CARendererDisplayLayers(BOOL isModelLayer)
{
    CFMutableSetRef displayLayers;
    if (isModelLayer) {
        displayLayers = _needsDisplayLayers;
    } else {
        displayLayers = _needsDisplayPresentationLayers;
    }
    for (CALayer *layer in displayLayers) {
        //DLog(@"[NSThread currentThread]: %@", [NSThread currentThread]);
        _CALayerDisplay(layer);
        if (layer->_displayContents) {
            CARenderLayer *renderLayer = (CARenderLayer *)layer->_renderLayer;
            if (renderLayer) {
                CFSetAddValue(_needsLoadRenderLayers, renderLayer);
                renderLayer->_oldContents = layer->_oldContents;
                renderLayer->_displayContents = layer->_displayContents;
                layer->_oldContents = nil;
                layer->_displayContents = nil;
                //DLog(@"renderLayer: %@, _oldContents: %@", renderLayer, renderLayer->_oldContents);
            }
        }
    }
    CFSetRemoveAllValues(displayLayers);
    //_CARendererLoadRenderLayers();
}

void _CARendererLoadRenderLayers()
{
    for (CARenderLayer *layer in _needsLoadRenderLayers) {
        //DLog(@"layer->presentationLayer->_contentsTransitionProgress: %f", layer->presentationLayer->_contentsTransitionProgress);
        if (layer->_oldContents) {
            _CABackingStoreLoad(layer->oldBackingStore, layer->_oldContents);
            CGImageRelease(layer->_oldContents);
            layer->_oldContents = nil;
        }
        _CABackingStoreLoad(layer->backingStore, layer->_displayContents);
        CGImageRelease(layer->_displayContents);
        layer->_displayContents = nil;
    }
    CFSetRemoveAllValues(_needsLoadRenderLayers);
}

