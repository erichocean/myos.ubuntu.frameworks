/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <CoreAnimation/CoreAnimation-private.h>

#define _kResetTimeInterval 1.0

NSConditionLock *_CAAnimatorConditionLock = nil;
int _CAAnimatorFrameCount = 0;
static BOOL _treeHasPendingAnimations=NO;
static BOOL _treeHadPendingAnimations = NO;
static BOOL _eaglContextIsReady = NO;

static NSTimeInterval previousTimestamp;
static NSTimeInterval beforeLockTime;
static NSTimeInterval currentTime;
 
#pragma mark - Static C functions

static void _CAAnimatorApplyAnimationsWithRoot(CALayer *layer)
{
    _CALayerApplyAnimations(layer);
    if (!_treeHasPendingAnimations) {
        if ([layer->_animations count]) {
            _treeHasPendingAnimations = YES;
        }
    }
    for (CALayer *sublayer in layer->sublayers) {
        _CAAnimatorApplyAnimationsWithRoot(sublayer);
    }
}

static void _CAAnimatorApplyAnimations()
{
    _treeHasPendingAnimations=NO;
    _CAAnimatorApplyAnimationsWithRoot(_CALayerRootLayer()->presentationLayer);
    _CARendererDisplayLayers(NO);
}

static void reportFPS(BOOL withCondition)
{
    if (currentTime - beforeLockTime > _kResetTimeInterval || !withCondition) {
        //float fps = _CAAnimatorFrameCount * 1.0 / (beforeLockTime - previousTimestamp);
        if (_CAAnimatorFrameCount>1) {
            //DLog(@"_CAAnimatorFrameCount: %d, fps: %0.0f", _CAAnimatorFrameCount, fps);
        }
        _CAAnimatorFrameCount = 0;
        previousTimestamp = CACurrentMediaTime();
    }
}

// CAAnimator uses CACompositor to composite Render Tree for each frame.
@implementation CAAnimator

+ (void)run
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    //DLog(@"[NSThread currentThread]: %@", [NSThread currentThread]);
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    //DLog(@"context: %@", context);
    [EAGLContext setCurrentContext:context];
    [context release];
    _EAGLSetup();
    _EAGLClear();
    _eaglContextIsReady = YES;
    BOOL vSyncEnabled = context->_vSyncEnabled;
    
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(display)];
    //displayLink.frameInterval = 2;
    while (true) {
        NSAutoreleasePool *pool2 = [[NSAutoreleasePool alloc] init];
        if (vSyncEnabled) {
            [displayLink displayFrame];
        } else {
            NSDate *limit = [[NSDate alloc] initWithTimeIntervalSinceNow:10.0];
            [[NSRunLoop currentRunLoop] runUntilDate:limit];
            [limit release];
        }
        [pool2 release];
    }
    [pool release];
}

+ (void)display
{
    //DLog();
    beforeLockTime = CACurrentMediaTime();
    [_CAAnimatorConditionLock lockWhenCondition:_CAAnimatorConditionLockHasWork];
    currentTime = CACurrentMediaTime();
    reportFPS(YES);
    _CAAnimatorApplyAnimations();
    _CARendererLoadRenderLayers();
    _CACompositorPrepareComposite();
    if (_treeHasPendingAnimations) {
        if (!_treeHadPendingAnimations) {
            previousTimestamp = CACurrentMediaTime();
            _treeHadPendingAnimations = YES;
        }
        [_CAAnimatorConditionLock unlock];
    } else {
        if (_treeHadPendingAnimations) {
            reportFPS(NO);
            _treeHadPendingAnimations = NO;
        }
        [_CAAnimatorConditionLock unlockWithCondition:_CAAnimatorConditionLockHasNoWork];
    }
    _CACompositorComposite();
}

@end

#pragma mark - Private C functions

void _CAAnimatorInitialize()
{
    _CAAnimatorConditionLock = [[NSConditionLock alloc] initWithCondition:_CAAnimatorConditionLockHasNoWork];
    //DLog(@"will detach thread");
    [NSThread detachNewThreadSelector:@selector(run)
                             toTarget:[CAAnimator class]
                           withObject:nil];
    DLog(@"detached the thread");
//    while (!_eaglContextIsReady) {
//        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
//    }
//    DLog(@"_eaglContextIsReady == YES");
}
