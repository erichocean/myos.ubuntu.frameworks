/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <CoreAnimation/CoreAnimation-private.h>

static BOOL _foundOpaqueLayer = NO;

#pragma mark - Static C functions

static void setNeedsCompositeIfIntersects(CARenderLayer *layer, CARenderLayer *opaqueLayer, CGRect r)
{
    CGRect rectInLayer = [opaqueLayer convertRect:r toLayer:layer];
    if (CGRectIntersectsRect(layer->bounds, rectInLayer)) {
        CGRect intersection = CGRectIntersection(layer->bounds, rectInLayer);
        intersection = _CARenderLayerApplyMasksToBoundsToRect(layer, layer->superlayer, intersection);
        layer->rectNeedsComposite = CGRectUnion(layer->rectNeedsComposite, intersection);
        for (CARenderLayer *sublayer in layer->sublayers) {
            setNeedsCompositeIfIntersects(sublayer, opaqueLayer, r);
        }
    }
}

static void setNeedsCompositeInRect(CARenderLayer *layer, CARenderLayer *opaqueLayer, CGRect r)
{
    for (CARenderLayer *sublayer in layer->sublayers) {
        if (sublayer==opaqueLayer) {
            _foundOpaqueLayer = YES;
        }
        if (_foundOpaqueLayer) {
           setNeedsCompositeIfIntersects(sublayer,opaqueLayer,r);
        }
        setNeedsCompositeInRect(sublayer, opaqueLayer, r);
    }
}

static CGPoint _CARenderLayerGetOrigin(CARenderLayer *layer)
{
    if (layer->superlayer) {
        CGPoint result;
        CGPoint superlayerOrigin = _CARenderLayerGetOrigin((CARenderLayer *)layer->superlayer);
        CGPoint layerPosition = layer->position;
        CGRect layerBounds = layer->bounds;
        //if (layerBounds.size.width < 200) {
        //}
        CGPoint layerAnchorPoint = layer.anchorPoint;
        result.x = superlayerOrigin.x + layerPosition.x - layerBounds.size.width * layerAnchorPoint.x;
        result.y = superlayerOrigin.y + layerPosition.y - layerBounds.size.height * (1 - layerAnchorPoint.y);
        return result;
    } else {
        return CGPointZero;
    }
}

