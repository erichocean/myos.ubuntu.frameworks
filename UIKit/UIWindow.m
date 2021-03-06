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
#import <UIKit/UIScreenMode.h>
#import <UIKit/UIViewController.h>
//#import <UIKit/UIGestureRecognizerSubclass.h>

const UIWindowLevel UIWindowLevelNormal = 0;
const UIWindowLevel UIWindowLevelStatusBar = 1000;
const UIWindowLevel UIWindowLevelAlert = 2000;

NSString *const UIWindowDidBecomeVisibleNotification = @"UIWindowDidBecomeVisibleNotification";
NSString *const UIWindowDidBecomeHiddenNotification = @"UIWindowDidBecomeHiddenNotification";
NSString *const UIWindowDidBecomeKeyNotification = @"UIWindowDidBecomeKeyNotification";
NSString *const UIWindowDidResignKeyNotification = @"UIWindowDidResignKeyNotification";

NSString *const UIKeyboardWillShowNotification = @"UIKeyboardWillShowNotification";
NSString *const UIKeyboardDidShowNotification = @"UIKeyboardDidShowNotification";
NSString *const UIKeyboardWillHideNotification = @"UIKeyboardWillHideNotification";
NSString *const UIKeyboardDidHideNotification = @"UIKeyboardDidHideNotification";

NSString *const UIKeyboardFrameBeginUserInfoKey = @"UIKeyboardFrameBeginUserInfoKey";
NSString *const UIKeyboardFrameEndUserInfoKey = @"UIKeyboardFrameEndUserInfoKey";
NSString *const UIKeyboardAnimationDurationUserInfoKey = @"UIKeyboardAnimationDurationUserInfoKey";
NSString *const UIKeyboardAnimationCurveUserInfoKey = @"UIKeyboardAnimationCurveUserInfoKey";

// deprecated

NSString *const UIKeyboardCenterBeginUserInfoKey = @"UIKeyboardCenterBeginUserInfoKey";
NSString *const UIKeyboardCenterEndUserInfoKey = @"UIKeyboardCenterEndUserInfoKey";
NSString *const UIKeyboardBoundsUserInfoKey = @"UIKeyboardBoundsUserInfoKey";

// Private

NSString *const _CARootLayersModifiedNotification = @"CARootLayersModifiedNotification";

@implementation UIWindow
@synthesize screen=_screen, rootViewController=_rootViewController;

#pragma mark - Life cycle

- (id)initWithFrame:(CGRect)theFrame
{
    if ((self=[super initWithFrame:theFrame])) {
        _undoManager = [[NSUndoManager alloc] init];
        //[self _makeHidden];	// do this first because before the screen is set, it will prevent any visibility notifications from being sent.
        self.screen = [UIScreen mainScreen];
        self.opaque = NO;
        _firstResponder = nil;
//        NSMutableArray *rootLayers = _CALayerGetRootLayers();
//        [rootLayers addObject:_layer];
//        DLog(@"rootLayers: %@", rootLayers);
        [[NSNotificationCenter defaultCenter] postNotificationName:_CARootLayersModifiedNotification object:self];
         /*
         addObserver:self
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];*/
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self _makeHidden];	// I don't really like this here, but the real UIKit seems to do something like this on window destruction as it sends a notification and we also need to remove it from the app's list of windows
    [_screen release];
    [_undoManager release];
    [_rootViewController release];
    [super dealloc];
}

#pragma mark - Accessors

- (UIView *)superview
{
    return nil;		// lies!
}

- (UIWindow *)window
{
    return self;
}

- (NSUndoManager *)undoManager
{
    return _undoManager;
}

- (void)setRootViewController:(UIViewController *)rootViewController
{
    if (rootViewController != _rootViewController) {
        [_subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [_rootViewController release];
        _rootViewController = [rootViewController retain];
        _rootViewController.view.frame = _layer.bounds;    // unsure about this
        [self addSubview:_rootViewController.view];
    }
}

- (void)setScreen:(UIScreen *)theScreen
{
    if (theScreen != _screen) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenModeDidChangeNotification object:_screen];
        const BOOL wasHidden = _layer.hidden;
        //[self _makeHidden];

        //[_layer removeFromSuperlayer];
        [_screen release];
        _screen = [theScreen retain];
        //[_screen->_layer addSublayer:_layer];

        if (!wasHidden) {
            [self _makeVisible];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_screenModeChangedNotification:) name:UIScreenModeDidChangeNotification object:_screen];
    }
}

