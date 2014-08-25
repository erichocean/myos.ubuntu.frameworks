/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <CoreAnimation/CoreAnimation-private.h>

NSString *const kCATransactionAnimationDuration = @"CATransactionAnimationDuration";
NSString *const kCATransactionAnimationTimingFunction = @"CATransactionAnimationTimingFunction";
NSString *const kCATransactionDisableActions = @"CATransactionDisableActions";
NSString *const kCATransactionCompletionBlock = @"CATransactionCompletionBlock";

static CFMutableArrayRef _transactions = nil;
static CFMutableSetRef _removeLayers = nil;

#pragma mark - Static C functions

static CATransactionGroup *_CATransactionGetCurrentTransaction()
{
    _CATransactionCreateImplicitTransactionIfNeeded();
    return CFArrayGetValueAtIndex(_transactions, CFArrayGetCount(_transactions)-1);
}

static void _CATransactionCopyTree(CALayer *layer)
{
    if (layer->_needsComposite) {
        CALayer *presentationLayer = layer->presentationLayer;
        CARenderLayer *renderLayer = (CARenderLayer *)presentationLayer->_renderLayer;
        _CALayerCopy(presentationLayer, layer);
        _CALayerRemoveExpiredAnimations(layer);
        layer->_needsComposite = NO;
        _CALayerCopyAnimations(presentationLayer);
         //CFDictionaryRemoveAllValues(layer->_animations);
        if (layer->superlayer) {
            int layerIndex =  _CALayerIndexOfLayer(layer);
            _CALayerAddSublayer(layer->superlayer->presentationLayer, presentationLayer, layerIndex);
            _CALayerAddSublayer(presentationLayer->superlayer->_renderLayer, renderLayer, layerIndex);
        }
    }
    for (CALayer *sublayer in layer->sublayers) {
        _CATransactionCopyTree(sublayer);
    }
}

static void _CATransactionUnloadIfNeeded(CALayer *layer)
{
    if (layer->_needsUnload) {
        CALayer *presentationLayer = layer->presentationLayer;
        CARenderLayer *renderLayer = (CARenderLayer *)presentationLayer->_renderLayer;
        _CARenderLayerUnload(renderLayer);
    }
    for (CALayer *sublayer in layer->sublayers) {
        _CATransactionUnloadIfNeeded(sublayer);
    }
}

static void _CATransactionRemoveLayers()
{
    for (CALayer *layer in _removeLayers) {
        CALayer *presentationLayer = layer->presentationLayer;
        CARenderLayer *renderLayer = (CARenderLayer *)presentationLayer->_renderLayer;
        _CARenderLayerUnload(renderLayer);
        _CALayerRemoveFromSuperlayer(presentationLayer);
        _CALayerRemoveFromSuperlayer(renderLayer);
    }
    CFSetRemoveAllValues(_removeLayers);
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

#pragma mark - Helpers

+ (void)begin
{
    CATransactionGroup *group = [[CATransactionGroup alloc] init];
    CFArrayAppendValue(_transactions, group);
    [group release];
}

+ (void)_commitTransaction
{
    //DLog(@"");
    if (_EAGLSwappingBuffers && [_CAAnimatorConditionLock condition] == _CAAnimatorConditionLockHasWork) {
        //DLog(@"_EAGLSwappingBuffers");
        [[CATransaction class] performSelector:@selector(_commitTransaction) withObject:nil afterDelay:0.01];
        return;
    }
    if (![_CAAnimatorConditionLock tryLock]) {
        DLog(@"[_CAAnimatorConditionLock condition]: %d", [_CAAnimatorConditionLock condition]);
        // Instead of blocking the run loop or the animation thread, we will try to commit later
        [[CATransaction class] performSelector:@selector(_commitTransaction) withObject:nil afterDelay:0.01];
        return;
    }
    CALayer *rootLayer = _CALayerRootLayer();
    //updateAnimationsWithRoot(rootLayer);
    //DLog(@"DisplayLayers");
    _CARendererDisplayLayers(YES);
    _CATransactionCopyTree(rootLayer);
    _CATransactionUnloadIfNeeded(rootLayer);
    //DLog(@"CleanTree");
    _CATransactionRemoveLayers();
    [_CAAnimatorConditionLock unlockWithCondition:_CAAnimatorConditionLockHasWork];
    //DLog(@"Composite");
    // Removing last transaction group, as this is a stack. In a stack, you add and remove from same place, in our case from 0
    CFArrayRemoveValueAtIndex(_transactions, CFArrayGetCount(_transactions)-1);
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

#pragma mark - Private C functions

void _CATransactionInitialize()
{
    //DLog();
    _transactions = CFArrayCreateMutable(kCFAllocatorDefault, 1, &kCFTypeArrayCallBacks);
    _removeLayers = CFSetCreateMutable(kCFAllocatorDefault, 3, &kCFTypeSetCallBacks);
    _CAAnimationInitialize();
    _CARendererInitialize();
    //_CAAnimatorInitialize();
}

void _CATransactionAddToRemoveLayers(CALayer *layer)
{
    CFSetAddValue(_removeLayers, layer);
}

void _CATransactionCreateImplicitTransactionIfNeeded()
{
    //DLog(@"_transactions: %@", _transactions);
    if (CFArrayGetCount(_transactions)==0) {
        CATransactionGroup *group = [[CATransactionGroup alloc] init];
        CFArrayAppendValue(_transactions, group);
        [group release];
        [[CATransaction class] performSelector:@selector(_commitTransaction) withObject:nil afterDelay:0.01];
        //DLog(@"new commit after delay");
    }
}

