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

#import <UIKit/UIResponder.h>
#import <UIKit/UIWindow-private.h>
#import <UIKit/UIInputController.h>

UIWindow* _UIResponderGetResponderWindow(UIResponder *responder);

@implementation UIResponder

#pragma mark - Accessors

- (UIResponder *)nextResponder
{
    return nil;
}

- (UIView *)inputAccessoryView
{
    return nil;
}

- (UIView *)inputView
{
    return nil;
}

- (NSUndoManager *)undoManager
{
    return [[self nextResponder] undoManager];
}

#pragma mark - Overridden methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //DLog(@"self: %@", self);
    [[self nextResponder] touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    //DLog(@"self: %@", self);
    [[self nextResponder] touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //DLog(@"self: %@", self);
    [[self nextResponder] touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[self nextResponder] touchesCancelled:touches withEvent:event];
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
}

- (void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
}

#pragma mark - Public methods

- (BOOL)isFirstResponder
{
    UIWindow* window = _UIResponderGetResponderWindow(self);
    if (window) {
        return (window->_firstResponder == self);
    }
    else {
        return NO;
    }
}

- (BOOL)canBecomeFirstResponder
{
    return NO;
}

- (BOOL)becomeFirstResponder
{
    if ([self isFirstResponder]) {
        return YES;
    } else {
        UIWindow *window = _UIResponderGetResponderWindow(self);
        UIResponder *firstResponder = window->_firstResponder;
        
        if (window && [self canBecomeFirstResponder]) {
            BOOL didResign = NO;
            
            if (firstResponder && [firstResponder canResignFirstResponder]) {
                didResign = [firstResponder resignFirstResponder];
            } else {
                didResign = YES;
            }
            if (didResign) {
                [window makeKeyWindow];		// not sure about this :/
                window->_firstResponder = self;
                
                // I have no idea how iOS manages this stuff, but here I'm modeling UIMenuController since it also uses the first
                // responder to do its work. My thinking is that if there were an on-screen keyboard, something here could detect
                // if self conforms to UITextInputTraits and UIKeyInput and/or UITextInput and then build/fetch the correct keyboard
                // and assign that to the inputView property which would seperate the keyboard and inputs themselves from the stuff
                // that actually displays them on screen. Of course on the Mac we don't need an on-screen keyboard, but there's
                // possibly an argument to be made for supporting custom inputViews anyway.
                UIInputController *controller = [UIInputController sharedInputController];
                controller.inputAccessoryView = self.inputAccessoryView;
                controller.inputView = self.inputView;
                [controller setInputVisible:YES animated:YES];
                return YES;
            }
        }
        return NO;
    }
}

- (BOOL)canResignFirstResponder
{
    return YES;
}

- (BOOL)resignFirstResponder
{
    if ([self isFirstResponder]) {
        UIWindow* window = _UIResponderGetResponderWindow(self);
        window->_firstResponder = nil;
        [[UIInputController sharedInputController] setInputVisible:NO animated:YES];
    }
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if ([isa instancesRespondToSelector:action]) {
        return YES;
    } else {
        return [[self nextResponder] canPerformAction:action withSender:sender];
    }
}

@end

#pragma mark - Shared functions

UIWindow* _UIResponderGetResponderWindow(UIResponder* responder)
{
    if ([responder isKindOfClass:[UIView class]]) {
        return [(UIView *)responder window];
    } else {
        return _UIResponderGetResponderWindow([responder nextResponder]);
    }
}

