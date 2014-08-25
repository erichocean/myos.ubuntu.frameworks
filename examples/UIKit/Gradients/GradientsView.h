/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import <UIKit/UIKit.h>
//#import <CoreAnimation/CAGradientLayer-private.h>

@interface GradientsView : UIView
{
    CAGradientLayer *gradientLayer;
    NSTimer *timer;
}

@property (nonatomic, retain) CAGradientLayer *gradientLayer;
@property (nonatomic, assign) NSTimer *timer;

@end

