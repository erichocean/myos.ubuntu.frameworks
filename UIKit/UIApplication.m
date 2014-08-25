/*
 * Copyright (c) 2011, The Iconfactory. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of The Iconfactory nor the names of its contributors may
 *    be used to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE ICONFACTORY BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <UIKit/UIKit-private.h>
#import <UIKit/UIGraphics.h>
#import <UIKit/UIColor.h>
#import <UIKit/UITapGestureRecognizer.h>
#import <UIKit/UIBackgroundTask.h>
#import <IOKit/IOKit.h>
#import <CoreAnimation/CoreAnimation-private.h>

#define _kInactiveTimeLimit 30.0
#define _kLongInactiveTimeLimit 60.0

NSString *const UIApplicationWillChangeStatusBarOrientationNotification = @"UIApplicationWillChangeStatusBarOrientationNotification";
NSString *const UIApplicationDidChangeStatusBarOrientationNotification = @"UIApplicationDidChangeStatusBarOrientationNotification";
NSString *const UIApplicationWillEnterForegroundNotification = @"UIApplicationWillEnterForegroundNotification";
NSString *const UIApplicationWillTerminateNotification = @"UIApplicationWillTerminateNotification";
NSString *const UIApplicationWillResignActiveNotification = @"UIApplicationWillResignActiveNotification";
NSString *const UIApplicationDidEnterBackgroundNotification = @"UIApplicationDidEnterBackgroundNotification";
NSString *const UIApplicationDidBecomeActiveNotification = @"UIApplicationDidBecomeActiveNotification";
NSString *const UIApplicationDidFinishLaunchingNotification = @"UIApplicationDidFinishLaunchingNotification";
NSString *const UIApplicationNetworkActivityIndicatorChangedNotification = @"UIApplicationNetworkActivityIndicatorChangedNotification";
NSString *const UIApplicationLaunchOptionsURLKey = @"UIApplicationLaunchOptionsURLKey";
NSString *const UIApplicationLaunchOptionsSourceApplicationKey = @"UIApplicationLaunchOptionsSourceApplicationKey";
NSString *const UIApplicationLaunchOptionsRemoteNotificationKey = @"UIApplicationLaunchOptionsRemoteNotificationKey";
NSString *const UIApplicationLaunchOptionsAnnotationKey = @"UIApplicationLaunchOptionsAnnotationKey";
NSString *const UIApplicationLaunchOptionsLocalNotificationKey = @"UIApplicationLaunchOptionsLocalNotificationKey";
NSString *const UIApplicationLaunchOptionsLocationKey = @"UIApplicationLaunchOptionsLocationKey";
NSString *const UIApplicationDidReceiveMemoryWarningNotification = @"UIApplicationDidReceiveMemoryWarningNotification";
NSString *const UITrackingRunLoopMode = @"UITrackingRunLoopMode";

const UIBackgroundTaskIdentifier UIBackgroundTaskInvalid = NSUIntegerMax; // correct?
const NSTimeInterval UIMinimumKeepAliveTimeout = 0;
static UIApplication *_application = nil;

void _UIApplicationLaunchApplicationWithDefaultWindow(UIWindow* window);

static BOOL TouchIsActiveGesture(UITouch *touch)
{
    return (touch.phase == _UITouchPhaseGestureBegan || touch.phase == _UITouchPhaseGestureChanged);
}

static BOOL TouchIsActiveNonGesture(UITouch *touch)
{
    return (touch.phase == UITouchPhaseBegan || touch.phase == UITouchPhaseMoved || touch.phase == UITouchPhaseStationary);
}

static BOOL TouchIsActive(UITouch *touch)
{
    return TouchIsActiveGesture(touch) || TouchIsActiveNonGesture(touch);
}

@implementation UIApplication

@synthesize keyWindow=_keyWindow; 
@synthesize delegate=_delegate; 
@synthesize idleTimerDisabled=_idleTimerDisabled; 
@synthesize applicationSupportsShakeToEdit=_applicationSupportsShakeToEdit;
@synthesize applicationIconBadgeNumber=_applicationIconBadgeNumber;
@synthesize applicationState=_applicationState;

#pragma mark - Life cycle

- (id)init
{
    if ((self=[super init])) {
        _currentEvent = [[UIEvent alloc] initWithEventType:UIEventTypeTouches];
        _UIEventSetTouch(_currentEvent, [[[UITouch alloc] init] autorelease]);
        _visibleWindows = [[NSMutableSet alloc] init];
        _backgroundTasks = [[NSMutableArray alloc] init];
        _applicationState = UIApplicationStateActive;
        _applicationSupportsShakeToEdit = YES;		// yeah... not *really* true, but UIKit defaults to YES :)
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_currentEvent release];
    [_visibleWindows release];
    [_backgroundTasks release];
    [_backgroundTasksExpirationDate release];
    [_blackScreen release];
    IOWindowDestroySharedWindow();
    [super dealloc];
}

#pragma mark - Class methods

/*
 + (void)initialize
 {
 if (self == [UIApplication class]) {
 _application = [[UIApplication alloc] init];
 }
 }*/

