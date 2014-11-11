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
#import <CoreAnimation/CoreAnimation-private.h>

static const UIEdgeInsets kButtonEdgeInsets = {0,0,0,0};
static const CGFloat kMinButtonWidth = 30;
static const CGFloat kMaxButtonWidth = 200;
static const CGFloat kMaxButtonHeight = 24;

static const NSTimeInterval kAnimationDuration = 0.33;

typedef enum {
    _UINavigationBarTransitionPush,
    _UINavigationBarTransitionPop,
    _UINavigationBarTransitionReload		// explicitly tag reloads from changed UINavigationItem data
} _UINavigationBarTransition;

#pragma mark - Static functions

static void _UINavigationBarSetBarButtonSize(UIView *view)
{
    CGRect frame = view.frame;
    frame.size = [view sizeThatFits:CGSizeMake(kMaxButtonWidth,kMaxButtonHeight)];
    frame.size.height = kMaxButtonHeight;
    frame.size.width = MAX(frame.size.width,kMinButtonWidth);
    view.frame = frame;
}

static UIButton *_UINavigationGetBarBackButtonWithBarButtonItem(UIBarButtonItem *item)
{
    if (!item) {
        return nil;
    }
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setBackgroundImage:_UIImageBackButtonImage() forState:UIControlStateNormal];
    [backButton setBackgroundImage:_UIImageHighlightedBackButtonImage() forState:UIControlStateHighlighted];
    [backButton setTitle:item.title forState:UIControlStateNormal];
    backButton.titleLabel.font = [UIFont systemFontOfSize:11];
    backButton.contentEdgeInsets = UIEdgeInsetsMake(0,15,0,7);
    [backButton addTarget:nil action:@selector(_backButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    _UINavigationBarSetBarButtonSize(backButton);
    return backButton;
}

static UIView *_UINavigationBarGetViewWithBarButtonItem(UIBarButtonItem *item)
{
    if (!item) return nil;
    
    if (item.customView) {
        _UINavigationBarSetBarButtonSize(item.customView);
        return item.customView;
    } else {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setBackgroundImage:_UIImageToolbarButtonImage() forState:UIControlStateNormal];
        [button setBackgroundImage:_UIImageHighlightedToolbarButtonImage() forState:UIControlStateHighlighted];
        [button setTitle:item.title forState:UIControlStateNormal];
        [button setImage:item.image forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:11];
        button.contentEdgeInsets = UIEdgeInsetsMake(0,7,0,7);
        [button addTarget:item.target action:item.action forControlEvents:UIControlEventTouchUpInside];
        _UINavigationBarSetBarButtonSize(button);
        return button;
    }
}

