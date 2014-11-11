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

NSString *const kCATransactionAnimationDuration = @"CATransactionAnimationDuration";
NSString *const kCATransactionAnimationTimingFunction = @"CATransactionAnimationTimingFunction";
NSString *const kCATransactionDisableActions = @"CATransactionDisableActions";
NSString *const kCATransactionCompletionBlock = @"CATransactionCompletionBlock";

BOOL _layersNeedLayout = NO;
static CFMutableArrayRef _transactions = nil;
static CFMutableSetRef _removeLayers = nil;

#pragma mark - Static functions

static CATransactionGroup *_CATransactionGetCurrentTransaction()
{
    //DLog(@"_CATransactionGetCurrentTransaction");
    _CATransactionCreateImplicitTransactionIfNeeded();
    return CFArrayGetValueAtIndex(_transactions, CFArrayGetCount(_transactions)-1);
}

static void _CATransactionLayoutLayers(CALayer *layer)
{
    //DLog();
    [layer layoutIfNeeded];
    for (CALayer *sublayer in layer->_sublayers) {
        _CATransactionLayoutLayers(sublayer);
    }
}

static void _CATransactionCopyTree(CALayer *layer)
{
    //DLog(@"layer: %@", layer);
    if (layer->_needsComposite) {
        CALayer *presentationLayer = layer->_presentationLayer;
        CARenderLayer *renderLayer = (CARenderLayer *)presentationLayer->_renderLayer;
        //DLog(@"layer2: %@", layer);
        _CALayerCopy(presentationLayer, layer);
        _CALayerRemoveExpiredAnimations(layer);
        layer->_needsComposite = NO;
        _CALayerCopyAnimations(presentationLayer);
        if (layer->_superlayer) {
            int layerIndex =  _CALayerIndexOfLayer(layer);
            _CALayerAddSublayer(layer->_superlayer->_presentationLayer, presentationLayer, layerIndex);
            _CALayerAddSublayer(presentationLayer->_superlayer->_renderLayer, renderLayer, layerIndex);
            //DLog(@"renderLayer: %@", renderLayer);
        }
    }
    for (CALayer *sublayer in layer->_sublayers) {
        _CATransactionCopyTree(sublayer);
    }
}

static void _CATransactionUnloadIfNeeded(CALayer *layer)
{
    //DLog(@"layer: %@", layer);
    if (layer->_needsUnload) {
        layer->_needsUnload = NO;
        CALayer *presentationLayer = layer->_presentationLayer;
        CARenderLayer *renderLayer = (CARenderLayer *)presentationLayer->_renderLayer;
        _CARenderLayerUnload(renderLayer);
    }
    for (CALayer *sublayer in layer->_sublayers) {
        _CATransactionUnloadIfNeeded(sublayer);
    }
}

static void _CATransactionRemoveLayers()
{
    //DLog();
    for (CALayer *layer in _removeLayers) {
        //DLog(@"layer: %@", layer);
        CALayer *presentationLayer = layer->_presentationLayer;
        //DLog(@"presentationLayer: %@", presentationLayer);
        CARenderLayer *renderLayer = (CARenderLayer *)presentationLayer->_renderLayer;
        //DLog(@"renderLayer: %@", renderLayer);
        if (layer->_needsUnload) {
            //DLog(@"layer->_needsUnload");
            _CARenderLayerUnload(renderLayer);
        }
        _CALayerRemoveFromSuperlayer(presentationLayer);
        _CALayerRemoveFromSuperlayer(renderLayer);
    }
    CFSetRemoveAllValues(_removeLayers);
}

static void _CATransactionCommitTransactionAfterDelay(float delay)
{
    [[CATransaction class] performSelector:@selector(_commitTransaction) withObject:nil afterDelay:delay];
}

@implementation CATransaction

#pragma mark - Accessors

+ (CFTimeInterval)animationDuration
{
    return (CFTimeInterval)[(NSNumber *)[self valueForKey:kCATransactionAnimationDuration] doubleValue];
}

+ (void)setAnimationDuration:(CFTimeInterval)dur
{
    [self setValue:[NSNumber numberWithDouble:dur] forKey:kCATransactionAnimationDuration];
}

+ (CAMediaTimingFunction *)animationTimingFunction
{
    return [self valueForKey:kCATransactionAnimationTimingFunction];
}

