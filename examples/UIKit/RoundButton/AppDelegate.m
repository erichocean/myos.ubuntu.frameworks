/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import "AppDelegate.h"
#import "RoundButtonView.h"

@implementation AppDelegate

@synthesize window;

#pragma mark - Life cycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    //DLog(@"screenBounds: %@", NSStringFromCGRect(screenBounds));
    self.window = [[[UIWindow alloc] initWithFrame:screenBounds] autorelease];
    window.backgroundColor = [UIColor brownColor];
    float width = 300;
    float height = 200;
    float x = (screenBounds.size.width - width) / 2.0;
    float y = (screenBounds.size.height - height) / 2.0;
    RoundButtonView *buttonView = [[[RoundButtonView alloc] initWithFrame:CGRectMake(x,y,width,height)] autorelease];
    [window addSubview:buttonView];
    //DLog(@"buttonView: %@", buttonView);
    [window makeKeyAndVisible];

    return YES;
}

- (void)dealloc
{
    [window release];
    [super dealloc];
}

@end

