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
#import <CoreGraphics/CoreGraphics-private.h>

static const NSTimeInterval UIScrollViewAnimationDuration = 0.33;
static const NSTimeInterval UIScrollViewQuickAnimationDuration = 0.22;
static const NSUInteger UIScrollViewScrollAnimationFramesPerSecond = 60;
static const float _UIScrollViewBounceRatio = 0.30;

const float UIScrollViewDecelerationRateNormal = 0.998;
const float UIScrollViewDecelerationRateFast = 0.99;

#pragma mark - Static functions

static BOOL _UIScrollViewCanScrollHorizontal(UIScrollView *scrollView)
{
    return scrollView.scrollEnabled && (scrollView->_contentSize.width > scrollView.bounds.size.width);
}

static BOOL _UIScrollViewCanScrollVertical(UIScrollView *scrollView)
{
    return scrollView.scrollEnabled && (scrollView->_contentSize.height > scrollView.bounds.size.height);
}

CGPoint _UIScrollViewConfinedDelta(UIScrollView *scrollView, CGPoint delta, BOOL animated)
{
    CGRect bounds = scrollView.bounds;
    //DLog(@"delta: %@", NSStringFromCGPoint(delta));
    CGPoint proposedOffset = CGPointMake(scrollView->_contentOffset.x - delta.x, scrollView->_contentOffset.y - delta.y);
    CGPoint visibleBottomCorner = CGPointMake(scrollView->_contentOffset.x + bounds.size.width, scrollView->_contentOffset.y + bounds.size.height);
    CGPoint proposedBottomCorner = CGPointMake(proposedOffset.x + bounds.size.width, proposedOffset.y + bounds.size.height);
    CGRect contentBounds = CGRectMake(0,0,scrollView->_contentSize.width, scrollView->_contentSize.height);
    if (CGRectContainsPoint(contentBounds, proposedOffset) &&  CGRectContainsPoint(contentBounds, proposedBottomCorner) &&
        !scrollView->_pagingEnabled) {
        return delta;
    }
    CGPoint resultOrigin = proposedOffset;
    BOOL canScrollHorizontal = _UIScrollViewCanScrollHorizontal(scrollView);
    BOOL canScrollVertical = _UIScrollViewCanScrollVertical(scrollView);
    if (resultOrigin.x < 0) {
        //DLog(@"resultOrigin.x < 0");
        if (scrollView->_bounces && canScrollHorizontal && !animated) {
            //DLog(@"scrollView->_bounces && canScrollHorizontal");
            //DLog(@"bounds: %@", NSStringFromCGRect(bounds));
            if (fabs(resultOrigin.x) < bounds.size.width * _UIScrollViewBounceRatio) {
                //DLog(@"fabs(resultOrigin.x) < bounds.size.width");
                resultOrigin.x = scrollView->_contentOffset.x - (delta.x * _UIScrollViewBounceRatio);
            } else {
                //DLog(@"fabs(resultOrigin.x) < bounds.size.width else");
                resultOrigin.x = -bounds.size.width * _UIScrollViewBounceRatio;
            }
        } else {
            //DLog(@"scrollView->_bounces && canScrollHorizontal");
            resultOrigin.x = 0;
        }
    } else if (resultOrigin.x > 0 && !canScrollHorizontal) {
        resultOrigin.x = 0;
    }
    if (resultOrigin.y < 0) {
        //DLog(@"resultOrigin.y < 0");
        if (scrollView->_bounces && canScrollVertical && !animated) {
            if (fabs(resultOrigin.y) < bounds.size.height * _UIScrollViewBounceRatio) {
                resultOrigin.y = scrollView->_contentOffset.y - (delta.y * _UIScrollViewBounceRatio);
                //resultOrigin.y = resultOrigin.y * _UIScrollViewBounceRatio;
            } else {
                //resultOrigin.y = -bounds.size.height * _UIScrollViewBounceRatio;
                resultOrigin.y = -bounds.size.height * _UIScrollViewBounceRatio;
            }
        } else {
            resultOrigin.y = 0;
        }
    } else if (resultOrigin.y > 0 && !canScrollVertical) {
        resultOrigin.y = 0;
    }
    CGPoint resultBottomCorner = proposedBottomCorner;
    if (proposedBottomCorner.x > scrollView->_contentSize.width) {
        //DLog(@"proposedBottomCorner.x > scrollView->_contentSize.width");
        if (scrollView->_bounces && canScrollHorizontal && !animated) {
            if (resultBottomCorner.x - scrollView->_contentSize.width < bounds.size.width * _UIScrollViewBounceRatio) {
                //DLog(@"resultBottomCorner.x - scrollView->_contentSize.width < bounds.size.width * _UIScrollViewBounceRatio");
                resultBottomCorner.x = visibleBottomCorner.x - (delta.x * _UIScrollViewBounceRatio);
            } else {
                //DLog(@"resultBottomCorner.x - scrollView->_contentSize.width < bounds.size.width * _UIScrollViewBounceRatio else");
                resultBottomCorner.x = scrollView->_contentSize.width + bounds.size.width * _UIScrollViewBounceRatio;
            }
        } else {
            resultBottomCorner.x = scrollView->_contentSize.width;
        }
        resultOrigin = CGPointMake(resultBottomCorner.x - bounds.size.width, resultOrigin.y);
    }
    if (proposedBottomCorner.y > scrollView->_contentSize.height) {
        //DLog(@"proposedBottomCorner.y > scrollView->_contentSize.height");
        if (scrollView->_bounces && canScrollVertical && !animated) {
            if (resultBottomCorner.y - scrollView->_contentSize.height < bounds.size.height * _UIScrollViewBounceRatio) {
                resultBottomCorner.y = visibleBottomCorner.y - (delta.y * _UIScrollViewBounceRatio);
            } else {
                resultBottomCorner.y = scrollView->_contentSize.height + bounds.size.height * _UIScrollViewBounceRatio;
            }
        } else {
            resultBottomCorner.y = scrollView->_contentSize.height;
        }
        resultOrigin = CGPointMake(resultOrigin.x, resultBottomCorner.y - bounds.size.height);
    }
    //DLog(@"scrollView->_contentOffset: %@", NSStringFromCGPoint(scrollView->_contentOffset));
    //DLog(@"resultOrigin: %@", NSStringFromCGPoint(resultOrigin));
    
    if (scrollView->_pagingEnabled && animated) {
        if (canScrollHorizontal) {
            resultOrigin.x = roundf(resultOrigin.x / bounds.size.width) * bounds.size.width;
        }
        if (canScrollVertical) {
            resultOrigin.y = roundf(resultOrigin.y / bounds.size.height) * bounds.size.height;
        }
        //DLog(@"resultOrigin: %@", NSStringFromCGPoint(resultOrigin));
    }
    CGPoint result = CGPointMake(scrollView->_contentOffset.x - resultOrigin.x , scrollView->_contentOffset.y - resultOrigin.y);
    //DLog(@"result: %@", NSStringFromCGPoint(result));
    return result;
}

