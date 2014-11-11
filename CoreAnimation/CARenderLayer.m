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
#import <OpenGLES/EAGL-private.h>
#import <IOKit/IOKit.h>

static BOOL _foundOpaqueLayer = NO;

#pragma mark - Static functions

static void setNeedsCompositeIfIntersects(CARenderLayer *layer, CARenderLayer *opaqueLayer, CGRect r)
{
    //if (layer->_opacity > 0) {
    CGRect rectInLayer = [opaqueLayer convertRect:r toLayer:layer];
    if (CGRectIntersectsRect(layer->_bounds, rectInLayer)) {
        CGRect intersection = CGRectIntersection(layer->_bounds, rectInLayer);
        intersection = _CARenderLayerApplyMasksToBoundsToRect(layer, layer->_superlayer, intersection);
        layer->_rectNeedsComposite = CGRectUnion(layer->_rectNeedsComposite, intersection);
        for (CARenderLayer *sublayer in layer->_sublayers) {
            setNeedsCompositeIfIntersects(sublayer, opaqueLayer, r);
        }
    }
    //}
}

static void setNeedsCompositeInRect(CARenderLayer *layer, CARenderLayer *opaqueLayer, CGRect r)
{
    for (CARenderLayer *sublayer in layer->_sublayers) {
        if (!sublayer->_hidden) {
            if (sublayer==opaqueLayer) {
                _foundOpaqueLayer = YES;
            }
            if (_foundOpaqueLayer) {
                setNeedsCompositeIfIntersects(sublayer,opaqueLayer,r);
            }
            setNeedsCompositeInRect(sublayer, opaqueLayer, r);
        }
    }
}

static CGPoint _CARenderLayerGetOrigin(CARenderLayer *layer)
{
    if (layer->_superlayer) {
        CGPoint result;
        CGPoint superlayerOrigin = _CARenderLayerGetOrigin((CARenderLayer *)layer->_superlayer);
        CGPoint layerPosition = layer->_position;
        CGRect layerBounds = layer->_bounds;
        CGPoint layerAnchorPoint = layer->_anchorPoint;
        result.x = superlayerOrigin.x + layerPosition.x - layerBounds.size.width * layerAnchorPoint.x + layerBounds.origin.x;
        result.y = superlayerOrigin.y + layerPosition.y - layerBounds.size.height * (1 - layerAnchorPoint.y) + layerBounds.origin.y;
        return result;
    } else {
        return layer->_bounds.origin; //CGPointZero;
    }
}