+ (UIApplication *)sharedApplication
{
    return _application;
}

#pragma mark - Accessors

- (BOOL)isStatusBarHidden
{
    return YES;
}

- (BOOL)isNetworkActivityIndicatorVisible
{
    return _networkActivityIndicatorVisible;
}

- (void)setNetworkActivityIndicatorVisible:(BOOL)b
{
    if (b != [self isNetworkActivityIndicatorVisible]) {
        _networkActivityIndicatorVisible = b;
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationNetworkActivityIndicatorChangedNotification object:self];
    }
}

- (BOOL)isIgnoringInteractionEvents
{
    return (_ignoringInteractionEvents > 0);
}

- (UIInterfaceOrientation)statusBarOrientation
{
    return UIInterfaceOrientationPortrait;
}

- (void)setStatusBarOrientation:(UIInterfaceOrientation)orientation
{
}

- (UIStatusBarStyle)statusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void)setStatusBarStyle:(UIStatusBarStyle)statusBarStyle
{
}

- (void)setStatusBarStyle:(UIStatusBarStyle)statusBarStyle animated:(BOOL)animated
{
}

- (NSTimeInterval)statusBarOrientationAnimationDuration
{
    return 0.3;
}

- (CGRect)statusBarFrame
{
    return CGRectZero;
}

- (NSTimeInterval)backgroundTimeRemaining
{
    return [_backgroundTasksExpirationDate timeIntervalSinceNow];
}

- (NSArray *)scheduledLocalNotifications
{
    return nil;
}

- (void)setScheduledLocalNotifications:(NSArray *)scheduledLocalNotifications
{
}