static void _UIScrollViewScrollContent(UIScrollView *scrollView, CGPoint delta, BOOL animated)
{
    //DLog(@"delta: %@", NSStringFromCGPoint(delta));
    CFTimeInterval duration = (CFTimeInterval)[(NSNumber *)[CATransaction valueForKey:kCATransactionAnimationDuration] doubleValue];
    scrollView->_contentOffset = CGPointMake(scrollView->_contentOffset.x - delta.x, scrollView->_contentOffset.y - delta.y);
    if (animated) {
        //DLog(@"animated");
        [UIView beginAnimations:@"scrollContent" context:nil];
        [UIView setAnimationDuration:duration];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDelegate:scrollView];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:)];
    }
    for (UIView *subview in scrollView->_subviews) {
        //DLog(@"subview: %@", subview);
        subview.center = CGPointMake(subview.center.x + delta.x, subview.center.y + delta.y);
    }
    if (animated) {
        [UIView commitAnimations];
    }
}

static void _UIScrollViewCancelScrollAnimation(UIScrollView *scrollView)
{
    [scrollView->_scrollTimer invalidate];
    scrollView->_scrollTimer = nil;
    [scrollView->_scrollAnimation release];
    scrollView->_scrollAnimation = nil;
    if (scrollView->_delegateCan.scrollViewDidEndScrollingAnimation) {
        [scrollView->_delegate scrollViewDidEndScrollingAnimation:scrollView];
    }
    if (scrollView->_decelerating) {
        scrollView->_horizontalScroller.alwaysVisible = NO;
        scrollView->_verticalScroller.alwaysVisible = NO;
        scrollView->_decelerating = NO;
        if (scrollView->_delegateCan.scrollViewDidEndDecelerating) {
            [scrollView->_delegate scrollViewDidEndDecelerating:scrollView];
        }
    }
}

static void _UIScrollViewSetScrollAnimation(UIScrollView *scrollView, UIScrollViewAnimation *animation)
{
    _UIScrollViewCancelScrollAnimation(scrollView);
    scrollView->_scrollAnimation = [animation retain];
    
    if (!scrollView->_scrollTimer) {
        scrollView->_scrollTimer = [NSTimer scheduledTimerWithTimeInterval:1 / (NSTimeInterval)UIScrollViewScrollAnimationFramesPerSecond
                                                                    target:scrollView
                                                                  selector:@selector(_updateScrollAnimation)
                                                                  userInfo:nil
                                                                   repeats:YES];
    }
}

