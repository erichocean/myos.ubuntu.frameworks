/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import <CoreGraphics/CGGeometry.h>
#import <CoreGraphics/CGContext-private.h>
#import <X11/Xlib.h>
#import <cairo-xlib.h>

//@class IOWindow;

@interface IOWindow : NSObject
{
@public
    Window xwindow;
    cairo_user_data_key_t cwindow;
    CGContextRef context;
    Display *display;
    CGRect rect;
}
@end

CGContextRef IOWindowCreateContext();
IOWindow *IOWindowCreateSharedWindow();
void IOWindowDestroySharedWindow();
CGContextRef IOWindowCreateContextWithRect(CGRect aRect);
IOWindow *IOWindowGetSharedWindow();
CGContextRef IOWindowContext();
void IOWindowSetContextSize(CGSize size);
void IOWindowFlush();
void IOWindowClear();
