/*
 * Copyright (c) 2012. All rights reserved.
 *
 */

#import "BigApple_Prefix.pch"
#import <CoreGraphics/CoreGraphics.h>

@interface BigAppleDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    UIImageView *appleView;
    UIButton *sillyButton;
}

@property (retain) UIWindow *window;
@property (retain) UIImageView *appleView;
@property (retain) UIButton *sillyButton;

@end

