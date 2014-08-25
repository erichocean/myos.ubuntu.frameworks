/*
 * Copyright (c) 2013. All rights reserved.
 *
 * RedRectangle example to show a RedRectangle of the screen using XWindow Server directly
 *
 */

#import "RRAppDelegate.h"
#import "RRSolidView.h"

@implementation RRAppDelegate

@synthesize window;

#pragma mark - Life cycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.window.backgroundColor = [UIColor brownColor];
//    UITextField* display = [[[UITextField alloc] initWithFrame:CGRectMake(10, 20, 70, 30)] autorelease];
//        [display setEditable: NO];
//    [display setBackgroundColor:[UIColor blueColor]];
    //[display setDrawsBackground: YES];
//        [display setAlignment: NSRightTextAlignment];

//    display.text = @"Red Rectangle";
//    [window addSubview: display];

    RRSolidView* solidView = [[[RRSolidView alloc] initWithFrame:CGRectMake(120, 100, 200, 150)] autorelease];
    //solidView.backgroundColor = [UIColor redColor];
    [window addSubview:solidView];
    [window makeKeyAndVisible];
//    RRSolidView* solidView2 = [[[RRSolidView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)] autorelease];
//    [solidView addSubview:solidView2];
    return YES;
}

- (void)dealloc
{
    [window release];
    [super dealloc];
}

@end