static void _UINavigationBarSetViewsWithTransition(UINavigationBar *navigationBar, _UINavigationBarTransition transition, BOOL animated)
{
    CGRect bounds = navigationBar->_layer->_bounds;
    {
        NSMutableArray *previousViews = [[NSMutableArray alloc] init];
        
        if (navigationBar->_leftView) [previousViews addObject:navigationBar->_leftView];
        if (navigationBar->_centerView) [previousViews addObject:navigationBar->_centerView];
        if (navigationBar->_rightView) [previousViews addObject:navigationBar->_rightView];
        
        if (animated) {
            CGFloat moveCenterBy = bounds.size.width - navigationBar->_centerView.frame.origin.x;
            CGFloat moveLeftBy = bounds.size.width * 0.33f;
            
            if (transition == _UINavigationBarTransitionPush) {
                moveCenterBy *= -1.f;
                moveLeftBy *= -1.f;
            }
            
            [UIView animateWithDuration:kAnimationDuration
                             animations:^(void) {
                                 navigationBar->_leftView.frame = CGRectOffset(navigationBar->_leftView.frame, moveLeftBy, 0);
                                 navigationBar->_centerView.frame = CGRectOffset(navigationBar->_centerView.frame, moveCenterBy, 0);
                             }];
            
            [UIView animateWithDuration:kAnimationDuration * 0.8
                                  delay:kAnimationDuration * 0.2
                                options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                             animations:^(void) {
                                 navigationBar->_leftView.alpha = 0;
                                 navigationBar->_rightView.alpha = 0;
                                 navigationBar->_centerView.alpha = 0;
                             }
                             completion:NULL];
            
            [navigationBar performSelector:@selector(_removeAnimatedViews:) withObject:previousViews afterDelay:kAnimationDuration];
        } else {
            [navigationBar _removeAnimatedViews:previousViews];
        }
        
        [previousViews release];
    }
    
    UINavigationItem *topItem = navigationBar.topItem;
    
    if (topItem) {
        UINavigationItem *backItem = navigationBar.backItem;
        
        // update weak references
        _UINavigationItemSetNavigationBar(backItem, nil);
        _UINavigationItemSetNavigationBar(topItem, navigationBar);
        
        CGRect leftFrame = CGRectZero;
        CGRect rightFrame = CGRectZero;
        
        if (backItem) {
            navigationBar->_leftView = _UINavigationGetBarBackButtonWithBarButtonItem(backItem.backBarButtonItem);
        } else {
            navigationBar->_leftView = _UINavigationBarGetViewWithBarButtonItem(topItem.leftBarButtonItem);
        }
        
        if (navigationBar->_leftView) {
            leftFrame = navigationBar->_leftView.frame;
            leftFrame.origin = CGPointMake(kButtonEdgeInsets.left, kButtonEdgeInsets.top);
            navigationBar->_leftView.frame = leftFrame;
            [navigationBar addSubview:navigationBar->_leftView];
        }
        
        navigationBar->_rightView = _UINavigationBarGetViewWithBarButtonItem(topItem.rightBarButtonItem);
        
        if (navigationBar->_rightView) {
            navigationBar->_rightView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            rightFrame = navigationBar->_rightView.frame;
            rightFrame.origin.x = bounds.size.width-rightFrame.size.width - kButtonEdgeInsets.right;
            rightFrame.origin.y = kButtonEdgeInsets.top;
            navigationBar->_rightView.frame = rightFrame;
            [navigationBar addSubview:navigationBar->_rightView];
        }
        
        navigationBar->_centerView = topItem.titleView;
        
        if (!navigationBar->_centerView) {
            UILabel *titleLabel = [[[UILabel alloc] init] autorelease];
            titleLabel.text = topItem.title;
            titleLabel.textAlignment = UITextAlignmentCenter;
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.textColor = [UIColor whiteColor];
            titleLabel.font = [UIFont boldSystemFontOfSize:14];
            navigationBar->_centerView = titleLabel;
        }
        
        const CGFloat centerPadding = MAX(leftFrame.size.width, rightFrame.size.width);
        navigationBar->_centerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        navigationBar->_centerView.frame = CGRectMake(kButtonEdgeInsets.left+centerPadding,kButtonEdgeInsets.top,bounds.size.width-kButtonEdgeInsets.right-kButtonEdgeInsets.left-centerPadding-centerPadding,kMaxButtonHeight);
        [navigationBar addSubview:navigationBar->_centerView];
        
        if (animated) {
            CGFloat moveCenterBy = bounds.size.width - navigationBar->_centerView.frame.origin.x;
            CGFloat moveLeftBy = bounds.size.width * 0.33f;
            
            if (transition == _UINavigationBarTransitionPush) {
                moveLeftBy *= -1.f;
                moveCenterBy *= -1.f;
            }
            
            CGRect destinationLeftFrame = navigationBar->_leftView.frame;
            CGRect destinationCenterFrame = navigationBar->_centerView.frame;
            
            navigationBar->_leftView.frame = CGRectOffset(navigationBar->_leftView.frame, -moveLeftBy, 0);
            navigationBar->_centerView.frame = CGRectOffset(navigationBar->_centerView.frame, -moveCenterBy, 0);
            navigationBar->_leftView.alpha = 0;
            navigationBar->_rightView.alpha = 0;
            navigationBar->_centerView.alpha = 0;
            
            [UIView animateWithDuration:kAnimationDuration
                             animations:^(void) {
                                 navigationBar->_leftView.frame = destinationLeftFrame;
                                 navigationBar->_centerView.frame = destinationCenterFrame;
                             }];
            
            [UIView animateWithDuration:kAnimationDuration * 0.8
                                  delay:kAnimationDuration * 0.2
                                options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                             animations:^(void) {
                                 navigationBar->_leftView.alpha = 1;
                                 navigationBar->_rightView.alpha = 1;
                                 navigationBar->_centerView.alpha = 1;
                             }
                             completion:NULL];
        }
    } else {
        navigationBar->_leftView = navigationBar->_centerView = navigationBar->_rightView = nil;
    }
}

@implementation UINavigationBar

@synthesize tintColor=_tintColor, delegate=_delegate, items=_navStack;

- (id)initWithFrame:(CGRect)frame
{
    if ((self=[super initWithFrame:frame])) {
        _navStack = [[NSMutableArray alloc] init];
        self.tintColor = [UIColor colorWithRed:21/255.f green:21/255.f blue:25/255.f alpha:1];
    }
    return self;
}

- (void)dealloc
{
    _UINavigationItemSetNavigationBar(self.topItem, nil);
    [_navStack release];
    [_tintColor release];
    [super dealloc];
}