static void _CARenderLayerCompositeWithOpacity(CARenderLayer *layer, float opacity, int textureID)
{
    int i;
    //DLog(@"textureID: %d", textureID);
    //DLog(@"layer: %@", layer);
    if (textureID == 0) {
        return;
    }
    glBindTexture(GL_TEXTURE_2D, textureID);
    //DLog(@"textureID: %d", textureID);
    //DLog(@"layer: %@", layer);
    float xr = layer->_rectNeedsComposite.origin.x;
    float yr = layer->_rectNeedsComposite.origin.y;
    float wr = layer->_rectNeedsComposite.size.width;
    float hr = layer->_rectNeedsComposite.size.height;
    
    float wl = layer->_bounds.size.width; // width of layer bounds
    float hl = layer->_bounds.size.height; // height of layer bounds
    //DLog(@"textureID: %d, wl: %0.1f, hl: %0.1f", textureID, wl, hl);
    CGPoint p1 = CGPointMake(xr/wl, 1.0-yr/hl);
    CGPoint p2 = CGPointMake((xr+wr)/wl, p1.y);
    CGPoint p3 = CGPointMake(p1.x, 1.0-(yr+hr)/hl);
    CGPoint p4 = CGPointMake(p2.x, p3.y);
    
    GLfloat texCoords[] = {
        p1.x, p1.y,
        p2.x, p2.y,
        p3.x, p3.y,
        p4.x, p4.y
    };
    
    //DLog(@"texCoords: %0.1f, %0.1f, %0.1f, %0.1f, %0.1f, %0.1f, %0.1f, %0.1f", texCoords[0], texCoords[1], texCoords[2], texCoords[3],
    //     texCoords[4], texCoords[5], texCoords[6], texCoords[7]);
    IOWindow *screenWindow = IOWindowGetSharedWindow();
    float ws = screenWindow->_rect.size.width; // width of screen
    float hs = screenWindow->_rect.size.height; // height of screen
    
    CGPoint layerOrigin = _CARenderLayerGetOrigin(layer);
    //DLog(@"ws: %f, hs: %f", ws, hs);

    float xo = layerOrigin.x + xr;
    float yo = layerOrigin.y + yr;
    p1 = CGPointMake(2.0*xo/ws-1, 1.0-2*yo/hs);
    p2 = CGPointMake(2.0*(xo+wr)/ws-1, p1.y);
    p3 = CGPointMake(p1.x, 1.0-2*(yo+hr)/hs);
    p4 = CGPointMake(p2.x, p3.y);
    
    GLfloat vertices[] = {
        p1.x, p1.y,
        p2.x, p2.y,
        p3.x, p3.y,
        p4.x, p4.y
    };
    
    EAGLContext *context = _EAGLGetCurrentContext();
    //DLog(@"context->_width: %d, context->_height: %d", context->_width, context->_height);
    glViewport(0, 0, context->_width, context->_height);
    
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    //DLog(@"glGetError: %d", glGetError());
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    //DLog(@"glGetError: %d", glGetError());
    
    glColor4f(opacity, opacity, opacity, opacity);
    //glColor4f(0.3, 0.3, 0.3, 0.3);
    //DLog(@"glGetError: %d", glGetError());
    //glColor4f(1.0, hs/ws, 0.0, 1.0);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    //DLog(@"glGetError: %d", glGetError());
    
    //glClearColor(0.0, 1.0, 0.0, 0.5);
    //glClear(GL_COLOR_BUFFER_BIT);
    //glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    
    //_EAGLSwapBuffers();
    //DLog(@"glGetError: %d", glGetError());
}

static void _CARenderLayerComposite(CARenderLayer *layer)
{
    GLuint textureID;
    if (layer->_contentsTransitionProgress < 1.0) {
        GLuint oldTextureID = layer->_oldBackingStore->_texture->_textureIDs[0];
        textureID = layer->_backingStore->_texture->_textureIDs[0];
        //GLuint textureID2 = layer->_backingStore->_texture->_textureIDs[1];
        //DLog(@"oldBackingStore: %@", layer->_oldBackingStore);
        //DLog(@"backingStore: %@", layer->backingStore);
        //DLog(@"oldTextureID: %d", oldTextureID);
        _CARenderLayerCompositeWithOpacity(layer, layer->_opacity*(1.0-layer->_contentsTransitionProgress), oldTextureID);
        _CARenderLayerCompositeWithOpacity(layer, layer->_opacity*layer->_contentsTransitionProgress, textureID);
    } else if (layer->_keyframesProgress > -1) {
        int index = round(layer->_keyframesProgress * (layer->_backingStore->_texture->_numberOfTextures - 1));
        textureID = layer->_backingStore->_texture->_textureIDs[index];
        if (layer->_keyframesProgress < 0.1) {
            //DLog(@"index: %d, textureID: %d", index, textureID);
        }
        _CARenderLayerCompositeWithOpacity(layer, layer->_opacity, textureID);
    } else {
        if (layer->_backingStore->_texture->_numberOfTextures > 0) {
            textureID = layer->_backingStore->_texture->_textureIDs[0];
            //DLog(@"opacity: %0.1f", layer->_opacity);
            //DLog(@"textureID: %d", textureID);
            _CARenderLayerCompositeWithOpacity(layer, layer->_opacity, textureID);
        } else {
            DLog(@"layer->_backingStore->_texture->_numberOfTextures == 0");
        }
    }
}

@implementation CARenderLayer

#pragma mark - Life cycle

