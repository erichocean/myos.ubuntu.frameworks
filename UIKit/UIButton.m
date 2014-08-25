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

#import <UIKit/UIButton.h>
#import <UIKit/UIControl-private.h>
#import <UIKit/UIColor.h>
#import "UILabel.h"
#import "UIFont.h"
#import <UIKit/UIImage.h>
#import <UIKit/UIImageView-private.h>
#import <CoreAnimation/CoreAnimation-private.h>

static NSString *UIButtonContentTypeTitle = @"UIButtonContentTypeTitle";
static NSString *UIButtonContentTypeTitleColor = @"UIButtonContentTypeTitleColor";
static NSString *UIButtonContentTypeTitleShadowColor = @"UIButtonContentTypeTitleShadowColor";
static NSString *UIButtonContentTypeBackgroundImage = @"UIButtonContentTypeBackgroundImage";
static NSString *UIButtonContentTypeImage = @"UIButtonContentTypeImage";

CGSize _UIButtonTitleSizeForState(UIButton *button, UIControlState state);
id _UIButtonNormalContentForState(UIButton *button, UIControlState state, NSString *type);
CGSize _UIButtonImageSizeForState(UIButton *button, UIControlState state);
CGRect _UIButtonComponentRectForSize(UIButton *button, CGSize size, CGRect contentRect, UIControlState state);
void _UIButtonSetContent(UIButton* button, id value, UIControlState state, NSString *type);
UIColor* _UIButtonDefaultTitleShadowColor(UIButton *button);
UIColor* _UIButtonDefaultTitleColor(UIButton* button);
void _UIButtonUpdateContent(UIButton* button);

@implementation UIButton

@synthesize buttonType=_buttonType, titleLabel=_titleLabel, reversesTitleShadowWhenHighlighted=_reversesTitleShadowWhenHighlighted;
@synthesize adjustsImageWhenHighlighted=_adjustsImageWhenHighlighted, adjustsImageWhenDisabled=_adjustsImageWhenDisabled;
@synthesize showsTouchWhenHighlighted=_showsTouchWhenHighlighted, imageView=_imageView, contentEdgeInsets=_contentEdgeInsets;
@synthesize titleEdgeInsets=_titleEdgeInsets, imageEdgeInsets=_imageEdgeInsets;

#pragma mark - Life cycle

+ (id)buttonWithType:(UIButtonType)buttonType
{
    UIButton *button = [[[self alloc] initWithFrame:CGRectZero] autorelease];
    button->_buttonType = buttonType;
   // button->_layer.backgroundColor = [[UIColor whiteColor] CGColor];
    if (buttonType==UIButtonTypeRoundedRect) {
        button.layer.borderColor = [[UIColor whiteColor] CGColor];
        button.layer.borderWidth = 2;
        button.layer.cornerRadius = 10;
        button.layer.masksToBounds = YES;
        button->gradientLayer = [CAGradientLayer layer];
        button->gradientLayer.colors = [NSArray arrayWithObjects:(id)[_kStartBlueGradientColor CGColor],
                                                                 (id)[_kMiddleBlueGradientColor CGColor],
                                                                 (id)[_kEndBlueGradientColor CGColor], nil];
        button->gradientLayer.cornerRadius = 10;
        button->gradientLayer.borderWidth = 0;
 
    }

   /*switch (buttonType) {
        case UIButtonTypeRoundedRect:
        case UIButtonTypeDetailDisclosure:
        case UIButtonTypeInfoLight:
        case UIButtonTypeInfoDark:
        case UIButtonTypeContactAdd:
            //return [[[UIRoundedRectButton alloc] init] autorelease];
        case UIButtonTypeCustom:    
        default:
            return [[[self alloc] init] autorelease];
    }*/
    return button;
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self=[super initWithFrame:frame])) {
        //DLog(@"");
        self.backgroundColor = [UIColor whiteColor];
        _buttonType = UIButtonTypeCustom;
        _content = [[NSMutableDictionary alloc] init];
        _titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
        _imageView = [[UIImageView alloc] init];
        _backgroundImageView = [[UIImageView alloc] init];
        _adjustsImageWhenHighlighted = YES;
        _adjustsImageWhenDisabled = YES;
        _showsTouchWhenHighlighted = NO;
        
        self.opaque = NO;
        _titleLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textAlignment = UITextAlignmentCenter;
        _titleLabel.shadowOffset = CGSizeZero;
        _titleLabel.font = [UIFont systemFontOfSize:[UIFont buttonFontSize]];

        [self addSubview:_backgroundImageView];
        [self addSubview:_imageView];
        [self addSubview:_titleLabel];
    }
    return self;
}

