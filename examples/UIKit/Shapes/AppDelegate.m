/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import "AppDelegate.h"
#import "ShapesView.h"

@implementation AppDelegate

@synthesize window;

#pragma mark - Life cycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    CGRect frame = [[UIScreen mainScreen] bounds];
    self.window = [[[UIWindow alloc] initWithFrame:frame] autorelease];
    window.backgroundColor = [UIColor yellowColor];
    float width = 450;
    float height = 400;
    float x = (frame.size.width - width) / 2.0;
    float y = (frame.size.height - height) / 2.0;
    ShapesView* shapes = [[[ShapesView alloc] initWithFrame:CGRectMake(x,y,width,height)] autorelease];
    [window addSubview:shapes];
    DLog(@"shapes: %@", shapes);
    [window makeKeyAndVisible];

    return YES;
}

- (void)dealloc
{
    [window release];
    [super dealloc];
}

@end

