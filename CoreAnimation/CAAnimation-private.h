/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <CoreAnimation/CAAnimation.h>

// Life cycle

void _CAAnimationInitialize();

// Animation

void _CAAnimationApplyAnimationForLayer(CAAnimation *theAnimation, CALayer *layer, CFTimeInterval time);

// CAAnimationGroup

CAAnimationGroup *_CAAnimationNewAnimationGroup();
CAAnimationGroup *_CAAnimationCurrentAnimationGroup();
void _CAAnimationAddToAnimationGroup(CAAnimation *animation);
void _CAAnimationCommitAnimationGroup();

// Helpers

void _CAAnimationCopy(CAAnimation *toAnimation, CAAnimation *fromAnimation);