- (void)dealloc
{
    [_content release];
    [_titleLabel release];
    [_imageView release];
    [_backgroundImageView release];
    [_adjustedHighlightImage release];
    [_adjustedDisabledImage release];
    [super dealloc];
}

#pragma mark - Accessors

- (void)setFrame:(CGRect)newFrame
{
    if (!CGRectEqualToRect(newFrame,_layer.frame)) {
        [super setFrame:newFrame];
        self->gradientLayer.frame = self.bounds;
        if (_titleLabel) {
            self->_titleLabel.frame = self.bounds;
        }
    }
}


- (NSString *)currentTitle
{
    return _titleLabel.text;
}

- (UIColor *)currentTitleColor
{
    return _titleLabel.textColor;
}

- (UIColor *)currentTitleShadowColor
{
    return _titleLabel.shadowColor;
}

- (UIImage *)currentImage
{
    return _imageView.image;
}

- (UIImage *)currentBackgroundImage
{
    return _backgroundImageView.image;
}

- (void)setTitle:(NSString *)title forState:(UIControlState)state
{
    _UIButtonSetContent(self, title, state, UIButtonContentTypeTitle);
}

- (void)setTitleColor:(UIColor *)color forState:(UIControlState)state
{
    _UIButtonSetContent(self, color, state, UIButtonContentTypeTitleColor);
}

- (void)setTitleShadowColor:(UIColor *)color forState:(UIControlState)state
{
    _UIButtonSetContent(self, color, state, UIButtonContentTypeTitleShadowColor);
}

- (void)setBackgroundImage:(UIImage *)image forState:(UIControlState)state
{
    _UIButtonSetContent(self, image, state, UIButtonContentTypeBackgroundImage);
}

- (void)setImage:(UIImage *)image forState:(UIControlState)state
{
    [_adjustedHighlightImage release];
    [_adjustedDisabledImage release];
    _adjustedDisabledImage = _adjustedHighlightImage = nil;
    _UIButtonSetContent(self, image, state, UIButtonContentTypeImage);
}

- (NSString *)titleForState:(UIControlState)state
{
    return _UIButtonNormalContentForState(self, state, UIButtonContentTypeTitle);
}

- (UIColor *)titleColorForState:(UIControlState)state
{
    return _UIButtonNormalContentForState(self, state, UIButtonContentTypeTitleColor);
}

- (UIColor *)titleShadowColorForState:(UIControlState)state
{
    return _UIButtonNormalContentForState(self, state, UIButtonContentTypeTitleShadowColor);
}

- (UIImage *)backgroundImageForState:(UIControlState)state
{
    return _UIButtonNormalContentForState(self, state, UIButtonContentTypeBackgroundImage);
}

- (UIImage *)imageForState:(UIControlState)state
{
    return _UIButtonNormalContentForState(self, state, UIButtonContentTypeImage);
}

- (CGRect)backgroundRectForBounds:(CGRect)bounds
{
    return bounds;
}

- (CGRect)contentRectForBounds:(CGRect)bounds
{
    return UIEdgeInsetsInsetRect(bounds,_contentEdgeInsets);
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    const UIControlState state = self.state;
    
    UIEdgeInsets inset = _titleEdgeInsets;
    CGSize imageSize = _UIButtonImageSizeForState(self, state);
    inset.left += imageSize.width;
    
    return _UIButtonComponentRectForSize(self, _UIButtonTitleSizeForState(self, state), UIEdgeInsetsInsetRect(contentRect,inset), state);
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
    const UIControlState state = self.state;
    
    UIEdgeInsets inset = _imageEdgeInsets;
    inset.right += [self titleRectForContentRect:contentRect].size.width;
    
    return _UIButtonComponentRectForSize(self, _UIButtonImageSizeForState(self, state), UIEdgeInsetsInsetRect(contentRect,inset), state);
}