- (NSArray *)windows
{
    NSSortDescriptor *sort = [[[NSSortDescriptor alloc] initWithKey:@"windowLevel" ascending:YES] autorelease];
    return [[_visibleWindows valueForKey:@"nonretainedObjectValue"] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
}

#pragma mark - Delegate

- (void)turnOnScreen:(id)sender
{
    [_blackScreen removeFromSuperview];
    _lastActivityTime = CACurrentMediaTime();
    _screenMode = _UIApplicationScreenModeActive;
}

#pragma mark - Helpers

- (void)beginIgnoringInteractionEvents
{
    _ignoringInteractionEvents++;
}

- (void)endIgnoringInteractionEvents
{
    _ignoringInteractionEvents--;
}

- (void)cancelAllLocalNotifications
{
}

- (UIBackgroundTaskIdentifier)beginBackgroundTaskWithExpirationHandler:(void(^)(void))handler
{
    UIBackgroundTask *task = [[[UIBackgroundTask alloc] initWithExpirationHandler:handler] autorelease];
    [_backgroundTasks addObject:task];
    return task.taskIdentifier;
}

- (void)endBackgroundTask:(UIBackgroundTaskIdentifier)identifier
{
    for (UIBackgroundTask *task in _backgroundTasks) {
        if (task.taskIdentifier == identifier) {
            [_backgroundTasks removeObject:task];
            break;
        }
    }
}

- (BOOL)sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event
{
    if (!target) {
        // The docs say this method will start with the first responder if target==nil. Initially I thought this meant that there was always a given
        // or set first responder (attached to the window, probably). However it doesn't appear that is the case. Instead it seems UIKit is perfectly
        // happy to function without ever having any UIResponder having had a becomeFirstResponder sent to it. This method seems to work by starting
        // with sender and traveling down the responder chain from there if target==nil. The first object that responds to the given action is sent
        // the message. (or no one is)
        
        // My confusion comes from the fact that motion events and keyboard events are supposed to start with the first responder - but what is that
        // if none was ever set? Apparently the answer is, if none were set, the message doesn't get delivered. If you expicitly set a UIResponder
        // using becomeFirstResponder, then it will receive keyboard/motion events but it does not receive any other messages from other views that
        // happen to end up calling this method with a nil target. So that's a seperate mechanism and I think it's confused a bit in the docs.
        
        // It seems that the reality of message delivery to "first responder" is that it depends a bit on the source. If the source is an external
        // event like motion or keyboard, then there has to have been an explicitly set first responder (by way of becomeFirstResponder) in order for
        // those events to even get delivered at all. If there is no responder defined, the action is simply never sent and thus never received.
        // This is entirely independent of what "first responder" means in the context of a UIControl. Instead, for a UIControl, the first responder
        // is the first UIResponder (including the UIControl itself) that responds to the action. It starts with the UIControl (sender) and not with
        // whatever UIResponder may have been set with becomeFirstResponder.
        
        id responder = sender;
        while (responder) {
            if ([responder respondsToSelector:action]) {
                target = responder;
                break;
            } else if ([responder respondsToSelector:@selector(nextResponder)]) {
                responder = [responder nextResponder];
            } else {
                responder = nil;
            }
        }
    }
    if (target) {
        [target performSelector:action withObject:sender withObject:event];
        return YES;
    } else {
        return NO;
    }
}

- (void)sendEvent:(UIEvent *)event
{
    _UIApplicationSendEvent(event);
}

- (void)_runBackgroundTasks:(void (^)(void))run_tasks
{
    run_tasks();
}

@end

@implementation UIApplication(UIApplicationDeprecated)

- (void)setStatusBarHidden:(BOOL)hidden animated:(BOOL)animated
{
}

@end

#pragma mark - Private C functions

int UIApplicationMain(int argc, char *argv[], NSString *principalClassName, NSString *delegateClassName)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    IOWindow *window = IOWindowCreateSharedWindow();
    CGRect cr = CGRectMake(0,0,640,480);
    CGContextRef ctx = IOWindowCreateContextWithRect(cr);
    UIGraphicsPushContext(ctx); 
    BOOL canDraw = NO;
    while (!canDraw) {
        if (IOEventCanDrawWindow(window)) {
            canDraw = YES;
        }
    } 
    NSTimeInterval currentTime = CACurrentMediaTime();
    
    _application = [[UIApplication alloc] init];
    Class appDelegateClass = NSClassFromString(delegateClassName);
    id appDelegate = [[appDelegateClass alloc] init];
    _application->_delegate = appDelegate;
    //DLog();
 
    [[UIScreen alloc] initWithBounds:cr];

    // Setting up the screen sleeping ability
    _application->_lastActivityTime = CACurrentMediaTime();
    _application->_blackScreen = [[UIView alloc] initWithFrame:cr];
    _application->_blackScreen.backgroundColor = [UIColor blackColor];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:_application 
                                                                                 action:@selector(turnOnScreen:)];
    [_application->_blackScreen addGestureRecognizer:tapGesture];

   _UIApplicationLaunchApplicationWithDefaultWindow(nil);
    
    //NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
    //DLog(@"currentRunLoop: %@", currentRunLoop);
    
   while (YES) {
        NSAutoreleasePool *pool2 = [[NSAutoreleasePool alloc] init];
        
        NSDate *limit = [[NSDate alloc] initWithTimeIntervalSinceNow:0.01];
        [[NSRunLoop currentRunLoop] runUntilDate:limit];
        [limit release];
        if (IOEventGetNextEvent(window, _application->_currentEvent)) {
            _UIApplicationSetCurrentEventTouchedView();
            _application->_lastActivityTime = CACurrentMediaTime();
        }
        currentTime = CACurrentMediaTime();
        if (currentTime - _application->_lastActivityTime > _kInactiveTimeLimit 
             && _application->_screenMode == _UIApplicationScreenModeActive) {
            _application->_screenMode = _UIApplicationScreenModeSleeping;
            [_application->_keyWindow addSubview:_application->_blackScreen];
            _application->_blackScreen.alpha = 0.0;
            [UIView beginAnimations:@"gotoSleep" context:nil];
            [UIView setAnimationDuration:0.5];
            _application->_blackScreen.alpha = 0.8;
            [UIView commitAnimations];
            //[NSTimer scheduledTimerWithTimeInterval:2 target:_application selector:@selector(turnONScreen) userInfo:nil repeats:NO];
        } 
        if (currentTime - _application->_lastActivityTime > _kLongInactiveTimeLimit 
             && _application->_screenMode == _UIApplicationScreenModeSleeping) {
            _application->_screenMode = _UIApplicationScreenModeOff;
            [UIView beginAnimations:@"gotoSleep" context:nil];
            [UIView setAnimationDuration:1.0];
            _application->_blackScreen.alpha = 1.0;
            [UIView commitAnimations];
        } 
        [pool2 release];
        //DLog(@"Free memory: %ld KB", CFGetFreeMemory());
    }
    //[tapGesture release];
    [pool release];
}

