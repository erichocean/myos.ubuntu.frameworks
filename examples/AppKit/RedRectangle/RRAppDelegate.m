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

- (id)init
{
    self.window = [[[NSWindow alloc] initWithContentRect: NSMakeRect (30, 100, 325, 311)
          	styleMask: (NSTitledWindowMask | NSMiniaturizableWindowMask)
       	    	backing: NSBackingStoreBuffered
       		defer: NO] autorelease];
    NSTextField* display = [[[NSTextField alloc] initWithFrame:NSMakeRect(100, 200, 130, 30)] autorelease];
//        [display setEditable: NO];
    [display setBackgroundColor:[NSColor blueColor]];
    [display setDrawsBackground: YES];
//        [display setAlignment: NSRightTextAlignment];

    [display setStringValue: @"Red Rectangle"];
    [[window contentView] addSubview: display];
    [window setTitle: @"RedRectangle.app"];
    [window center];

    RRSolidView* solidView = [[[RRSolidView alloc] initWithFrame:NSMakeRect(20, 70, 200, 100)] autorelease];
    [[window contentView] addSubview:solidView];

    return self;
}

- (void)dealloc
{
    [window release];
}

#pragma mark - Notifications

- (void)applicationDidFinishLaunching: (NSNotification *)aNotification
{
    //DLog(@"aNotification: %@", aNotification);
    [window orderFront: self];
}
@end