- (void)setWindowLevel:(UIWindowLevel)level
{
    _layer.zPosition = level;
}

- (UIWindowLevel)windowLevel
{
    return _layer.zPosition;
}

#pragma mark - Notifications

- (void) _screenModeChangedNotification:(NSNotification *)notification
{
    UIScreenMode *previousMode = [[notification userInfo] objectForKey:@"_previousMode"];
    UIScreenMode *newMode = _screen->_currentMode;
    if (!CGSizeEqualToSize(previousMode->_size,newMode->_size)) {
        _UIViewSuperviewSizeDidChange((UIView*)self, previousMode->_size, newMode->_size);
    }
}

#pragma mark - Public methods

- (void)removeFromSuperview
{
    // does nothing
}

- (UIResponder *)nextResponder
{
    return [UIApplication sharedApplication];
}

- (CGPoint)convertPoint:(CGPoint)toConvert toWindow:(UIWindow *)toWindow
{
    if (toWindow == self) {
        return toConvert;
    } 
    else {
        // Convert to screen coordinates
        toConvert.x += _layer.frame.origin.x;
        toConvert.y += _layer.frame.origin.y;    
        if (toWindow) {
            // Now convert the screen coords into the other screen's coordinate space
            toConvert = [_screen convertPoint:toConvert toScreen:toWindow.screen];

            // And now convert it from the new screen's space into the window's space
            toConvert.x -= toWindow.frame.origin.x;
            toConvert.y -= toWindow.frame.origin.y;
        }
        return toConvert;
    }
}

- (CGPoint)convertPoint:(CGPoint)toConvert fromWindow:(UIWindow *)fromWindow
{
    if (fromWindow == self) {
        return toConvert;
    } 
    else {
        if (fromWindow) {
            // Convert to screen coordinates
            toConvert.x += fromWindow.frame.origin.x;
            toConvert.y += fromWindow.frame.origin.y;
            // Change to this screen.
            toConvert = [_screen convertPoint:toConvert fromScreen:fromWindow.screen];
        }    
        // Convert to window coordinates
        toConvert.x -= _layer.frame.origin.x;
        toConvert.y -= _layer.frame.origin.y;
        return toConvert;
    }
}

- (CGRect)convertRect:(CGRect)toConvert fromWindow:(UIWindow *)fromWindow
{
    CGPoint convertedOrigin = [self convertPoint:toConvert.origin fromWindow:fromWindow];
    return CGRectMake(convertedOrigin.x, convertedOrigin.y, toConvert.size.width, toConvert.size.height);
}

- (CGRect)convertRect:(CGRect)toConvert toWindow:(UIWindow *)toWindow
{
    CGPoint convertedOrigin = [self convertPoint:toConvert.origin toWindow:toWindow];
    return CGRectMake(convertedOrigin.x, convertedOrigin.y, toConvert.size.width, toConvert.size.height);
}

- (void)becomeKeyWindow
{
    if ([_firstResponder respondsToSelector:@selector(becomeKeyWindow)]) {
        [(id) _firstResponder becomeKeyWindow];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:UIWindowDidBecomeKeyNotification object:self];
}

- (void)makeKeyWindow
{
    if (!self.isKeyWindow) {
        [[UIApplication sharedApplication].keyWindow resignKeyWindow];
        _UIApplicationSetKeyWindow([UIApplication sharedApplication], self);
        [self becomeKeyWindow];
    }
}

- (BOOL)isKeyWindow
{
    return ([UIApplication sharedApplication].keyWindow == self);
}

- (void)resignKeyWindow
{
    if ([_firstResponder respondsToSelector:@selector(resignKeyWindow)]) {
        [(id) _firstResponder resignKeyWindow];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:UIWindowDidResignKeyNotification object:self];
}

