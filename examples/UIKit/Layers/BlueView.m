/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import "BlueView.h"

@implementation BlueView

- (id)initWithFrame:(CGRect)theFrame
{
    self = [super initWithFrame:theFrame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0];
        //self.backgroundColor = [UIColor blueColor];
    }
    return self;
}

@end

