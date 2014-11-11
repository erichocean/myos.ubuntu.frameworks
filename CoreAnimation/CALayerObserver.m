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

static CALayerObserver *_layerObserver = nil;

@implementation CALayerObserver

#pragma mark - Delegates

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //DLog();
    NSNumber *isPrior = [change objectForKey:@"notificationIsPrior"];
    if (![isPrior boolValue]) {
        return;
    }
    CALayer *layer = (CALayer *)object;
    BOOL isModelLayer = (layer->_modelLayer == layer);
    BOOL needsDisplay = [[layer class] needsDisplayForKey:keyPath];
    if (!isModelLayer) {
        if (needsDisplay) {
            layer->_needsDisplay = YES;
            CFSetAddValue(_needsDisplayPresentationLayers, layer);
        }
        return;
    }
    //DLog();
    CAAnimationGroup *animationGroup = _CAAnimationGroupGetCurrent();
    if ((!layer->delegate && layer->_superlayer) || animationGroup) {
        //DLog(@"keyPath: %@", keyPath);
        id<CAAction> action = [layer actionForKey:keyPath];
        [action runActionForKey:keyPath object:layer arguments:nil];
        CABasicAnimation *animation = (CABasicAnimation *)[layer animationForKey:keyPath];
        if (animation) {
            if (animationGroup) {
                //DLog(@"animationGroup: %@", animationGroup);
                _CAAnimationCopy(animation, (CAAnimation *)animationGroup);
                _CAAnimationGroupAddAnimation(animationGroup, animation);
            }
            if ([keyPath isEqualToString:@"contents"]) {
                //DLog(@"layer: %@", layer);
                if (layer->_contents) {
                    if (layer->_oldContents) {
                        [layer->_oldContents release];
                    }
                    layer->_oldContents = CGImageCreateCopy(layer->_contents);
                    //DLog(@"layer->_oldContents: %@", layer->_oldContents);
                }
            }
        }
    }
    if (needsDisplay) {
        //DLog(@"keyPath: %@", keyPath);
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

