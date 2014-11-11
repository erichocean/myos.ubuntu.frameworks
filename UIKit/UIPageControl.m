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

#define _kPageDotSize           8
#define _kPageDotInterSpace     16

#pragma mark - Static functions

static float _UIPageControlHighlightedDotLoaction(UIPageControl *pageControl)
{
    float dotsSize = _kPageDotInterSpace * (pageControl->_numberOfPages - 1);
    return (pageControl.frame.size.width - dotsSize) / 2.0 + pageControl->_currentPage * _kPageDotInterSpace - _kPageDotSize / 2.0;
}

@implementation UIPageControl

@synthesize currentPage=_currentPage;
@synthesize numberOfPages=_numberOfPages;
@synthesize defersCurrentPageDisplay=_defersCurrentPageDisplay;

#pragma mark - Life cycle

- (id)initWithFrame:(CGRect)theFrame
{
    if ((self = [super initWithFrame:theFrame])) {
        _dotView = [[UIView alloc] initWithFrame:CGRectMake(0,0,_kPageDotSize,_kPageDotSize)];
        _dotView.backgroundColor = [UIColor whiteColor];
        [self addSubview:_dotView];
        //DLog(@"self.subviews: %@", self.subviews);
    }
    return self;
}

- (void)dealloc
{
    [_dotView release];
    [super dealloc];
}

#pragma mark - Accessors

- (void)setCurrentPage:(NSInteger)page
{
    //DLog(@"page: %d", page);
    if (page != _currentPage) {
        _currentPage = MIN(MAX(0,page), self.numberOfPages-1);
        [self setNeedsLayout];
    }
}

- (void)setNumberOfPages:(NSInteger)numberOfPages
{
    _numberOfPages = numberOfPages;
    _CALayerSetNeedsDisplay(_layer);
    _dotView.hidden = (_numberOfPages == 1);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; currentPage: %d; numberOfPages: %d>", [self className], self, _currentPage, _numberOfPages];
}

#pragma mark - Overridden methods
 
- (void)drawRect:(CGRect)rect
{
    //DLog(@"_numberOfPages: %d", _numberOfPages);
    if (_numberOfPages == 1) {
        return;
    }
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    float dotsSize = _kPageDotInterSpace * (_numberOfPages - 1);
    CGContextSetRGBFillColor(context, 0.5, 0.5, 0.5, 0.5);
    for (int i = 0; i < _numberOfPages; i++) {
        CGContextFillRect(context, CGRectMake((rect.size.width - dotsSize) / 2.0 + i * _kPageDotInterSpace - _kPageDotSize/2.0,
                                              rect.size.height / 2.0 - _kPageDotSize / 2.0,
                                              _kPageDotSize, _kPageDotSize));
    }
    CGContextRestoreGState(context);
    //DLog(@"end");
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    //DLog();
    float dotsSize = _kPageDotInterSpace * (_numberOfPages - 1);
    _dotView.center = CGPointMake((self.frame.size.width - dotsSize) / 2.0 + _currentPage * _kPageDotInterSpace,
                                  self.frame.size.height / 2.0);
}

- (void)_sendActionsForControlEvents:(UIControlEvents)controlEvents withEvent:(UIEvent *)event
{
    [super _sendActionsForControlEvents:controlEvents withEvent:event];
    UITouch *touch = event->_touch;
    if (touch->_phase == UITouchPhaseEnded) {
        //DLog(@"event: %@", event);
        CGPoint point = [touch locationInView:self];
        int oldCurrentPage = _currentPage;
        //DLog(@"_currentPage: %d", _currentPage);
        if (!_defersCurrentPageDisplay) {
            float highlightedDotLoaction = _UIPageControlHighlightedDotLoaction(self);
            if (point.x > highlightedDotLoaction) {
                self.currentPage = _currentPage+1;
            } else {
                self.currentPage = _currentPage-1;
            }
        }
        //DLog(@"_currentPage2: %d", _currentPage);
        if (oldCurrentPage != _currentPage) {
            //DLog();
            [super _sendActionsForControlEvents:UIControlEventValueChanged withEvent:event];
        }
    }
}

@end
