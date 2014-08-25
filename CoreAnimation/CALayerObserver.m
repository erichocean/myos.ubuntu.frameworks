/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import <CoreAnimation/CoreAnimation-private.h>

static CALayerObserver *_layerObserver = nil;

@implementation CALayerObserver

#pragma mark - Delegates

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSNumber *isPrior = [change objectForKey:@"notificationIsPrior"];
    if (![isPrior boolValue]) {
        return;
    }
    CALayer *layer = (CALayer *)object;
    BOOL isModelLayer = (layer->modelLayer == layer);
    BOOL needsDisplay = [[layer class] needsDisplayForKey:keyPath];
    if (!isModelLayer) {
        if (needsDisplay) {
            layer->needsDisplay = YES;
            CFSetAddValue(_needsDisplayPresentationLayers, layer);
            //_CARendererAddToDisplayPresentationLayers(layer);
        }
        return;
    }
    CAAnimationGroup *animationGroup = _CAAnimationCurrentAnimationGroup();
    if ((!layer->delegate && layer->superlayer) || animationGroup) {
        id<CAAction> action = [layer actionForKey:keyPath];
        [action runActionForKey:keyPath object:layer arguments:nil];
        CABasicAnimation *animation = (CABasicAnimation *)[layer animationForKey:keyPath];
        if (animation) {
            if (animationGroup) {
                _CAAnimationCopy(animation, (CAAnimation *)animationGroup);
            }
            if ([keyPath isEqualToString:@"contents"]) {
                //DLog(@"layer: %@", layer);
                if (layer->contents) {
                    if (layer->_oldContents) {
                        [layer->_oldContents release];
                    }
                    layer->_oldContents = CGImageCreateCopy(layer->contents);
                }
            }
        }
    }
    if (needsDisplay) {
        _CALayerSetNeedsDisplay(layer);
    } else {
        //DLog(@"keyPath: %@, needsComposite", keyPath);
        _CALayerSetNeedsComposite(layer);
    }
}

@end

void _CALayerObserverInitialize()
{
    _layerObserver = [[CALayerObserver alloc] init];
}

CALayerObserver *_CALayerObserverGetSharedObserver()
{
    return _layerObserver;
}