#pragma mark - Overridden methods

- (void)_updateContent
{
    _UIButtonUpdateContent(self);
    [super _updateContent];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
   
    const CGRect bounds = self.bounds;
    const CGRect contentRect = [self contentRectForBounds:bounds];

    _backgroundImageView.frame = [self backgroundRectForBounds:bounds];
    _titleLabel.frame = [self titleRectForContentRect:contentRect];
    _imageView.frame = [self imageRectForContentRect:contentRect];
}

#pragma mark - Helpers

- (CGSize)sizeThatFits:(CGSize)size
{
    const UIControlState state = self.state;
    
    const CGSize imageSize = _UIButtonImageSizeForState(self, state);
    const CGSize titleSize = _UIButtonTitleSizeForState(self, state);
    
    CGSize fitSize;
    fitSize.width = _contentEdgeInsets.left + _contentEdgeInsets.right + titleSize.width + imageSize.width;
    fitSize.height = _contentEdgeInsets.top + _contentEdgeInsets.bottom + MAX(titleSize.height,imageSize.height);
    
    UIImage* background = [self currentBackgroundImage];
    if (background) {
        CGSize backgroundSize = background.size;
        fitSize.width = MAX(fitSize.width, backgroundSize.width);
        fitSize.height = MAX(fitSize.height, backgroundSize.height);
    }
    
    return fitSize;
}

@end

#pragma mark - Private C functions

UIColor *_UIButtonDefaultTitleColor(UIButton *button)
{
    return [UIColor blueColor];
}

UIColor *_UIButtonDefaultTitleShadowColor(UIButton *button)
{
    return [UIColor blackColor];
}

id _UIButtonContentForState(UIButton *button, UIControlState state, NSString *type)
{
    return [[button->_content objectForKey:type] objectForKey:[NSNumber numberWithInt:state]];
}

id _UIButtonNormalContentForState(UIButton *button, UIControlState state, NSString *type)
{
    return _UIButtonContentForState(button, state, type) ?: _UIButtonContentForState(button, UIControlStateNormal, type);
}

void _UIButtonUpdateContent(UIButton *button)
{
    const UIControlState state = button.state;
    button->_titleLabel.text = [button titleForState:state];
    button->_titleLabel.textColor = [button titleColorForState:state] ?: _UIButtonDefaultTitleColor(button);
    button->_titleLabel.shadowColor = [button titleShadowColorForState:state] ?: _UIButtonDefaultTitleShadowColor(button);
    
    UIImage *image = _UIButtonContentForState(button, state, UIButtonContentTypeImage);
    UIImage *backgroundImage = _UIButtonContentForState(button, state, UIButtonContentTypeBackgroundImage);
   
    if (!image) {
        image = [button imageForState:state];	// find the correct default image to show
        if (button->_adjustsImageWhenDisabled && state & UIControlStateDisabled) {
            _UIImageViewSetDrawMode(button->_imageView, _UIImageViewDrawModeDisabled);
        } else if (button->_adjustsImageWhenHighlighted && state & UIControlStateHighlighted) {
            _UIImageViewSetDrawMode(button->_imageView, _UIImageViewDrawModeHighlighted);
        } else {
            _UIImageViewSetDrawMode(button->_imageView, _UIImageViewDrawModeNormal);
        }
    } else {
        _UIImageViewSetDrawMode(button->_imageView, _UIImageViewDrawModeNormal);
    }
    if (!backgroundImage) {
        backgroundImage = [button backgroundImageForState:state];
        if (button->_adjustsImageWhenDisabled && state & UIControlStateDisabled) {
            _UIImageViewSetDrawMode(button->_backgroundImageView, _UIImageViewDrawModeDisabled);
        } else if (button->_adjustsImageWhenHighlighted && state & UIControlStateHighlighted) {
            _UIImageViewSetDrawMode(button->_backgroundImageView, _UIImageViewDrawModeHighlighted);
        } else {
            _UIImageViewSetDrawMode(button->_backgroundImageView, _UIImageViewDrawModeNormal);
        }
    } else {
        _UIImageViewSetDrawMode(button->_backgroundImageView, _UIImageViewDrawModeNormal);
    }
    button->_imageView.image = image;
    button->_backgroundImageView.image = backgroundImage;
    if (button->_highlighted) {
        //DLog(@"[button->_registeredActions count]: %d", [button->_registeredActions count]);
        if ([button->_registeredActions count]==0) {
            //button->gradientLayer.frame = button.bounds;
            [button->_layer insertSublayer:button->gradientLayer atIndex:0];
        }
    } else {
        if ([button->_registeredActions count]==0) {
            [button->gradientLayer removeFromSuperlayer];
        }
    }
    [button setNeedsLayout];
}

