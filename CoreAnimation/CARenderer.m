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

CFMutableSetRef _needsDisplayLayers;
CFMutableSetRef _needsDisplayPresentationLayers;
static CFMutableSetRef _needsLoadRenderLayers;

// CARenderer draws Layer Tree content by calling its layers' display.
// CALayer is the model, Presentation Layer is the view, CATransaction, CARenderer, CACompositor and CAAnimator are the controllers.
@implementation CARenderer

@end

#pragma mark - Shared functions

void _CARendererInitialize()
{
    //DLog(@"");
    _needsDisplayLayers = CFSetCreateMutable(kCFAllocatorDefault, 10, &kCFTypeSetCallBacks);
    _needsDisplayPresentationLayers = CFSetCreateMutable(kCFAllocatorDefault, 10, &kCFTypeSetCallBacks);
    _needsLoadRenderLayers = CFSetCreateMutable(kCFAllocatorDefault, 10, &kCFTypeSetCallBacks);
}

void _CARendererDisplayLayers(BOOL isModelLayer)
{
    CFMutableSetRef displayLayers;
    if (isModelLayer) {
        displayLayers = _needsDisplayLayers;
        //DLog(@"displayLayers: %@", displayLayers);
    } else {
        displayLayers = _needsDisplayPresentationLayers;
    }
    //DLog(@"displayLayers: %@", displayLayers);
    //DLog(@"_needsLoadRenderLayers: %@", _needsLoadRenderLayers);
    //DLog(@"[displayLayers className]: %@", [displayLayers className]);
    for (CALayer *layer in displayLayers) {
        _CALayerDisplay(layer);
        //DLog();
        if (layer->_displayContents) {
            CARenderLayer *renderLayer = (CARenderLayer *)layer->_renderLayer;
            if (renderLayer) {
                //DLog(@"renderLayer.retainCount: %d", renderLayer.retainCount);
                CFSetAddValue(_needsLoadRenderLayers, renderLayer);
                //DLog(@"renderLayer.retainCount: %d", renderLayer.retainCount);
                renderLayer->_oldContents = layer->_oldContents;
                renderLayer->_displayContents = layer->_displayContents;
                renderLayer->_keyframesContents = layer->_keyframesContents;
                layer->_oldContents = nil;
                layer->_displayContents = nil;
                layer->_keyframesContents = nil;
                //DLog(@"layer: %@", layer);
                //DLog(@"renderLayer: %@", renderLayer);
            } else {
                DLog(@"no renderLayer - layer: %@", layer);
            }
        } else {
                DLog(@"no layer->_displayContents - layer: %@", layer);
        }
    }
    //DLog(@"displayLayers.count: %d", displayLayers.count);
    //DLog(@"_needsLoadRenderLayers: %@", _needsLoadRenderLayers);
    //DLog(@"_needsLoadRenderLayers.count: %d", _needsLoadRenderLayers.count);
    CFSetRemoveAllValues(displayLayers);
    //DLog();
}

void _CARendererLoadRenderLayers()
{
    //DLog();
    //DLog(@"_needsLoadRenderLayers: %@", _needsLoadRenderLayers);
    //DLog(@"_needsLoadRenderLayers.count: %d", _needsLoadRenderLayers.count);
    for (CARenderLayer *layer in _needsLoadRenderLayers) {
        //DLog(@"layer: %@", layer);
        //DLog(@"layer->_presentationLayer->_contentsTransitionProgress: %f", layer->_presentationLayer->_contentsTransitionProgress);
        if (layer->_keyframesContents) {
            //DLog(@"layer->_keyframesContents: %@", layer->_keyframesContents);
            _CABackingStoreLoad(layer->_backingStore, layer->_keyframesContents);
            [layer->_keyframesContents release];
            layer->_keyframesContents = nil;
        } else {
            if (layer->_oldContents) {
                //DLog(@"layer->_oldContents: %@", layer->_oldContents);
                _CABackingStoreLoad(layer->_oldBackingStore, [NSArray arrayWithObjects:layer->_oldContents, nil]);
                CGImageRelease(layer->_oldContents);
                layer->_oldContents = nil;
            }
            _CABackingStoreLoad(layer->_backingStore, [NSArray arrayWithObjects:layer->_displayContents, nil]);
            //DLog(@"layer->_displayContents: %@", layer->_displayContents);
            CGImageRelease(layer->_displayContents);
            layer->_displayContents = nil;
        }
    }
    [_needsLoadRenderLayers removeAllObjects];
    //CFSetRemoveAllValues(_needsLoadRenderLayers);
}