void _UIApplicationSetKeyWindow(UIApplication *application, UIWindow *newKeyWindow)
{
    application->_keyWindow = newKeyWindow;
    //DLog(@"_keyWindow: %@", application->_keyWindow);
}

void _UIApplicationLaunchApplicationWithDefaultWindow(UIWindow* window)
{
    //UIApplication *app = [UIApplication sharedApplication];
    id<UIApplicationDelegate> appDelegate = _application->_delegate;

    if ([appDelegate respondsToSelector:@selector(application:didFinishLaunchingWithOptions:)]) {
        [appDelegate application:_application didFinishLaunchingWithOptions:nil];
    }
    else if ([appDelegate respondsToSelector:@selector(applicationDidFinishLaunching:)]) {
        [appDelegate applicationDidFinishLaunching:_application];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidFinishLaunchingNotification
                                                        object:_application];
    if ([appDelegate respondsToSelector:@selector(applicationDidBecomeActive:)]) {
        [appDelegate applicationDidBecomeActive:_application];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification
                                                        object:_application];
}

void _UIApplicationWindowDidBecomeVisible(UIApplication* application, UIWindow* theWindow)
{
    [application->_visibleWindows addObject:[NSValue valueWithNonretainedObject:theWindow]];
}

void _UIApplicationWindowDidBecomeHidden(UIApplication* application, UIWindow* theWindow)
{
    if (theWindow == application->_keyWindow) {
        _UIApplicationSetKeyWindow(application, nil);
    }
    [application->_visibleWindows removeObject:[NSValue valueWithNonretainedObject:theWindow]];
}

void _UIApplicationEnterForeground(UIApplication* application)
{
    if (application->_applicationState == UIApplicationStateBackground) {
        if ([application->_delegate respondsToSelector:@selector(applicationWillEnterForeground:)]) {
            [application->_delegate applicationWillEnterForeground:application];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:application];
        application->_applicationState = UIApplicationStateInactive;
    }
}

BOOL _UIApplicationEnterBackground(UIApplication* application)
{
    if (application->_applicationState != UIApplicationStateBackground) {
        application->_applicationState = UIApplicationStateBackground;
        if ([application->_delegate respondsToSelector:@selector(applicationDidEnterBackground:)]) {
            [application->_delegate applicationDidEnterBackground:application];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:application];
        return YES;
    } else {
        return NO;
    }
}

void _UIApplicationSetCurrentEventTouchedView()
{
    UIEvent *currentEvent = _application->_currentEvent;
    NSSet *touches = [currentEvent allTouches];
    UITouch *touch = [touches anyObject];
    UIView *previousView = [touch.view retain];
    CGPoint screenLocation = touch->_location;
    UIScreen *theScreen = _application->_keyWindow->_screen;
    UIView *hitView = _UIScreenHitTest(theScreen, screenLocation, currentEvent);
    _UITouchSetTouchedView(touch, hitView);
    if (hitView != previousView) {
        const UITouchPhase phase = touch.phase;
        if (phase == UITouchPhaseMoved) {
            [previousView touchesMoved:touches withEvent:currentEvent];
        }
    }
    _UIApplicationSendEvent(currentEvent);
    [previousView release];
}

void _UIApplicationSendEvent(UIEvent *event)
{
    for (UITouch *touch in [event allTouches]) {
        [touch.window sendEvent:event];
    }
}

