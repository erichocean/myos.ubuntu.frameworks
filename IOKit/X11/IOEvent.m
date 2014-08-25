/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import "IOEvent.h"
#import <cairo-xlib.h>
#import <UIKit/UIEvent.h>
#import <UIKit/UITouch-private.h>

static XEvent _xevent;

#define _KIOEventTimeDiffMax	0.27

//static IOEventRef _event = nil;
UIEvent* IOEventUIEventFromXEvent(XEvent e);

BOOL IOEventGetNextEvent(IOWindow * window, UIEvent *uievent)
{
    //XEvent e;

    //IOWindow* window = [IOWindow sharedWindow];
    //Display *d = window->display;
    //CGContextRef ctx = window->context;
    //DLog(@"");
    //while (YES) {
    //    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    //DLog(@"");
    //XNextEvent(d,&_xevent);
    //DLog(@"e: %d", _xevent.type);
    
    if (XCheckWindowEvent(window->display, window->xwindow, ButtonPressMask | Button1MotionMask | ButtonReleaseMask, &_xevent)) {
        UITouch *touch = [[uievent allTouches] anyObject];
        CGPoint screenLocation = CGPointMake(_xevent.xbutton.x, _xevent.xbutton.y);
        NSTimeInterval timestamp = _xevent.xbutton.time / 1000.0;
        switch (_xevent.type) {
            case ButtonPress: {
                CGPoint delta = CGPointZero;
                int tapCount = 1;//touch.tapCount;
                NSTimeInterval timeDiff = fabs(touch.timestamp - timestamp);
                if (touch.phase == UITouchPhaseEnded && timeDiff < _KIOEventTimeDiffMax) {
                    tapCount = touch.tapCount+1;
                }
                _UITouchSetPhase(touch, UITouchPhaseBegan, screenLocation, tapCount, delta, timestamp);
                break;
            }
            case MotionNotify:
                _UITouchUpdatePhase(touch, UITouchPhaseMoved, screenLocation, timestamp);
                break;
            case ButtonRelease:
                _UITouchUpdatePhase(touch, UITouchPhaseEnded, screenLocation, timestamp);
                break;
        }
        //DLog(@"touch: %@", touch);
        return YES;
    } else {
        return NO;
    }
    
    
/*    
switch (e.type) {
        case Expose:
            DLog(@"Expose");
             Dispose multiple events 
            while (XCheckTypedEvent(d, Expose, &e));
             Draw window contents 
            if (e.xexpose.count == 0) {
                //CGContextSaveGState(ctx);
                //XClearWindow(d, win);
                //draw(ctx, cr);
                //CGContextRestoreGState(ctx);
            }
            break;
        case ConfigureNotify: {
            DLog(@"ConfigureNotify");
            CGRect cr = window->rect;
            if (cr.size.width != e.xconfigure.width || cr.size.height != e.xconfigure.height) {
                cr.size.width = e.xconfigure.width;
                cr.size.height = e.xconfigure.height;
                NSLog(@"New rect: %f x %f", (float)cr.size.width, (float)cr.size.height);
                IOWindowSetContextSize(cr.size);                    
            }
            break;
        }
        case ButtonRelease:
            DLog(@"ButtonRelease");
             Finish program 
            CGContextRelease(ctx);
            XCloseDisplay(d);
            exit(EXIT_SUCCESS);
            DLog(@"Closing");
            break;
        default: {
            DLog(@"default");
            //if ([delegate respondsToSelector:@selector(sendEvent:)]) {
            //[delegate performSelector:@selector(sendEvent:) withObject:[self UIEventFromXEvent:e]];
            //}
            break; 
        }
    }
    return IOEventUIEventFromXEvent(e);*/
    //  [pool release];
    // }
}

BOOL IOEventCanDrawWindow(IOWindow * window)
{
    //Display *d = window->display;

    while( XCheckWindowEvent(window->display, window->xwindow, ExposureMask, &_xevent) ) {
             if (_xevent.xexpose.count == 0) {
                return YES;
                //CGContextSaveGState(ctx);
                //XClearWindow(d, win);
                //draw(ctx, cr);
                //CGContextRestoreGState(ctx);
            }
    }
/*
    while( XPending(d) ) {
    XNextEvent(d,&_xevent);
    switch (_xevent.type) {
        case Expose:
            DLog(@"Expose");
            // Dispose multiple events
            while (XCheckTypedEvent(d, Expose, &_xevent));
            // Draw window contents 
            if (_xevent.xexpose.count == 0) {
                return YES;
                //CGContextSaveGState(ctx);
                //XClearWindow(d, win);
                //draw(ctx, cr);
                //CGContextRestoreGState(ctx);
            }
            break;
         default:
            //DLog(@"default");
            break; 
    }
    }*/
    return NO;
}

UIEvent* IOEventUIEventFromXEvent(XEvent e)
{
    return [[[UIEvent alloc] initWithEventType:UIEventTypeTouches] autorelease];
}