static void _CARenderLayerCompositeWithOpacity(CARenderLayer *layer, float opacity, int textureID)
{
    if (textureID == 0) {
        return;
    }
    glBindTexture(GL_TEXTURE_2D, textureID);
    
    float xr = layer->rectNeedsComposite.origin.x;
    float yr = layer->rectNeedsComposite.origin.y;
    float wr = layer->rectNeedsComposite.size.width;
    float hr = layer->rectNeedsComposite.size.height;
    
    float wl = layer->bounds.size.width; // width of layer bounds
    float hl = layer->bounds.size.height; // height of layer bounds
    
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
    
    IOWindow *screenWindow = IOWindowGetSharedWindow();
    float ws = screenWindow->rect.size.width; // width of screen
    float hs = screenWindow->rect.size.height; // height of screen
    CGPoint layerOrigin = _CARenderLayerGetOrigin(layer);

    //layerOrigin = CGPointMake(layerOrigin.x + xr, layerOrigin.y + yr);
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
    
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    glVertexPointer(2, GL_FLOAT, 0, vertices);
  
    glColor4f(opacity, opacity, opacity, opacity);
    //glColor4f(1.0, 1.0, 1.0, 1.0);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

static void _CARenderLayerComposite(CARenderLayer *layer)
{
    GLuint textureID = layer->backingStore->texture->textureID;
    if (layer->_contentsTransitionProgress < 1.0) {
        GLuint oldTextureID = layer->oldBackingStore->texture->textureID;
        //DLog(@"oldBackingStore: %@", layer->oldBackingStore);
        //DLog(@"backingStore: %@", layer->backingStore);
        //DLog(@"oldTextureID: %d", oldTextureID);
        _CARenderLayerCompositeWithOpacity(layer, layer->opacity*(1.0-layer->_contentsTransitionProgress), oldTextureID);
        _CARenderLayerCompositeWithOpacity(layer, layer->opacity*layer->_contentsTransitionProgress, textureID);
    } else {
        //DLog(@"opacity: %0.1f", layer->opacity); 
        _CARenderLayerCompositeWithOpacity(layer, layer->opacity, textureID);
    }
}

@implementation CARenderLayer

//@synthesize oldBackingStore;

#pragma mark - Life cycle

- (id)initWithPresentationLayer:(CALayer *)layer
{
    self = [super init];
    if (self) {
        presentationLayer = layer;
        layer->_renderLayer = self;
        bounds = CGRectZero;
        position = CGPointZero;
        anchorPoint = CGPointMake(0.5, 0.5);
        opaque = NO;
        oldBackingStore = [[CABackingStore alloc] init];
        backingStore = [[CABackingStore alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [oldBackingStore release];
    [backingStore release];
    [super dealloc];
}

@end

#pragma mark - Private C functions

void _CARenderLayerCopy(CARenderLayer *renderLayer, CALayer *presentationLayer)
{
    renderLayer->position = presentationLayer->position;
    //if (presentationLayer->bounds.size.width < 200) {
    //    DLog(@" position: %@", NSStringFromCGPoint(renderLayer->position));
    //}
    renderLayer->bounds = presentationLayer->bounds;
    renderLayer->anchorPoint = presentationLayer->anchorPoint;
    renderLayer->masksToBounds = presentationLayer->masksToBounds;
    renderLayer->_contentsTransitionProgress = presentationLayer->_contentsTransitionProgress;
    renderLayer->contentsRect = presentationLayer->contentsRect;
    renderLayer->contentsScale = presentationLayer->contentsScale;
    renderLayer->contentsCenter = presentationLayer->contentsCenter;
    renderLayer->opaque = presentationLayer->opaque;
    renderLayer->opacity = presentationLayer->opacity;
    renderLayer->hidden = presentationLayer->hidden;
    renderLayer->masksToBounds = presentationLayer->masksToBounds;
    CGImageRelease(renderLayer->_displayContents);
    renderLayer->_displayContents = CGImageRetain(presentationLayer->_displayContents);
}

CARenderLayer *_CARenderLayerClosestOpaqueLayerFromLayer(CARenderLayer *layer)
{
    if (layer->opaque || !layer->superlayer) {
        return layer;
    } else {
        return _CARenderLayerClosestOpaqueLayerFromLayer((CARenderLayer *)layer->superlayer);
    }
}

CGRect _CARenderLayerApplyMasksToBoundsToRect(CALayer *layer, CALayer *ancestorLayer, CGRect rect)
{
    //CALayer *superlayer = layer->superlayer;
    CGRect resultRect = rect;
    if (ancestorLayer) {
        if (ancestorLayer->masksToBounds) {
            CGRect ancestorRect = [ancestorLayer convertRect:ancestorLayer->bounds toLayer:layer];
            resultRect = CGRectIntersection(rect, ancestorRect);
        }
        return _CARenderLayerApplyMasksToBoundsToRect(layer, ancestorLayer->superlayer, resultRect);
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

void _CARenderLayerCompositeIfNeeded(CARenderLayer *layer)//, CGContextRef ctx)
{
    if (!CGRectEqualToRect(layer->rectNeedsComposite, CGRectZero)) {
        //_CACompositorNeedsFlush(YES);
        _CARenderLayerComposite(layer);
    } /*else {
    }*/
}

void _CARenderLayerUnload(CARenderLayer *layer)
{
    //DLog(@"layer: %@", layer);
    _CABackingStoreUnload(layer->backingStore);
    for (CARenderLayer *sublayer in layer->sublayers) {
        _CARenderLayerUnload(sublayer);
    }
}