void _UIButtonSetContent(UIButton *button, id value, UIControlState state, NSString *type)
{
    NSMutableDictionary *typeContent = [button->_content objectForKey:type];
    
    if (!typeContent) {
        typeContent = [[[NSMutableDictionary alloc] init] autorelease];
        [button->_content setObject:typeContent forKey:type];
    }
    NSNumber *key = [NSNumber numberWithInt:state];
    if (value) {
        [typeContent setObject:value forKey:key];
    } else {
        [typeContent removeObjectForKey:key];
    }
    _UIButtonUpdateContent(button);
}

CGSize _UIButtonBackgroundSizeForState(UIButton *button, UIControlState state)
{
    UIImage *backgroundImage = [button backgroundImageForState:state];
    return backgroundImage? backgroundImage.size : CGSizeZero;
}

CGSize _UIButtonTitleSizeForState(UIButton *button, UIControlState state)
{
    NSString *title = [button titleForState:state];
    return ([title length] > 0)? [title sizeWithFont:button->_titleLabel.font constrainedToSize:CGSizeMake(CGFLOAT_MAX,CGFLOAT_MAX)] : CGSizeZero;
}

CGSize _UIButtonImageSizeForState(UIButton *button, UIControlState state)
{
    UIImage *image = [button imageForState:state];
    return image ? image.size : CGSizeZero;
}

CGRect _UIButtonComponentRectForSize(UIButton *button, CGSize size, CGRect contentRect, UIControlState state)
{
    CGRect rect;

    rect.origin = contentRect.origin;
    rect.size = size;
    
    // clamp the right edge of the rect to the contentRect - this is what the real UIButton appears to do.
    if (CGRectGetMaxX(rect) > CGRectGetMaxX(contentRect)) {
        rect.size.width -= CGRectGetMaxX(rect) - CGRectGetMaxX(contentRect);
    }
    switch (button.contentHorizontalAlignment) {
        case UIControlContentHorizontalAlignmentCenter:
            rect.origin.x += floorf((contentRect.size.width/2.f) - (rect.size.width/2.f));
            break;
        case UIControlContentHorizontalAlignmentRight:
            rect.origin.x += contentRect.size.width - rect.size.width;
            break;
        case UIControlContentHorizontalAlignmentFill:
            rect.size.width = contentRect.size.width;
            break;
        case UIControlContentHorizontalAlignmentLeft:
            // don't do anything - it's already left aligned
            break;
    }
    switch (button.contentVerticalAlignment) {
        case UIControlContentVerticalAlignmentCenter:
            rect.origin.y += floorf((contentRect.size.height/2.f) - (rect.size.height/2.f));
            break;
        case UIControlContentVerticalAlignmentBottom:
            rect.origin.y += contentRect.size.height - rect.size.height;
            break;
        case UIControlContentVerticalAlignmentFill:
            rect.size.height = contentRect.size.height;
            break;
        case UIControlContentVerticalAlignmentTop:
            // don't do anything - it's already top aligned
            break;
    }
    return rect;
}

void _UIButtonStateDidChange(UIButton *button)
{
    _UIControlStateDidChange((UIControl *)button);
    _UIButtonUpdateContent(button);
}

