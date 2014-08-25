/*
 * Copyright (c) 2012. All rights reserved.
 *
 */

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window;

#pragma mark - Life cycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    CGRect frame = [[UIScreen mainScreen] bounds];
    self.window = [[[UIWindow alloc] initWithFrame:frame] autorelease];
    window.backgroundColor = [UIColor yellowColor];
    UILabel* label = [[[UILabel alloc] initWithFrame:CGRectMake(10,10,200,30)] autorelease];
    label.text = @"Test text drawing 12";
    label.textColor = [UIColor redColor];
    label.textAlignment = UITextAlignmentCenter;
    [window addSubview:label];

    label = [[[UILabel alloc] initWithFrame:CGRectMake(10,50,200,30)] autorelease];
    label.text = @"Test text drawing 20";
    label.textColor = [UIColor blueColor];
    label.textAlignment = UITextAlignmentRight;
    label.font = [UIFont boldSystemFontOfSize:20];
    [window addSubview:label];

    label = [[[UILabel alloc] initWithFrame:CGRectMake(10,90,200,30)] autorelease];
    label.text = @"Test text drawing 20";
    label.textAlignment = UITextAlignmentLeft;
    label.font = [UIFont systemFontOfSize:20];
    [window addSubview:label];

    label = [[[UILabel alloc] initWithFrame:CGRectMake(250,10,100,30)] autorelease];
    label.text = @"Test text drawing 12";
    label.textColor = [UIColor redColor];
    label.lineBreakMode = UILineBreakModeMiddleTruncation;
    [window addSubview:label];

    label = [[[UILabel alloc] initWithFrame:CGRectMake(250,50,100,30)] autorelease];
    label.text = @"Test text drawing 20";
    label.textColor = [UIColor blueColor];
    label.lineBreakMode = UILineBreakModeHeadTruncation;
    label.font = [UIFont systemFontOfSize:20];
    [window addSubview:label];

    label = [[[UILabel alloc] initWithFrame:CGRectMake(250,90,100,30)] autorelease];
    label.text = @"Test text drawing 20";
    label.lineBreakMode = UILineBreakModeTailTruncation;
    label.font = [UIFont fontWithName:@"DejaVu Serif-Bold" size:20];
    [window addSubview:label];

    [window makeKeyAndVisible];

    return YES;
}

- (void)dealloc
{
    [window release];
    [super dealloc];
}

@end