static UIView *_UIScrollViewZoomingView(UIScrollView *scrollView)
{
    return (scrollView->_delegateCan.viewForZoomingInScrollView)? [scrollView->_delegate viewForZoomingInScrollView:scrollView] : nil;
}

static void _UIScrollViewUpdateContentLayout(UIScrollView *scrollView)
{
    //DLog();
    scrollView->_verticalScroller.contentSize = scrollView->_contentSize.height;
    scrollView->_verticalScroller.contentOffset = scrollView->_contentOffset.y;
    scrollView->_horizontalScroller.contentSize = scrollView->_contentSize.width;
    scrollView->_horizontalScroller.contentOffset = scrollView->_contentOffset.x;
    scrollView->_verticalScroller.hidden = !_UIScrollViewCanScrollVertical(scrollView);
    scrollView->_horizontalScroller.hidden = !_UIScrollViewCanScrollHorizontal(scrollView);
    CGRect bounds = scrollView.bounds;
    //DLog(@"bounds: %@", NSStringFromCGRect(bounds));
    scrollView->_contentOffset.x = scrollView->_contentOffset.x + scrollView->_contentInset.left;
    scrollView->_contentOffset.y = scrollView->_contentOffset.y + scrollView->_contentInset.top;
    //DLog(@"bounds2: %@", NSStringFromCGRect(bounds));
    [scrollView setNeedsLayout];
}

static void _UIScrollViewConfineContent(UIScrollView *scrollView)
{
    scrollView.contentOffset = _UIScrollViewConfinedContentOffset(scrollView, scrollView->_contentOffset);
}

static void _UIScrollViewQuickFlashScrollIndicators(UIScrollView *scrollView)
{
    [scrollView->_horizontalScroller quickFlash];
    [scrollView->_verticalScroller quickFlash];
}

static UIScrollViewAnimation *_UIScrollViewPageSnapAnimation(UIScrollView *scrollView)
{
    const CGSize pageSize = scrollView.bounds.size;
    const CGSize numberOfWholePages = CGSizeMake(floorf(scrollView->_contentSize.width/pageSize.width), floorf(scrollView->_contentSize.height/pageSize.height));
    const CGSize currentRawPage = CGSizeMake(scrollView->_contentOffset.x/pageSize.width, scrollView->_contentOffset.y/pageSize.height);
    const CGSize currentPage = CGSizeMake(floorf(currentRawPage.width), floorf(currentRawPage.height));
    const CGSize currentPagePercentage = CGSizeMake(1-(currentRawPage.width-currentPage.width), 1-(currentRawPage.height-currentPage.height));
    CGPoint finalContentOffset = CGPointZero;
    // if currentPagePercentage is less than 50%, then go to the next page (if any), otherwise snap to the current page
    
    if (currentPagePercentage.width < 0.5 && (currentPage.width+1) < numberOfWholePages.width) {
        finalContentOffset.x = pageSize.width * (currentPage.width + 1);
    } else {
        finalContentOffset.x = pageSize.width * currentPage.width;
    }
    if (currentPagePercentage.height < 0.5 && (currentPage.height+1) < numberOfWholePages.height) {
        finalContentOffset.y = pageSize.height * (currentPage.height + 1);
    } else {
        finalContentOffset.y = pageSize.height * currentPage.height;
    }
    // quickly animate the snap (if necessary)
    if (!CGPointEqualToPoint(finalContentOffset, scrollView->_contentOffset)) {
        return [[[UIScrollViewAnimationScroll alloc] initWithScrollView:scrollView
                                                      fromContentOffset:scrollView->_contentOffset
                                                        toContentOffset:finalContentOffset
                                                               duration:UIScrollViewQuickAnimationDuration
                                                                  curve:UIScrollViewAnimationScrollCurveQuadraticEaseOut] autorelease];
    } else {
        return nil;
    }
}

static void _UIScrollViewAnimateWithVelocity(UIScrollView *scrollView, CGPoint velocity)
{
    //DLog(@"velocity: %@", NSStringFromCGPoint(velocity));
    CFTimeInterval duration = (CFTimeInterval)[(NSNumber *)[CATransaction valueForKey:kCATransactionAnimationDuration] doubleValue];
    
    CGPoint proposedDelta = CGPointMake(velocity.x * duration, velocity.y * duration);
    //DLog(@"proposedDelta: %@", NSStringFromCGPoint(proposedDelta));
    CGPoint confinedDelta = _UIScrollViewConfinedDelta(scrollView, proposedDelta, YES);
    //DLog(@"confinedDelta: %@", NSStringFromCGPoint(confinedDelta));
    _UIScrollViewScrollContent(scrollView, confinedDelta, YES);
    
    /*const CGPoint confinedOffset = _UIScrollViewConfinedContentOffset(scrollView, scrollView->_contentOffset);
    
    // if we've pulled up the content outside it's bounds, we don't want to register any flick momentum there and instead just
    // have the animation pull the content back into place immediately.
    if (confinedOffset.x != scrollView->_contentOffset.x) {
        velocity.x = 0;
    }
    if (confinedOffset.y != scrollView->_contentOffset.y) {
        velocity.y = 0;
    }
    
    if (!CGPointEqualToPoint(velocity, CGPointZero) || !CGPointEqualToPoint(confinedOffset, scrollView->_contentOffset)) {
        return [[[UIScrollViewAnimationDeceleration alloc] initWithScrollView:scrollView
                                                                     velocity:velocity] autorelease];
    } else {
        return nil;
    }*/
}

