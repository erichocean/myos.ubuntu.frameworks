/*
 * Copyright (c) 2013. All rights reserved.
 *
 * RedRectangle example to show a RedRectangle of the screen using XWindow Server directly
 *
 */

#import "RRAppDelegate.h"

int main(int argc, char *argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    DLog(@"RedRectangle");
    NSApplication* app = [NSApplication sharedApplication];
    RRAppDelegate* appDelegate = [[RRAppDelegate alloc] init];
    app.delegate = appDelegate;
    [app run];
/*
    NSGraphicsContext *ctxt = GSCurrentContext();
    DLog(@"ctxt: %@", ctxt);
    [[NSColor redColor] set];
    [[NSColor redColor] setFill];
    NSRectFill(NSMakeRect(200,200,200,200));
*/  
    [pool release];
    return 0;
}