+ (void)setAnimationTimingFunction:(CAMediaTimingFunction *)function
{
    [self setValue:function forKey:kCATransactionAnimationTimingFunction];
}

+ (BOOL)disableActions
{
    return [(NSNumber *)[self valueForKey:kCATransactionDisableActions] boolValue];
}

+ (void)setDisableActions:(BOOL)flag
{
    [self setValue:[NSNumber numberWithBool:flag] forKey:kCATransactionDisableActions];
}

+ (void)setValue:(id)value forKey:(NSString *)key
{
    CATransactionGroup *group = _CATransactionGetCurrentTransaction();
    CFDictionarySetValue(group->_values, key, value);
}

+ (id)valueForKey:(NSString *)key
{
    CATransactionGroup *group = _CATransactionGetCurrentTransaction();
    return CFDictionaryGetValue(group->_values, key);
}

#pragma mark - Public methods

+ (void)begin
{
    CATransactionGroup *group = [[CATransactionGroup alloc] init];
    CFArrayAppendValue(_transactions, group);
    [group release];
}

+ (void)_commitTransaction
{
    //DLog();

    if (![_CAAnimatorConditionLock tryLock]) {
        //DLog(@"[_CAAnimatorConditionLock condition]: %d", [_CAAnimatorConditionLock condition]);
        // Instead of blocking the run loop or the animation thread, we will try to commit later
        _CATransactionCommitTransactionAfterDelay(0.01);
        //[[CATransaction class] performSelector:@selector(_commitTransaction) withObject:nil afterDelay:0.01];
        return;
    }
    //DLog();
    CALayer *rootLayer = _CALayerRootLayer();
    //DLog(@"LayoutLayers");
    if (_layersNeedLayout) {
        //DLog(@"_layersNeedLayout");
        _CATransactionLayoutLayers(rootLayer);
        _layersNeedLayout = NO;
    }
    //DLog(@"_CARendererDisplayLayers");
    _CARendererDisplayLayers(YES);
    //DLog(@"_CATransactionCopyTree");
    _CATransactionCopyTree(rootLayer);
    //DLog(@"_CATransactionUnloadIfNeeded");
    _CATransactionUnloadIfNeeded(rootLayer);
    //DLog(@"_CATransactionRemoveLayers");
    _CATransactionRemoveLayers();
    [_CAAnimatorConditionLock unlockWithCondition:_CAAnimatorConditionLockHasWork];
    //DLog(@"[CAAnimator display]");
    //[CAAnimator display];
    //DLog(@"End Composite");
    // Removing last transaction group, as this is a stack. In a stack, you add and remove from same place, in our case from 0
    //DLog(@"_transactions: %@", _transactions);
    CFArrayRemoveValueAtIndex(_transactions, CFArrayGetCount(_transactions)-1);
    //DLog(@"_transactions2: %@", _transactions);
    //DLog(@"Free memory: %ld KB", CFGetFreeMemory());
}

+ (void)commit
{
    //DLog(@"");
    CFArrayRemoveValueAtIndex(_transactions, CFArrayGetCount(_transactions)-1);
    _CATransactionCreateImplicitTransactionIfNeeded();
}

+ (void)flush
{
}

+ (void)lock 
{
}

+ (void)unlock
{
}

@end

#pragma mark - Shared functions

void _CATransactionInitialize()
{
    //DLog();
    _transactions = CFArrayCreateMutable(kCFAllocatorDefault, 5, &kCFTypeArrayCallBacks);
    _removeLayers = CFSetCreateMutable(kCFAllocatorDefault, 10, &kCFTypeSetCallBacks);
    _CAAnimationInitialize();
    //DLog();
    _CARendererInitialize();
    //DLog();
    _CACompositorInitialize();
    //DLog();
}

void _CATransactionAddToRemoveLayers(CALayer *layer)
{
    //DLog();
    CFSetAddValue(_removeLayers, layer);
}

void _CATransactionCreateImplicitTransactionIfNeeded()
{
    if (CFArrayGetCount(_transactions)==0) {
        //DLog();
        CATransactionGroup *group = [[CATransactionGroup alloc] init];
        CFArrayAppendValue(_transactions, group);
        [group release];
        _CATransactionCommitTransactionAfterDelay(0.01);
        //DLog(@"_transactions: %@", _transactions);
        //[[CATransaction class] performSelector:@selector(_commitTransaction) withObject:nil afterDelay:0.01];
        //DLog(@"new commit after delay");
    }
}
