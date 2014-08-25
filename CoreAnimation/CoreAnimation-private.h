/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <CoreGraphics/CoreGraphics-private.h>
#import <CoreFoundation/CFArray-private.h>
#import <IOKit/IOKit.h>
#import <OpenGLES/OpenGLES-private.h>

#import <CoreAnimation/CoreAnimation.h>

#import <CoreAnimation/CAGradientLayer-private.h>
#import <CoreAnimation/CALayer+CFunctions.h>
#import <CoreAnimation/CALayer+PresentationLayer.h>
#import <CoreAnimation/CALayerObserver.h>
#import <CoreAnimation/CARenderLayer.h>
#import <CoreAnimation/CATransaction-private.h>
#import <CoreAnimation/CARenderer-private.h>
#import <CoreAnimation/CACompositor.h>
#import <CoreAnimation/CAAnimator.h>
#import <CoreAnimation/CAAnimation-private.h>
#import <CoreAnimation/CATransactionGroup.h>
#import <CoreAnimation/CAMediaTimingFunction-private.h>
#import <CoreAnimation/CABackingStore.h>
#import <CoreAnimation/CADisplayLink-private.h>

#define _kSmallValue    0.0001
