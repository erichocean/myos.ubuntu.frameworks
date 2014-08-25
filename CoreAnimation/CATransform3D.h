/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <CoreAnimation/CABase.h>

typedef struct {
    CGFloat m11, m12, m13, m14;
    CGFloat m21, m22, m23, m24;
    CGFloat m31, m32, m33, m34;
    CGFloat m41, m42, m43, m44;
} CATransform3D;

extern const CATransform3D CATransform3DIdentity;
/*
CATransform3D CATransform3DIdentity = {
    1,0,0,0,
    0,1,0,0,
    0,0,1,0,
    0,0,0,1
};*/

CGAffineTransform CATransform3DGetAffineTransform(CATransform3D t);
CATransform3D CATransform3DMakeAffineTransform(CGAffineTransform t);
