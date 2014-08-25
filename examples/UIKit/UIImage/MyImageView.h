/*
 * Copyright (c) 2012. All rights reserved.
 *
 */

#import <UIKit/UIKit.h>

@interface MyImageView : UIView
{
    UIImageView *imageView;
    float firstY;
    NSTimeInterval previousTimestamp;
}

@property (nonatomic, retain) UIImageView *imageView;

@end

