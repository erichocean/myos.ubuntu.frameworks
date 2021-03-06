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

static CGSize UIActivityIndicatorViewStyleSize(UIActivityIndicatorViewStyle style)
{
    if (style == UIActivityIndicatorViewStyleWhiteLarge) {
        return CGSizeMake(40,40);
    } else {
        return CGSizeMake(20,20);
    }
}

static UIImage *UIActivityIndicatorViewFrameImage(UIActivityIndicatorViewStyle style, NSInteger frame, NSInteger numberOfFrames)
{
    const CGSize frameSize = UIActivityIndicatorViewStyleSize(style);
    const CGFloat radius = frameSize.width / 2.f;
    const CGFloat TWOPI = M_PI * 2.f;
    const CGFloat numberOfTeeth = 12;
    const CGFloat toothWidth = (style == UIActivityIndicatorViewStyleWhiteLarge) ? 3.5 : 2;

    UIColor *toothColor = (style == UIActivityIndicatorViewStyleGray) ? [UIColor grayColor] : [UIColor whiteColor];
    //DLog(@"toothColor: %@", toothColor);
    //DLog();
    UIGraphicsBeginImageContext(frameSize);
    //DLog();
    CGContextRef c = UIGraphicsGetCurrentContext();

    //DLog();
    // first put the origin in the center of the frame. this makes things easier later
    CGContextTranslateCTM(c, radius, radius);
    //DLog();
    // now rotate the entire thing depending which frame we're trying to generate
    CGContextRotateCTM(c, frame / (CGFloat)numberOfFrames * TWOPI);
    //DLog();
    // draw all the teeth
    for (NSInteger toothNumber=0; toothNumber<numberOfTeeth; toothNumber++) {
        // set the correct color for the tooth, dividing by more than the number of teeth to prevent the last tooth from being too translucent
        const CGFloat alpha = 0.3 + ((toothNumber / numberOfTeeth) * 0.7);
        //DLog();
        UIColor *color = [toothColor colorWithAlphaComponent:alpha];
        //DLog(@"color: %@", color);
        [color setFill];
        //DLog();
        // position and draw the tooth
        CGContextRotateCTM(c, 1 / numberOfTeeth * TWOPI);
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(-toothWidth/2.f,-radius,toothWidth,ceilf(radius*.54f))
                                    cornerRadius:toothWidth/2.f] fill];
        //DLog();
    }
    //DLog();
    // hooray!
    UIImage *frameImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    //DLog();
    return frameImage;
}

@implementation UIActivityIndicatorView

- (id)initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyle)style
{
    CGRect frame = CGRectZero;
    frame.size = UIActivityIndicatorViewStyleSize(style);
    //DLog();
    if ((self=[super initWithFrame:frame])) {
        _animating = NO;
        self.activityIndicatorViewStyle = style;
        self.hidesWhenStopped = YES;
        self.opaque = NO;
        //DLog();
    }

    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [self initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite])) {
        self.frame = frame;
    }

    return self;
}

#pragma mark - Overridden methods

- (void)drawRect:(CGRect)rect
{
    UIActivityIndicatorViewStyle style;
    //DLog();
    @synchronized (self) {
        style = _activityIndicatorViewStyle;
    }
    //DLog();
    [UIActivityIndicatorViewFrameImage(style, 0, 1) drawInRect:self.bounds];
}

#pragma mark - Accessors

- (CGSize)sizeThatFits:(CGSize)aSize
{
    UIActivityIndicatorViewStyle style;
    
    @synchronized (self) {
        style = _activityIndicatorViewStyle;
    }
    return UIActivityIndicatorViewStyleSize(style);
}

- (void)setActivityIndicatorViewStyle:(UIActivityIndicatorViewStyle)style
{
    @synchronized (self) {
        if (_activityIndicatorViewStyle != style) {
            _activityIndicatorViewStyle = style;
            _CALayerSetNeedsDisplay(_layer);
            if (_animating) {
                [self startAnimating];	// this will reset the images in the animation if it was already animating
            }
        }
    }
}

- (UIActivityIndicatorViewStyle)activityIndicatorViewStyle
{
    UIActivityIndicatorViewStyle style;

    @synchronized (self) {
        style = _activityIndicatorViewStyle;
    }

    return style;
}

- (void)setHidesWhenStopped:(BOOL)hides
{
    @synchronized (self) {
        _hidesWhenStopped = hides;

        if (_hidesWhenStopped) {
            self.hidden = !_animating;
        } else {
            self.hidden = NO;
        }
    }
}

- (BOOL)hidesWhenStopped
{
    BOOL hides;

    @synchronized (self) {
        hides = _hidesWhenStopped;
    }

    return hides;
}

#pragma mark - Public methods

- (void)startAnimating
{
    @synchronized (self) {
        _animating = YES;
        self.hidden = NO;
        //DLog();
        const NSInteger numberOfFrames = 12;
        const CFTimeInterval animationDuration = 1.0;
        //DLog();
        NSMutableArray *images = [[NSMutableArray alloc] initWithCapacity:numberOfFrames];
        for (NSInteger frameNumber=0; frameNumber<numberOfFrames; frameNumber++) {
            [images addObject:(__bridge id)UIActivityIndicatorViewFrameImage(_activityIndicatorViewStyle, frameNumber, numberOfFrames).CGImage];
        }
        //DLog(@"images: %@", images);
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
        animation.calculationMode = kCAAnimationDiscrete;
        animation.duration = animationDuration;
        //animation.repeatCount = HUGE_VALF;
        animation.removedOnCompletion = NO;
        animation.values = images;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        //DLog(@"animation: %@", animation);
        [self.layer addAnimation:animation forKey:@"contents"];
        [images release];
    }
}

- (void)stopAnimating
{
    @synchronized (self) {
        _animating = NO;
        [self.layer removeAnimationForKey:@"contents"];
        
        if (self.hidesWhenStopped) {
            self.hidden = YES;
        }
    }
}

- (BOOL)isAnimating
{
    BOOL animating;

    @synchronized (self) {
        animating = _animating;
    }
    return animating;
}

@end