BOOL _UIApplicationRunRunLoopForBackgroundTasksBeforeDate(UIApplication *application, NSDate *date)
{
    // check if all tasks were done, and if so, break
    if ([application->_backgroundTasks count] == 0) {
        return NO;
    }
    // run the runloop in the default mode so things like connections and timers still work for processing our
    // background tasks. we'll make sure not to run this any longer than 1 second at a time, otherwise the alert
    // might hang around for a lot longer than is necessary since we might not have anything to run in the default
    // mode for awhile or something which would keep this method from returning.
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:date];
    // otherwise check if we've timed out and if we are, break
    if ([[NSDate date] timeIntervalSinceReferenceDate] >= [application->_backgroundTasksExpirationDate timeIntervalSinceReferenceDate]) {
        return NO;
    }
    return YES;
}

void _UIApplicationCancelBackgroundTasks(UIApplication* application)
{
    // if there's any remaining tasks, run their expiration handlers
    for (UIBackgroundTask *task in application->_backgroundTasks) {
        if (task.expirationHandler) {
            task.expirationHandler();
        }
    }
    // remove any lingering tasks so we're back to being empty
    [application->_backgroundTasks removeAllObjects];
}

UIResponder *_UIApplicationFirstResponderForScreen(UIApplication* application, UIScreen* screen)
{
    if (application->_keyWindow.screen == screen) {
        return application->_keyWindow->_firstResponder;
    } else {
        return nil;
    }
}

BOOL _UIApplicationSendActionToFirstResponder(UIApplication* application, SEL action, id sender, UIScreen* theScreen)
{
    UIResponder *responder = _UIApplicationFirstResponderForScreen(application, theScreen);
    while (responder) {
        if ([responder respondsToSelector:action]) {
            [responder performSelector:action withObject:sender];
            return YES;
        } else {
            responder = [responder nextResponder];
        }
    }
    return NO;
}

BOOL _UIApplicationFirstResponderCanPerformAction(UIApplication *application, SEL action, id sender, UIScreen *theScreen)
{
    return [_UIApplicationFirstResponderForScreen(application, theScreen) canPerformAction:action withSender:sender];
}

// this is used to cause an interruption/cancel of the current touches.
// Use this when a modal UI element appears (such as a native popup menu), or when a UIPopoverController appears. It seems to make the most sense
// to call _cancelTouches *after* the modal menu has been dismissed, as this causes UI elements to remain in their "pushed" state while the menu
// is being displayed. If that behavior isn't desired, the simple solution is to present the menu from touchesEnded: instead of touchesBegan:.
void _UIApplicationCancelTouches(UIApplication *application)
{
    UIEvent *currentEvent = application->_currentEvent;
    UITouch *touch = [[currentEvent allTouches] anyObject];
    const BOOL wasActiveTouch = TouchIsActive(touch);
    touch->_phase = UITouchPhaseCancelled;    
    if (wasActiveTouch) {
        _UIApplicationSendEvent(currentEvent);
    }
}

// this sets the touches view property to nil (while retaining the window property setting)
// this is used when a view is removed from its superview while it may have been the origin
// of an active touch. after a view is removed, we don't want to deliver any more touch events
// to it, but we still may need to route the touch itself for the sake of gesture recognizers
// so we need to retain the touch's original window setting so that events can still be routed.
//
// note that the touch itself is not being cancelled here so its phase remains unchanged.
// I'm not entirely certain if that's the correct thing to do, but I think it makes sense. The
// touch itself has not gone anywhere - just the view that it first touched. That breaks the
// delivery of the touch events themselves as far as the usual responder chain delivery is
// concerned, but that appears to be what happens in the real UIKit when you remove a view out
// from under an active touch.
//
// this whole thing is necessary because otherwise a gesture which may have been initiated over
// some specific view would end up getting cancelled/failing if the view under it happens to be
// removed. this is more common than you might expect. a UITableView that is not reusing rows
// does exactly this as it scrolls - which coincidentally is how I found this bug in the first
// place. :P
void _UIApplicationRemoveViewFromTouches(UIApplication *application, UIView *aView)
{
    for (UITouch *touch in [application->_currentEvent allTouches]) {
        if (touch.view == aView) {
            _UITouchRemoveFromView(touch);
        }
    }
}
