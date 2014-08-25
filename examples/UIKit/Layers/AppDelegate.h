/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import "Layers.h"
#import "BlueView.h"

@interface AppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow* window;
    Layers* layers;
    BlueView* blueView;
}

@property (nonatomic, retain) UIWindow* window;
@property (nonatomic, retain) Layers* layers;
@property (nonatomic, retain) BlueView* blueView;

@end