static void _UIScrollViewBeginDragging(UIScrollView *scrollView)
{
    if (!scrollView->_dragging) {
        scrollView->_dragging = YES;
        
        scrollView->_horizontalScroller.alwaysVisible = YES;
        scrollView->_verticalScroller.alwaysVisible = YES;
        
        _UIScrollViewCancelScrollAnimation(scrollView);
        
        if (scrollView->_delegateCan.scrollViewWillBeginDragging) {
            [scrollView->_delegate scrollViewWillBeginDragging:scrollView];
        }
    }
}

static void _UIScrollViewEndDraggingWithVelocity(UIScrollView *scrollView, CGPoint velocity)
{
    //DLog();
    if (scrollView->_dragging) {
        scrollView->_dragging = NO;
        //DLog(@"velocity: %@", NSStringFromCGPoint(velocity));
        _UIScrollViewAnimateWithVelocity(scrollView, velocity);
        //UIScrollViewAnimation *decelerationAnimation = scrollView->_pagingEnabled ? _UIScrollViewPageSnapAnimation(scrollView) :  _UIScrollViewAnimateWithVelocity(scrollView, velocity);
        BOOL deceleratingAnimation = YES;
        if (scrollView->_delegateCan.scrollViewDidEndDragging) {
            [scrollView->_delegate scrollViewDidEndDragging:scrollView willDecelerate:deceleratingAnimation];
        }
        if (deceleratingAnimation) {
            //[self _setScrollAnimation:decelerationAnimation];
            //_UIScrollViewSetScrollAnimation(scrollView, decelerationAnimation);
            scrollView->_horizontalScroller.alwaysVisible = YES;
            scrollView->_verticalScroller.alwaysVisible = YES;
            scrollView->_decelerating = YES;
            if (scrollView->_delegateCan.scrollViewWillBeginDecelerating) {
                [scrollView->_delegate scrollViewWillBeginDecelerating:scrollView];
            }
        } else {
            scrollView->_horizontalScroller.alwaysVisible = NO;
            scrollView->_verticalScroller.alwaysVisible = NO;
            //_UIScrollViewConfineContent(scrollView);
        }
    }
}

static void _UIScrollViewDragBy(UIScrollView *scrollView, CGPoint delta)
{
    if (scrollView->_dragging) {
        //DLog();
        scrollView->_horizontalScroller.alwaysVisible = YES;
        scrollView->_verticalScroller.alwaysVisible = YES;
        
        //CGPoint originalOffset = scrollView.contentOffset;
        //DLog(@"originalOffset: %@", NSStringFromCGPoint(originalOffset));
        CGPoint proposedDelta = delta;//originalOffset;
        //proposedDelta.x += delta.x;
        //proposedDelta.y += delta.y;
        //DLog(@"proposedDelta: %@", NSStringFromCGPoint(proposedDelta));
        CGPoint confinedDelta = _UIScrollViewConfinedDelta(scrollView, proposedDelta, NO);
        //DLog(@"confinedDelta: %@", NSStringFromCGPoint(confinedDelta));
        /*if (scrollView->_bounces) {
         BOOL shouldHorizontalBounce = (fabs(proposedDelta.x - confinedOffset.x) > 0);
         BOOL shouldVerticalBounce = (fabs(proposedDelta.y - confinedOffset.y) > 0);
         if (shouldHorizontalBounce) {
         proposedDelta.x = originalOffset.x + (0.055 * delta.x);
         }
         if (shouldVerticalBounce) {
         proposedDelta.y = originalOffset.y + (0.055 * delta.y);
         }
         _UIScrollViewSetRestrainedContentOffset(scrollView, proposedDelta);
         } else {*/
        //DLog(@"setContentOffset:confinedOffset");
        //[scrollView setContentOffset:confinedOffset];
        _UIScrollViewScrollContent(scrollView, confinedDelta, NO);
        //}
    }
}

@interface UIScrollView () <UIScrollerDelegate>

@end

@implementation UIScrollView