- (void)setHidden:(BOOL)hide
{
    if (hide) {
        [self _makeHidden];
    } 
    else {
        [self _makeVisible];
    }
}

- (void) _makeHidden
{
    if (!self.hidden) {
        [super setHidden:YES];
        if (self.screen) {
            _UIApplicationWindowDidBecomeHidden([UIApplication sharedApplication], self);
            [[NSNotificationCenter defaultCenter] postNotificationName:UIWindowDidBecomeHiddenNotification object:self];
        }
    }
}

- (void) _makeVisible
{
    if (self.hidden) {
        [super setHidden:NO];
        if (self.screen) {
            _UIApplicationWindowDidBecomeVisible([UIApplication sharedApplication], self);
            [[NSNotificationCenter defaultCenter] postNotificationName:UIWindowDidBecomeVisibleNotification object:self];
        }
    }
}

- (void)makeKeyAndVisible
{
    [self _makeVisible];
    [self makeKeyWindow];
}

- (void)sendEvent:(UIEvent *)event
{
    if (event.type == UIEventTypeTouches) {
        NSSet *touches = [event touchesForWindow:self];
        NSMutableSet *gestureRecognizers = [NSMutableSet setWithCapacity:1];
        for (UITouch *touch in touches) {
            //DLog(@"touch: %@", touch);
            //DLog(@"touch->_gestureRecognizers: %@", touch->_gestureRecognizers);
            [gestureRecognizers addObjectsFromArray:touch->_gestureRecognizers];
        }
        //DLog();
        for (UIGestureRecognizer *recognizer in gestureRecognizers) {
            //DLog(@"recognizer: %@", recognizer);
            _UIGestureRecognizerRecognizeTouches(recognizer, touches, event);
        }
        for (UITouch *touch in touches) {
            // normally there'd be no need to retain the view here, but this works around a strange problem I ran into.
            // what can happen is, now that UIView's -removeFromSuperview will remove the view from the active touch
            // instead of just cancel the touch (which is how I had implemented it previously - which was wrong), the
            // situation can arise where, in response to a touch event of some kind, the view may remove itself from its
            // superview in some fashion, which means that the handling of the touchesEnded:withEvent: (or whatever)
            // methods could somehow result in the view itself being destroyed before the method is even finished running!
            // I ran into this in particular with a load more button in Twitterrific which would crash in UIControl's
            // touchesEnded: implemention after sending actions to the registered targets (because one of those targets
            // ended up removing the button from view and thus reducing its retain count to 0). For some reason, even
            // though I attempted to rearrange stuff in UIControl so that actions were always the last thing done, it'd
            // still end up crashing when one of the internal methods returned to touchesEnded:, which didn't make sense
            // to me because there was no code after that (at the time) and therefore it should just have been unwinding
            // the stack to eventually get back here and all should have been okay. I never figured out exactly why that
            // crashed in that way, but by putting a retain here it works around this problem and perhaps others that have
            // gone so-far unnoticed. Converting to ARC should also work with this solution because there will be a local
            // strong reference to the view retainined throughout the rest of this logic and thus the same protection
            // against mid-method view destrustion should be provided under ARC. If someone can figure out some other,
            // better way to fix this without it having to have this hacky-feeling retain here, that'd be cool, but be
            // aware that this is here for a reason and that the problem it prevents is very rare and somewhat contrived.
            UIView *view = [touch.view retain];

            //DLog(@"view: %@", view);
            const UITouchPhase phase = touch.phase;
            
            if (phase == UITouchPhaseBegan) {
                [view touchesBegan:touches withEvent:event];
            } else if (phase == UITouchPhaseMoved) {
                [view touchesMoved:touches withEvent:event];
            } else if (phase == UITouchPhaseEnded) {
                [view touchesEnded:touches withEvent:event];
            } else if (phase == UITouchPhaseCancelled) {
                [view touchesCancelled:touches withEvent:event];
            }
            [view release];
        }
    }
}

@end
