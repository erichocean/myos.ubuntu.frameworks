/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import <UIKit/UIApplication.h>

typedef enum {
    _UIApplicationScreenModeActive,
    _UIApplicationScreenModeSleeping,
    _UIApplicationScreenModeOff
} _UIApplicationScreenMode;

@class UIWindow, UIScreen;

void _UIApplicationSetKeyWindow(UIApplication *app, UIWindow *newKeyWindow);
void _UIApplicationWindowDidBecomeVisible(UIApplication *app, UIWindow *theWindow);
void _UIApplicationWindowDidBecomeHidden(UIApplication *app, UIWindow *theWindow);
void _UIApplicationCancelTouchesInView(UIApplication *app, UIView *aView);
UIResponder* _UIApplicationFirstResponderForScreen(UIApplication *app, UIScreen *screen);
BOOL _UIApplicationFirstResponderCanPerformAction(UIApplication *app, SEL action, id sender, UIScreen *theScreen);
BOOL _UIApplicationSendActionToFirstResponder(UIApplication *app, SEL action, id sender, UIScreen *theScreen);
void _UIApplicationRemoveViewFromTouches(UIApplication* application, UIView *aView);
//void _UIApplicationDrawLayer();
//CGLayerRef _UIApplicationMakeSampleLayer(CGContextRef aContext);
void _UIApplicationSetCurrentEventTouchedView();
void _UIApplicationSendEvent(UIEvent *event);