- (void)setDelegate:(id)newDelegate
{
    _delegate = newDelegate;
    _delegateHas.shouldPushItem = [_delegate respondsToSelector:@selector(navigationBar:shouldPushItem:)];
    _delegateHas.didPushItem = [_delegate respondsToSelector:@selector(navigationBar:didPushItem:)];
    _delegateHas.shouldPopItem = [_delegate respondsToSelector:@selector(navigationBar:shouldPopItem:)];
    _delegateHas.didPopItem = [_delegate respondsToSelector:@selector(navigationBar:didPopItem:)];
}

- (UINavigationItem *)topItem
{
    return [_navStack lastObject];
}

- (UINavigationItem *)backItem
{
    return ([_navStack count] <= 1)? nil : [_navStack objectAtIndex:[_navStack count]-2];
}

- (void)setTintColor:(UIColor *)newColor
{
    if (newColor != _tintColor) {
        [_tintColor release];
        _tintColor = [newColor retain];
        _CALayerSetNeedsDisplay(_layer);
        //[self setNeedsDisplay];
    }
}

- (void)setItems:(NSArray *)items animated:(BOOL)animated
{
    if (![_navStack isEqualToArray:items]) {
        [_navStack removeAllObjects];
        [_navStack addObjectsFromArray:items];
        _UINavigationBarSetViewsWithTransition(self, _UINavigationBarTransitionPush, animated);
    }
}

- (void)setItems:(NSArray *)items
{
    [self setItems:items animated:NO];
}

- (UIBarStyle)barStyle
{
    return UIBarStyleDefault;
}

- (void)setBarStyle:(UIBarStyle)barStyle
{
}

- (void)pushNavigationItem:(UINavigationItem *)item animated:(BOOL)animated
{
    BOOL shouldPush = YES;

    if (_delegateHas.shouldPushItem) {
        shouldPush = [_delegate navigationBar:self shouldPushItem:item];
    }

    if (shouldPush) {
        [_navStack addObject:item];
        _UINavigationBarSetViewsWithTransition(self, _UINavigationBarTransitionPush, animated);
        
        if (_delegateHas.didPushItem) {
            [_delegate navigationBar:self didPushItem:item];
        }
    }
}

- (UINavigationItem *)popNavigationItemAnimated:(BOOL)animated
{
    UINavigationItem *previousItem = self.topItem;
    
    if (previousItem) {
        BOOL shouldPop = YES;

        if (_delegateHas.shouldPopItem) {
            shouldPop = [_delegate navigationBar:self shouldPopItem:previousItem];
        }
        
        if (shouldPop) {
            [previousItem retain];
            [_navStack removeObject:previousItem];
            _UINavigationBarSetViewsWithTransition(self, _UINavigationBarTransitionPop, animated);
            
            if (_delegateHas.didPopItem) {
                [_delegate navigationBar:self didPopItem:previousItem];
            }
            
            return [previousItem autorelease];
        }
    }
    
    return nil;
}

#pragma mark - Overridden methods

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (_navigationBarFlags.reloadItem) {
        _navigationBarFlags.reloadItem = 0;
        _UINavigationBarSetViewsWithTransition(self, _UINavigationBarTransitionReload, NO);
    }
}

- (void)drawRect:(CGRect)rect
{
    const CGRect bounds = self.bounds;
    
    // I kind of suspect that the "right" thing to do is to draw the background and then paint over it with the tintColor doing some kind of blending
    // so that it actually doesn "tint" the image instead of define it. That'd probably work better with the bottom line coloring and stuff, too, but
    // for now hardcoding stuff works well enough.
    
    [_tintColor setFill];
    UIRectFill(bounds);
}

#pragma mark - Delegates

- (void)_removeAnimatedViews:(NSArray *)views
{
    [views makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)_backButtonTapped:(id)sender
{
    [self popNavigationItemAnimated:YES];
}

@end

#pragma mark - Shared functions

void _UINavigationBarUpdateNavigationItem(UINavigationBar *navigationBar, UINavigationItem *item, BOOL animated) // ignored for now
{
    // let's sanity-check that the item is supposed to be talking to us
    if (item != navigationBar.topItem) {
        _UINavigationItemSetNavigationBar(item, nil);
        return;
    }
    
    // this is going to remove & re-add all the item views. Not ideal, but simple enough that it's worth profiling.
    // next step is to add animation support-- that will require changing _setViewsWithTransition:animated:
    //  such that it won't perform any coordinate translations, only fade in/out
    
    // don't just fire the damned thing-- set a flag & mark as needing layout
    if (navigationBar->_navigationBarFlags.reloadItem == 0) {
        navigationBar->_navigationBarFlags.reloadItem = 1;
        [navigationBar setNeedsLayout];
    }
}
