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

#import <CoreAnimation/CoreAnimation.h>

#import <CoreAnimation/CAGradientLayer-private.h>
#import <CoreAnimation/CALayer-CFunctions.h>
#import <CoreAnimation/CALayer-private.h>
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