@synthesize contentOffset=_contentOffset;
@synthesize contentInset=_contentInset;
@synthesize scrollIndicatorInsets=_scrollIndicatorInsets;
@synthesize scrollEnabled=_scrollEnabled;
@synthesize showsHorizontalScrollIndicator=_showsHorizontalScrollIndicator;
@synthesize showsVerticalScrollIndicator=_showsVerticalScrollIndicator;
@synthesize contentSize=_contentSize;
@synthesize maximumZoomScale=_maximumZoomScale;
@synthesize minimumZoomScale=_minimumZoomScale;
@synthesize scrollsToTop=_scrollsToTop;
@synthesize indicatorStyle=_indicatorStyle;
@synthesize delaysContentTouches=_delaysContentTouches;
@synthesize delegate=_delegate;
@synthesize pagingEnabled=_pagingEnabled;
@synthesize canCancelContentTouches=_canCancelContentTouches;
@synthesize bouncesZoom=_bouncesZoom;
@synthesize zooming=_zooming;
@synthesize alwaysBounceVertical=_alwaysBounceVertical;
@synthesize alwaysBounceHorizontal=_alwaysBounceHorizontal;
@synthesize bounces=_bounces;
@synthesize decelerationRate=_decelerationRate;// scrollWheelGestureRecognizer=_scrollWheelGestureRecognizer,
@synthesize panGestureRecognizer=_panGestureRecognizer;

#pragma mark - Life cycle

- (id)initWithFrame:(CGRect)frame
{
    if ((self=[super initWithFrame:frame])) {
        //DLog();
        _contentOffset = CGPointZero;
        _contentSize = CGSizeZero;
        _contentInset = UIEdgeInsetsZero;
        _scrollIndicatorInsets = UIEdgeInsetsZero;
        _scrollEnabled = YES;
        _showsVerticalScrollIndicator = YES;
        _showsHorizontalScrollIndicator = YES;
        _maximumZoomScale = 1;
        _minimumZoomScale = 1;
        _scrollsToTop = YES;
        _indicatorStyle = UIScrollViewIndicatorStyleDefault;
        _delaysContentTouches = YES;
        _canCancelContentTouches = YES;
        _pagingEnabled = NO;
        _bouncesZoom = NO;
        _zooming = NO;
        _alwaysBounceVertical = NO;
        _alwaysBounceHorizontal = NO;
        _bounces = YES;
        _decelerationRate = UIScrollViewDecelerationRateNormal;
        //DLog();
        _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_gestureDidChange:)];
        [self addGestureRecognizer:_panGestureRecognizer];
//DLog();
        //_scrollWheelGestureRecognizer = [[UIScrollWheelGestureRecognizer alloc] initWithTarget:self action:@selector(_gestureDidChange:)];
        //[self addGestureRecognizer:_scrollWheelGestureRecognizer];
//DLog();
        /*
        _verticalScroller = [[UIScroller alloc] init];
        //DLog();
        _verticalScroller.delegate = self;
        //DLog();
        [super addSubview:_verticalScroller];
//DLog();
        _horizontalScroller = [[UIScroller alloc] init];
        _horizontalScroller.delegate = self;
        [super addSubview:_horizontalScroller];*/
        //DLog();
        self.clipsToBounds = YES;
        //DLog();
    }
    return self;
}

- (void)dealloc
{
    [_panGestureRecognizer release];
    //[_scrollWheelGestureRecognizer release];
    [_scrollAnimation release];
    [_verticalScroller release];
    [_horizontalScroller release];
    [super dealloc];
}

#pragma mark - Accessors

- (void)setDelegate:(id)newDelegate
{
    _delegate = newDelegate;
    _delegateCan.scrollViewDidScroll = [_delegate respondsToSelector:@selector(scrollViewDidScroll:)];
    _delegateCan.scrollViewWillBeginDragging = [_delegate respondsToSelector:@selector(scrollViewWillBeginDragging:)];
    _delegateCan.scrollViewDidEndDragging = [_delegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)];
    _delegateCan.viewForZoomingInScrollView = [_delegate respondsToSelector:@selector(viewForZoomingInScrollView:)];
    _delegateCan.scrollViewWillBeginZooming = [_delegate respondsToSelector:@selector(scrollViewWillBeginZooming:withView:)];
    _delegateCan.scrollViewDidEndZooming = [_delegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)];
    _delegateCan.scrollViewDidZoom = [_delegate respondsToSelector:@selector(scrollViewDidZoom:)];
    _delegateCan.scrollViewDidEndScrollingAnimation = [_delegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)];
    _delegateCan.scrollViewWillBeginDecelerating = [_delegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)];
    _delegateCan.scrollViewDidEndDecelerating = [_delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)];
}

