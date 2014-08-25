/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
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