- (id)init
{
    self = [super init];
    if (self) {
        //_presentationLayer = layer;
        //layer->_renderLayer = self;
        _bounds = CGRectZero;
        _position = CGPointZero;
        _anchorPoint = CGPointMake(0.5, 0.5);
        _opaque = NO;
        _oldBackingStore = [[CABackingStore alloc] init];
        _backingStore = [[CABackingStore alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_oldBackingStore release];
    [_backingStore release];
    [super dealloc];
}

@end

#pragma mark - Shared functions

void _CARenderLayerCopy(CARenderLayer *renderLayer, CALayer *presentationLayer)
{
    //DLog(@"renderLayer: %@", renderLayer);
    //DLog(@"presentationLayer: %@", presentationLayer);
    renderLayer->_position = presentationLayer->_position;
    renderLayer->_bounds = presentationLayer->_bounds;
    renderLayer->_anchorPoint = presentationLayer->_anchorPoint;
    renderLayer->_masksToBounds = presentationLayer->_masksToBounds;
    renderLayer->_contentsTransitionProgress = presentationLayer->_contentsTransitionProgress;
    renderLayer->_keyframesProgress = presentationLayer->_keyframesProgress;
    renderLayer->_contentsRect = presentationLayer->_contentsRect;
    renderLayer->_contentsScale = presentationLayer->_contentsScale;
    renderLayer->_contentsCenter = presentationLayer->_contentsCenter;
    renderLayer->_opaque = presentationLayer->_opaque;
    renderLayer->_opacity = presentationLayer->_opacity;
    renderLayer->_hidden = presentationLayer->_hidden;
    renderLayer->_masksToBounds = presentationLayer->_masksToBounds;
    //DLog(@"renderLayer->_displayContents: %@", renderLayer->_displayContents);
    CGImageRelease(renderLayer->_displayContents);
    renderLayer->_displayContents = CGImageRetain(presentationLayer->_displayContents);
}

CARenderLayer *_CARenderLayerClosestOpaqueLayerFromLayer(CARenderLayer *layer)
{
    if ((layer->_opaque && !layer->_hidden) || !layer->_superlayer) {
        return layer;
    } else {
        return _CARenderLayerClosestOpaqueLayerFromLayer((CARenderLayer *)layer->_superlayer);
    }
}

CGRect _CARenderLayerApplyMasksToBoundsToRect(CALayer *layer, CALayer *ancestorLayer, CGRect rect)
{
    CGRect resultRect = rect;
    if (ancestorLayer) {
        if (ancestorLayer->_masksToBounds) {
            CGRect ancestorRect = [ancestorLayer convertRect:ancestorLayer->_bounds toLayer:layer];
            resultRect = CGRectIntersection(rect, ancestorRect);
        }
        return _CARenderLayerApplyMasksToBoundsToRect(layer, ancestorLayer->_superlayer, resultRect);
    }
    return resultRect;
}

void _CARenderLayerSetNeedsCompositeInRect(CARenderLayer *rootLayer, CARenderLayer *opaqueLayer, CGRect r)
{
    _foundOpaqueLayer = NO;
    if (rootLayer==opaqueLayer) {
        _foundOpaqueLayer = YES;
        setNeedsCompositeIfIntersects(rootLayer, opaqueLayer, r);
    }
    setNeedsCompositeInRect(rootLayer, opaqueLayer, r);
}

void _CARenderLayerCompositeIfNeeded(CARenderLayer *layer)
{
    //DLog(@"layer: %@", layer);
    if (!CGRectEqualToRect(layer->_rectNeedsComposite, CGRectZero)) {
        _CARenderLayerComposite(layer);
    } else {
        //DLog(@"layer with zero rect: %@", layer);
    }
}

void _CARenderLayerUnload(CARenderLayer *layer)
{
    //DLog(@"layer: %@", layer);
    _CABackingStoreUnload(layer->_backingStore);
    for (CARenderLayer *sublayer in layer->_sublayers) {
        _CARenderLayerUnload(sublayer);
    }
}