- (void)setIndicatorStyle:(UIScrollViewIndicatorStyle)style
{
    _indicatorStyle = style;
    _horizontalScroller.indicatorStyle = style;
    _verticalScroller.indicatorStyle = style;
}

- (void)setShowsHorizontalScrollIndicator:(BOOL)show
{
    _showsHorizontalScrollIndicator = show;
    [self setNeedsLayout];
}

- (void)setShowsVerticalScrollIndicator:(BOOL)show
{
    _showsVerticalScrollIndicator = show;
    [self setNeedsLayout];
}

- (void)setScrollEnabled:(BOOL)enabled
{
    _scrollEnabled = enabled;
    [self setNeedsLayout];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    _UIScrollViewConfineContent(self);
}

- (void)setContentOffset:(CGPoint)theOffset animated:(BOOL)animated
{
    //DLog();
    //if (animated) {
    CGPoint delta = CGPointMake(_contentOffset.x - theOffset.x, _contentOffset.y - theOffset.y);
    _UIScrollViewScrollContent(self, delta, animated);
    /*} else {
     //DLog(@"theOffset: %@", NSStringFromCGPoint(theOffset));
     _contentOffset.x = roundf(theOffset.x);
     _contentOffset.y = roundf(theOffset.y);
     //DLog(@"_contentOffset2: %@", NSStringFromCGPoint(_contentOffset));
     _UIScrollViewUpdateContentLayout(self);
     if (_delegateCan.scrollViewDidScroll) {
     [_delegate scrollViewDidScroll:self];
     }
     }*/
}

- (void)setContentOffset:(CGPoint)theOffset
{
    //DLog(@"theOffset: %@", NSStringFromCGPoint(theOffset));
    [self setContentOffset:theOffset animated:NO];
}

- (void)setContentSize:(CGSize)newSize
{
    if (!CGSizeEqualToSize(newSize, _contentSize)) {
        _contentSize = newSize;
        _UIScrollViewConfineContent(self);
    }
}

- (BOOL)isScrollEnabled
{
    return _scrollEnabled;
}

- (BOOL)isTracking
{
    return NO;
}

- (BOOL)isDragging
{
    return _dragging;
}

- (BOOL)isPagingEnabled
{
    return _pagingEnabled;
}

- (BOOL)isDecelerating
{
    return NO;
}

- (BOOL)isZoomBouncing
{
    return NO;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; frame = (%.0f %.0f; %.0f %.0f); clipsToBounds = %@; layer = %@; contentOffset = {%.0f, %.0f}>", [self className], self, self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height, (self.clipsToBounds ? @"YES" : @"NO"), self.layer, self.contentOffset.x, self.contentOffset.y];
}

#pragma mark - Overridden methods

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    const CGRect bounds = self.bounds;
    const CGFloat scrollerSize = UIScrollerWidthForBoundsSize(bounds.size);
    
    _verticalScroller.frame = CGRectMake(_contentOffset.x+bounds.size.width-scrollerSize-_scrollIndicatorInsets.right,_contentOffset.y+_scrollIndicatorInsets.top,scrollerSize,bounds.size.height-_scrollIndicatorInsets.top-_scrollIndicatorInsets.bottom);
    //DLog(@"_verticalScroller.frame: %@", NSStringFromCGRect(_verticalScroller.frame));
    _horizontalScroller.frame = CGRectMake(_contentOffset.x+_scrollIndicatorInsets.left,_contentOffset.y+bounds.size.height-scrollerSize-_scrollIndicatorInsets.bottom,bounds.size.width-_scrollIndicatorInsets.left-_scrollIndicatorInsets.right,scrollerSize);
    //DLog(@"_horizontalScroller: %@", NSStringFromCGRect(_horizontalScroller.frame));
}

- (void)addSubview:(UIView *)subview
{
    //DLog();
    [super addSubview:subview];
    //_contentSize = CGSizeCGRectUnion(_contentSize, subview.frame);
    //DLog();
    [self _bringScrollersToFront];
}

- (void)bringSubviewToFront:(UIView *)subview
{
    //DLog();
    [super bringSubviewToFront:subview];
    //DLog();
    [self _bringScrollersToFront];
    //DLog();
}

- (void)insertSubview:(UIView *)subview atIndex:(NSInteger)index
{
    [super insertSubview:subview atIndex:index];
    [self _bringScrollersToFront];
}

#pragma mark - Scroller

- (void)UIScrollerDidBeginDragging:(UIScroller *)scroller withEvent:(UIEvent *)event
{
    _UIScrollViewBeginDragging(self);
}

- (void)UIScroller:(UIScroller *)scroller contentOffsetDidChange:(CGFloat)newOffset
{
    DLog();
    if (scroller == _verticalScroller) {
        [self setContentOffset:CGPointMake(self.contentOffset.x,newOffset) animated:NO];
    } else if (scroller == _horizontalScroller) {
        [self setContentOffset:CGPointMake(newOffset,self.contentOffset.y) animated:NO];
    }
}

