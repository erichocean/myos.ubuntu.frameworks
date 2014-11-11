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
