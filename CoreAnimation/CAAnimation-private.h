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

#import <CoreAnimation/CAAnimation.h>

// Life cycle

void _CAAnimationInitialize();

// Animation

void _CAAnimationApplyAnimationForLayer(CAAnimation *theAnimation, CALayer *layer, CFTimeInterval time);

// CAAnimationGroup

CAAnimationGroup *_CAAnimationGroupNew();
CAAnimationGroup *_CAAnimationGroupGetCurrent();
void _CAAnimationGroupAddAnimation(CAAnimationGroup *animationGroup, CAAnimation *animation);
void _CAAnimationGroupRemoveAnimation(CAAnimationGroup *animationGroup, CAAnimation *animation);
void _CAAnimationGroupCommit();

// Helpers

void _CAAnimationCopy(CAAnimation *toAnimation, CAAnimation *fromAnimation);
