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

#import "IOWindow.h"

/* Internal cairo API, declare it here to avoid dependencies of cairoint.h */
extern void _cairo_surface_set_device_scale(cairo_surface_t *surface, double sx, double sy);


#pragma mark - Class methods

static IOWindow *_window = nil;

@implementation IOWindow

- (void)dealloc
{
    [super dealloc];
}

@end

IOWindow *IOWindowCreateSharedWindow()
{
    if (_window) {
        [_window release];
    }
    _window = [[IOWindow alloc] init];
    return _window;
}

IOWindow *IOWindowGetSharedWindow()
{
    return _window;
}

void IOWindowDestroySharedWindow()
{
    if (_window) {
        [_window release];
    }
    _window = nil;
}

CGContextRef IOWindowCreateContextWithRect(CGRect aRect)
{
    XSetWindowAttributes wa;

    _window->rect = aRect;
    _window->display = XOpenDisplay(NULL);
    //DLog(@"display: %p", _window->display);
    if (!_window->display) {
        fprintf(stderr, "Cannot open display: %s\n", XDisplayName(NULL));
        exit(EXIT_FAILURE);
    }
    //printf("Opened display %s\n", DisplayString(_window->display));

    //cr = CGRectMake(0,0,640,480);
    wa.background_pixel = WhitePixel(_window->display, DefaultScreen(_window->display));
    wa.event_mask = ExposureMask | ButtonPressMask | Button1MotionMask | ButtonReleaseMask;

    /* Create a window */
    _window->xwindow = XCreateWindow(_window->display, /* Display */
                DefaultRootWindow(_window->display), /* Parent */
                _window->rect.origin.x, _window->rect.origin.y, /* x, y */
                _window->rect.size.width, _window->rect.size.height, /* width, height */
                0, /* border_width */
                CopyFromParent, /* depth */
                InputOutput, /* class */
                CopyFromParent, /* visual */
                CWBackPixel | CWEventMask, /* valuemask */
                &wa); /* attributes */
    //printf("XCreateWindow returned: %lx\n", _window->xwindow);
    XSelectInput(_window->display, _window->xwindow, ExposureMask | StructureNotifyMask | ButtonPressMask | Button1MotionMask | ButtonReleaseMask);
    /* Map the window */
    int ret = XMapRaised(_window->display, _window->xwindow);
    //printf("XMapRaised returned: %x\n", ret);

    /* Create a CGContext */
    _window->context = IOWindowCreateContext();
    if (!_window->context) {
        fprintf(stderr,"Cannot create context\n");
        exit(EXIT_FAILURE);
    }
    //printf("Created context\n");
    return _window->context;
}

CGContextRef IOWindowCreateContext()
{
    CGContextRef ctx;
    XWindowAttributes wa;
    cairo_surface_t *target;
    int ret;

    ret = XGetWindowAttributes(_window->display, _window->xwindow, &wa);
    if (!ret) {
        NSLog(@"XGetWindowAttributes returned %d", ret);
        return NULL;
    }
    target = cairo_xlib_surface_create(_window->display, _window->xwindow, wa.visual, wa.width, wa.height);
    /* May not need this but left here for reference */
    ret = cairo_surface_set_user_data(target, &_window->cwindow, (void *)_window->xwindow, NULL);
    if (ret) {
        NSLog(@"cairo_surface_set_user_data %s", cairo_status_to_string(CAIRO_STATUS_NO_MEMORY));
        cairo_surface_destroy(target);
        return NULL;
    }
    /* Flip coordinate system */
    //cairo_surface_set_device_offset(target, 0, wa.height);
    /* FIXME: The scale part of device transform does not work correctly in
     * cairo so for now we have to patch the CTM! This should really be fixed
     * in cairo and then the ScaleCTM call below and the hacks in GetCTM in
     * CGContext should be removed in favour of the following line: */
    /* _cairo_surface_set_device_scale(target, 1.0, -1.0); */
    
    // NOTE: It doesn't looks like cairo will support using both device_scale and 
    //             device_offset any time soon, so I moved the translation part of the
    //             flip to the transformation matrix, to be consistent.
    //             - Eric
    ctx = opal_new_CGContext(target, CGSizeMake(wa.width, wa.height));
    cairo_surface_destroy(target);
    return ctx;
}

void IOWindowSetContextSize(CGSize size)
{
    _window->rect.size = size;
    OPContextSetSize(_window->context, size); // Updates CTM
    cairo_xlib_surface_set_size(cairo_get_target(_window->context->ct), size.width, size.height);
}

CGContextRef IOWindowContext()
{
    return _window->context;
}

void IOWindowFlush()
{
//    XFlushGC(_window->display, _window->context);
    XFlush(_window->display);
}

void IOWindowClear()
{
    XClearWindow(_window->display, _window->xwindow);
}
