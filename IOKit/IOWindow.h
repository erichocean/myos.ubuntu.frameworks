/*
 Copyright © 2014 myOS Group.
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 Lesser General Public License for more details.
 
 Contributor(s):
 Amr Aboelela <amraboelela@gmail.com>
 
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
