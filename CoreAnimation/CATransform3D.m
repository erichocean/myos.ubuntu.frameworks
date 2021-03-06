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

#import "CATransform3D.h"

const CATransform3D CATransform3DIdentity = {
    1,0,0,0,
    0,1,0,0,
    0,0,1,0,
    0,0,0,1
};

CGAffineTransform CATransform3DGetAffineTransform(CATransform3D t)
{
    CGAffineTransform transform = CGAffineTransformMake(
    	1,
    	0,
    	0,
    	0,
    	1,
        0	
    	);
    return transform;
}

CATransform3D CATransform3DMakeAffineTransform(CGAffineTransform t)
{
    return CATransform3DIdentity;
}