- (void)UIScrollerDidEndDragging:(UIScroller *)scroller withEvent:(UIEvent *)event
{
    DLog();
    UITouch *touch = [[event allTouches] anyObject];
    const CGPoint point = [touch locationInView:self];
    
    if (!CGRectContainsPoint(scroller.frame,point)) {
        scroller.alwaysVisible = NO;
    }
    _UIScrollViewEndDraggingWithVelocity(self,CGPointZero);
}

#pragma mark - Other delegates

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)flag
{
    //DLog(@"animation: %@, flag: %d", animation, flag);
    if (_delegateCan.scrollViewDidEndDecelerating) {
        [_delegate scrollViewDidEndDecelerating:self];
    }
}

#pragma mark - Actions

- (void)_updateScrollAnimation
{
    if ([_scrollAnimation animate]) {
        _UIScrollViewCancelScrollAnimation(self);
    }
}

- (void)_gestureDidChange:(UIGestureRecognizer *)gesture
{
    // the scrolling gestures are broken into two components due to the somewhat fundamental differences
    // in how they are handled by the system. The UIPanGestureRecognizer will only track scrolling gestures
    // that come from actual touch scroller devices. This does *not* include old fashioned mouse wheels.
    // the non-standard UIScrollWheelGestureRecognizer is a discrete recognizer which only responds to
    // non-gesture scroll events such as those from non-touch devices. HOWEVER the system sends momentum
    // scroll events *after* the touch gesture has ended which allows for us to distinguish the difference
    // here between actual touch gestures and the momentum gestures and thus feed them into the playing
    // deceleration animation as we receive them so that we can preserve the system's proper feel for that.
    
    // Also important to note is that with a legacy scroll device, each movement of the wheel is going to
    // trigger a beginDrag, dragged, endDragged sequence. I believe that's an acceptable compromise however
    // it might cause some potentially strange behavior in client code that is not expecting such rapid
    // state changes along these lines.
    
    // Another note is that only touch-based panning gestures will trigger calls to _dragBy: which means
    // that only touch devices can possibly pull the content outside of the scroll view's bounds while
    // active. An old fashioned wheel will not be able to do that and its scroll events are confined to
    // the bounds of the scroll view.
    
    // There are some semi-legacy devices like the magic mouse which 10.6 doesn't seem to consider a true
    // touch device, so it doesn't send the gestureBegin/ended stuff that's used to recognize such things
    // but it *will* send momentum events. This means that those devices on 10.6 won't give you the feeling
    // of being able to grab and pull your content away from the bounds like a proper touch trackpad will.
    // As of 10.7 it appears Apple fixed this and they do actually send the proper gesture events, so on
    // 10.7 the magic mouse should end up acting like any other touch input device as far as we're concerned.
    
    // Momentum scrolling doesn't work terribly well with how the paging stuff is now handled. Something
    // could be improved there. I'm not sure if the paging animation should just pretend it's longer to
    // kind of "mask" the OS' momentum events, or if a flag should be set, or if it should work so that
    // even in paging mode the deceleration and stuff happens like usual and it only snaps to the correct
    // page *after* the usual deceleration is done. I can't decide what might be best, but since we
    // don't use paging mode in Twitterrific at the moment, I'm not suffeciently motivated to worry about it. :)
    //DLog(@"gesture: %@", gesture);
    if (gesture == _panGestureRecognizer) {
        //DLog(@"_panGestureRecognizer.state: %d", _panGestureRecognizer.state);
        if (_panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
            //DLog();
            _UIScrollViewBeginDragging(self);
        } else if (_panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
            //DLog();
            _UIScrollViewDragBy(self, [_panGestureRecognizer translationInView:self]);
            //[_panGestureRecognizer setTranslation:CGPointZero inView:self];
        } else if (_panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
            //DLog();
            _UIScrollViewEndDraggingWithVelocity(self,[_panGestureRecognizer velocityInView:self]);
        }
    }
}

#pragma mark - Public methods

- (void)flashScrollIndicators
{
    [_horizontalScroller flash];
    [_verticalScroller flash];
}

