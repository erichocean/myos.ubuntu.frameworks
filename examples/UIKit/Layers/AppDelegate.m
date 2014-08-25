/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import "AppDelegate.h"
#import "SmileyFaceView.h"


@implementation AppDelegate

@synthesize window;
@synthesize layers;
@synthesize blueView;

#pragma mark - Life cycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    //DLog(@"context: %@", context);
    //CGRect frame = [[UIScreen mainScreen] bounds];
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    window.backgroundColor = [UIColor yellowColor];
    //DLog(@"window: %@", window);
    self.blueView = [[[BlueView alloc] initWithFrame:CGRectMake(20,20,370,340)] autorelease];
    //DLog(@"blueView: %@", blueView);
    [window addSubview:blueView];
    [window makeKeyAndVisible];

    SmileyFaceView *smiley = [[[SmileyFaceView alloc] initWithFrame:CGRectMake(40,50,51,51)] autorelease];
    [blueView addSubview:smiley];
/*
    SmileyFaceView *subSmiley = [[[SmileyFaceView alloc] initWithFrame:CGRectMake(5,5,50,50)] autorelease];
    [smiley addSubview:subSmiley];	
    smiley = [[[SmileyFaceView alloc] initWithFrame:CGRectMake(5,5,50,50)] autorelease];
    [subSmiley addSubview:smiley];
*/
    DLog(@"smiley: %@", smiley);
    smiley = [[[SmileyFaceView alloc] initWithFrame:CGRectMake(250,40,50,50)] autorelease];
    [blueView addSubview:smiley];
    smiley = [[[SmileyFaceView alloc] initWithFrame:CGRectMake(260,50,50,50)] autorelease];
    [blueView addSubview:smiley];
    smiley = [[[SmileyFaceView alloc] initWithFrame:CGRectMake(150,140,50,50)] autorelease];
    smiley.backgroundColor = [UIColor greenColor];
    [blueView addSubview:smiley];
    smiley = [[[SmileyFaceView alloc] initWithFrame:CGRectMake(160,165,50,50)] autorelease];
    [blueView addSubview:smiley];

/*
    self.layers = [[Layers alloc] initWithContext:context andBorder:frame];
    DLog(@"layers: %@", layers);
    [layers fillBorder];
    [layers draw2];
    [layers draw];
    [layers draw2];*/

    return YES;

/*
    self.window = [[[UIWindow alloc] initWithFrame:CGRectMake(10, 10, 100, 150)] autorelease];
    UITextField* display = [[[UITextField alloc] initWithFrame:CGRectMake(10, 20, 70, 30)] autorelease];
//        [display setEditable: NO];
    [display setBackgroundColor:[UIColor blueColor]];
    //[display setDrawsBackground: YES];
//        [display setAlignment: NSRightTextAlignment];

    display.text = @"Red Rectangle";
    [window addSubview: display];

    RRSolidView* solidView = [[[RRSolidView alloc] initWithFrame:CGRectMake(20, 70, 200, 100)] autorelease];
    [window addSubview:solidView];

    [window makeKeyAndVisible];*/

}

- (void)dealloc
{
    [window release];
    [layers release];
    [blueView release];
    [super dealloc];
}

#pragma mark - Notifications

@end

