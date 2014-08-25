/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import "AppDelegate.h"
#import "AnimationGradientsView.h"

@implementation AppDelegate

@synthesize window;

#pragma mark - Life cycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    CGRect frame = [[UIScreen mainScreen] bounds];
    self.window = [[[UIWindow alloc] initWithFrame:frame] autorelease];
    window.backgroundColor = [UIColor brownColor];
    float width = 500;
    float height = 300;
    float x = (frame.size.width - width) / 2.0;
    float y = (frame.size.height - height) / 2.0;
    AnimationGradientsView *gradients = [[[AnimationGradientsView alloc] initWithFrame:CGRectMake(x,y,width,height)] autorelease];
    [window addSubview:gradients];

    AnimationGradientsView *gradients2;

    gradients2 = [[[AnimationGradientsView alloc] initWithFrame:CGRectMake(x+15,y-70,width-30,150)] autorelease];
    [window addSubview:gradients2];
    gradients2 = [[[AnimationGradientsView alloc] initWithFrame:CGRectMake(x+95,y+height-180,width-170,50)] autorelease];
    [window addSubview:gradients2];

    gradients2 = [[[AnimationGradientsView alloc] initWithFrame:CGRectMake(25,50,width-50,100)] autorelease];
    [gradients addSubview:gradients2];

    [window makeKeyAndVisible];

    return YES;
}

- (void)dealloc
{
    [window release];
    [super dealloc];
}

@end