- (void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated
{
    const CGRect contentRect = CGRectMake(0,0,_contentSize.width, _contentSize.height);
    const CGRect visibleRect = self.bounds;
    CGRect goalRect = CGRectIntersection(rect, contentRect);

    DLog();
    if (!CGRectIsNull(goalRect) && !CGRectContainsRect(visibleRect, goalRect)) {
        
        // clamp the goal rect to the largest possible size for it given the visible space available
        // this causes it to prefer the top-left of the rect if the rect is too big
        goalRect.size.width = MIN(goalRect.size.width, visibleRect.size.width);
        goalRect.size.height = MIN(goalRect.size.height, visibleRect.size.height);
        
        CGPoint offset = self.contentOffset;
        
        if (CGRectGetMaxY(goalRect) > CGRectGetMaxY(visibleRect)) {
            offset.y += CGRectGetMaxY(goalRect) - CGRectGetMaxY(visibleRect);
        } else if (CGRectGetMinY(goalRect) < CGRectGetMinY(visibleRect)) {
            offset.y += CGRectGetMinY(goalRect) - CGRectGetMinY(visibleRect);
        }
        
        if (CGRectGetMaxX(goalRect) > CGRectGetMaxX(visibleRect)) {
            offset.x += CGRectGetMaxX(goalRect) - CGRectGetMaxX(visibleRect);
        } else if (CGRectGetMinX(goalRect) < CGRectGetMinX(visibleRect)) {
            offset.x += CGRectGetMinX(goalRect) - CGRectGetMinX(visibleRect);
        }
        
        [self setContentOffset:offset animated:animated];
    }
}

- (float)zoomScale
{
    UIView *zoomingView = _UIScrollViewZoomingView(self);
    
    // it seems weird to return the "a" component of the transform for this, but after some messing around with the real UIKit, I'm
    // reasonably certain that's how it is doing it.
    return zoomingView? zoomingView.transform.a : 1.f;
}

- (void)setZoomScale:(float)scale animated:(BOOL)animated
{
    UIView *zoomingView = _UIScrollViewZoomingView(self);
    scale = MIN(MAX(scale, _minimumZoomScale), _maximumZoomScale);

    if (zoomingView && self.zoomScale != scale) {
        [UIView animateWithDuration:animated? UIScrollViewAnimationDuration : 0
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                         animations:^(void) {
                             zoomingView.transform = CGAffineTransformMakeScale(scale, scale);
                             const CGSize size = zoomingView.frame.size;
                             zoomingView.layer.position = CGPointMake(size.width/2.f, size.height/2.f);
                             self.contentSize = size;
                         }
                         completion:NULL];
    }
}

- (void)setZoomScale:(float)scale
{
    [self setZoomScale:scale animated:NO];
}

- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated
{
}

- (void)_bringScrollersToFront
{
    /*DLog(@"self: %@", self);
    DLog(@"[super className]: %@", [super className]);
    [super bringSubviewToFront:_horizontalScroller];
    DLog();
    [super bringSubviewToFront:_verticalScroller];*/
}

@end

#pragma mark - Shared functions

CGPoint _UIScrollViewConfinedContentOffset(UIScrollView *scrollView, CGPoint contentOffset)
{/*
    CGRect scrollerBounds = UIEdgeInsetsInsetRect(scrollView.bounds, scrollView->_contentInset);
    //DLog(@"scrollView->_contentSize: %@", NSStringFromCGSize(scrollView->_contentSize));
    //DLog(@"contentOffset: %@", NSStringFromCGPoint(contentOffset));
    if ((scrollView->_contentSize.width - contentOffset.x) < scrollerBounds.size.width) {
        contentOffset.x = (scrollView->_contentSize.width - scrollerBounds.size.width);
    }
    if ((scrollView->_contentSize.height-contentOffset.y) < scrollerBounds.size.height) {
        contentOffset.y = (scrollView->_contentSize.height - scrollerBounds.size.height);
    }
    //DLog(@"contentOffset2: %@", NSStringFromCGPoint(contentOffset));
    contentOffset.x = MAX(contentOffset.x,0);
    contentOffset.y = MAX(contentOffset.y,0);
    if (scrollView->_contentSize.width <= scrollerBounds.size.width) {
        contentOffset.x = 0;
    }
    if (scrollView->_contentSize.height <= scrollerBounds.size.height) {
        contentOffset.y = 0;
    }
    //DLog(@"contentOffset3: %@", NSStringFromCGPoint(contentOffset));*/
    return contentOffset;
}

void _UIScrollViewSetRestrainedContentOffset(UIScrollView *scrollView, CGPoint offset)
{
    const CGPoint confinedOffset = _UIScrollViewConfinedContentOffset(scrollView, offset);
    const CGRect scrollerBounds = UIEdgeInsetsInsetRect(scrollView.bounds, scrollView->_contentInset);
    
    if (!scrollView.alwaysBounceHorizontal && scrollView->_contentSize.width <= scrollerBounds.size.width) {
        offset.x = confinedOffset.x;
    }
    if (!scrollView.alwaysBounceVertical && scrollView->_contentSize.height <= scrollerBounds.size.height) {
        offset.y = confinedOffset.y;
    }
    scrollView.contentOffset = offset;
}
