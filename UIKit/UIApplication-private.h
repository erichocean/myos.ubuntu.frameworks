/*
 Copyright © 2014 myOS Group.
 
 This file is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2 of the License, or (at your option) any later version.
 
 This file is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 Lesser General Public License for more details.
 
 Contributor(s):
 Amr Aboelela <amraboelela@gmail.com>
 */

#import <UIKit/UIApplication.h>
#import <rd_app_glue.h>

typedef enum {
    _UIApplicationScreenModeActive,
    _UIApplicationScreenModeSleeping,
    _UIApplicationScreenModeOff
} _UIApplicationScreenMode;

@class UIWindow, UIScreen;

void _UIApplicationMain(struct android_app *app, NSString *appName, NSString *delegateClassName);
void _UIApplicationSetKeyWindow(UIApplication *app, UIWindow *newKeyWindow);
void _UIApplicationWindowDidBecomeVisible(UIApplication *app, UIWindow *theWindow);
void _UIApplicationWindowDidBecomeHidden(UIApplication *app, UIWindow *theWindow);
void _UIApplicationCancelTouchesInView(UIApplication *app, UIView *aView);
UIResponder *_UIApplicationFirstResponderForScreen(UIApplication *app, UIScreen *screen);
BOOL _UIApplicationFirstResponderCanPerformAction(UIApplication *app, SEL action, id sender, UIScreen *theScreen);
BOOL _UIApplicationSendActionToFirstResponder(UIApplication *app, SEL action, id sender, UIScreen *theScreen);
void _UIApplicationRemoveViewFromTouches(UIApplication* application, UIView *aView);
void _UIApplicationSetCurrentEventTouchedView();
void _UIApplicationSendEvent(UIEvent *event);
void _UIApplicationEnterForeground();
BOOL _UIApplicationEnterBackground();
