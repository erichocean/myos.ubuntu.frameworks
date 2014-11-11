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

@implementation UILabel

@synthesize text=_text, font=_font, textColor=_textColor, textAlignment=_textAlignment, lineBreakMode=_lineBreakMode, enabled=_enabled;
@synthesize numberOfLines=_numberOfLines, shadowColor=_shadowColor, shadowOffset=_shadowOffset;
@synthesize baselineAdjustment=_baselineAdjustment, adjustsFontSizeToFitWidth=_adjustsFontSizeToFitWidth;
@synthesize highlightedTextColor=_highlightedTextColor, minimumFontSize=_minimumFontSize, highlighted=_highlighted;

#pragma mark - Life cycle

- (id)initWithFrame:(CGRect)frame
{
    //DLog(@"1");
    if ((self = [super initWithFrame:frame])) {
        _userInteractionEnabled = NO;
        _textAlignment = UITextAlignmentLeft;
        _lineBreakMode = UILineBreakModeTailTruncation;
        _textColor = [[UIColor blackColor] retain];
        _font = [[UIFont systemFontOfSize:[UIFont labelFontSize]] retain];
        _enabled = YES;
        _numberOfLines = 1;
        _contentMode = UIViewContentModeLeft;
        self.clipsToBounds = YES;
        _shadowOffset = CGSizeMake(0,-1);
        _baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
        self.contentScaleFactor = _UIScreenMainScreen()->_scale;
    }
    //DLog(@"2");
    return self;
}

- (void)dealloc
{
    [_text release];
    [_font release];
    [_textColor release];
    [_font release];
    [_shadowColor release];
    [_highlightedTextColor release];
    [super dealloc];
}

#pragma mark - Accessors

- (void)setText:(NSString *)newText
{
    if (_text != newText) {
        [_text release];
        _text = [newText copy];
        _CALayerSetNeedsDisplay(_layer);
    }
}

- (void)setFont:(UIFont *)newFont
{
    //DLog();
    assert(newFont != nil);

    if (newFont != _font) {
        [_font release];
        _font = [newFont retain];
        _CALayerSetNeedsDisplay(_layer);
    }
}

- (void)setTextColor:(UIColor *)newColor
{
    //DLog();
    if (newColor != _textColor) {
        [_textColor release];
        _textColor = [newColor retain];
        _CALayerSetNeedsDisplay(_layer);
    }
}

- (void)setShadowColor:(UIColor *)newColor
{
    if (newColor != _shadowColor) {
        [_shadowColor release];
        _shadowColor = [newColor retain];
        _CALayerSetNeedsDisplay(_layer);
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    if (highlighted != _highlighted) {
        _highlighted = highlighted;
        _CALayerSetNeedsDisplay(_layer);
    }
}

- (void)setShadowOffset:(CGSize)newOffset
{
    if (!CGSizeEqualToSize(newOffset,_shadowOffset)) {
        _shadowOffset = newOffset;
        _CALayerSetNeedsDisplay(_layer);
    }
}

- (void)setTextAlignment:(UITextAlignment)newAlignment
{
    //DLog();
    if (newAlignment != _textAlignment) {
        _textAlignment = newAlignment;
        _CALayerSetNeedsDisplay(_layer);
    }
}

- (void)setLineBreakMode:(UILineBreakMode)newMode
{
    if (newMode != _lineBreakMode) {
        _lineBreakMode = newMode;
        _CALayerSetNeedsDisplay(_layer);
    }
}

- (void)setEnabled:(BOOL)newEnabled
{
    if (newEnabled != _enabled) {
        _enabled = newEnabled;
    }
}

- (void)setNumberOfLines:(NSInteger)lines
{
    if (lines != _numberOfLines) {
        _numberOfLines = lines;
        _CALayerSetNeedsDisplay(_layer);
    }
}

- (void)setFrame:(CGRect)newFrame
{
    const BOOL redisplay = !CGSizeEqualToSize(newFrame.size,self.frame.size);
    [super setFrame:newFrame];
    if (redisplay) {
        _CALayerSetNeedsDisplay(_layer);
    }
}

- (void)setAdjustsFontSizeToFitWidth:(BOOL)adjustsFontSizeToFitWidth
{
    if (adjustsFontSizeToFitWidth) {
        //DLog();
        CGSize boundsSize = self.bounds.size;
        //DLog();
        float fontSize = _font.pointSize;
        //DLog();
        UIFont *font = [UIFont fontWithName:_font.fontName size:fontSize];
        //DLog(@"_text: %@", _text);
        CGSize size = [_text sizeWithFont:_font];
        //DLog(@"size: %@", NSStringFromCGSize(size));
        //DLog(@"boundsSize: %@", NSStringFromCGSize(boundsSize));
        while (size.width > boundsSize.width) {
            fontSize--;
            //DLog(@"fontSize: %0.1f", fontSize);
            font = [UIFont fontWithName:_font.fontName size:fontSize];
            size = [_text sizeWithFont:font];
            //DLog(@"size: %@", NSStringFromCGSize(size));
            //DLog(@"font: %@", font);
        }
        self.font = font;
        //DLog();
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; text: %@; frame = %@; layer = %p>", [self className], self, _text, NSStringFromCGRect(self.frame), _layer];
}

#pragma mark - Overridden methods

- (void)drawRect:(CGRect)rect
{
    if ([_text length] > 0) {
        CGContext *context = UIGraphicsGetCurrentContext();
        CGContextSaveGState(context);
        
        const CGRect bounds = self.bounds;
        CGRect drawRect = CGRectZero;
        
        // find out the actual size of the text given the size of our bounds
        CGSize maxSize = bounds.size;
        if (_numberOfLines > 0) {
            maxSize.height = _font.lineHeight * _numberOfLines;
        }
        //DLog(@"_lineBreakMode: %d", _lineBreakMode);
        drawRect.size = [_text sizeWithFont:_font constrainedToSize:maxSize lineBreakMode:_lineBreakMode];

        // now vertically center it
        drawRect.origin.y = roundf((bounds.size.height - drawRect.size.height) / 2.f);
        // now position it correctly for the width
        // this might be cheating somehow and not how the real thing does it...
        // I didn't spend a ton of time investigating the sizes that it sends the drawTextInRect: method
        drawRect.origin.x = 0;
        drawRect.size.width = bounds.size.width;
        
        // if there's a shadow, let's set that up
        CGSize offset = _shadowOffset;
        offset.height *= -1;				// Need to verify this on Lion! The shadow direction reversed in iOS 4 (I think) which might
                                            // indicate a reversal is coming in 10.7 as well!
        CGContextSetShadowWithColor(context, offset, 0, _shadowColor.CGColor);
        
        // finally, draw the real label
        UIColor *drawColor = (_highlighted && _highlightedTextColor) ? _highlightedTextColor : _textColor;
        [drawColor setFill];
        [self drawTextInRect:drawRect];
        CGContextRestoreGState(context);
    }
}

#pragma mark - Public methods

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines
{
    if ([_text length] > 0) {
        CGSize maxSize = bounds.size;
        if (numberOfLines > 0) {
            maxSize.height = _font.lineHeight * numberOfLines;
        }
        //DLog(@"_lineBreakMode: %d", _lineBreakMode);
        CGSize size = [_text sizeWithFont:_font constrainedToSize:maxSize lineBreakMode:_lineBreakMode];
        return (CGRect){bounds.origin, size};
    }
    return (CGRect){bounds.origin, {0, 0}};
}

- (void)drawTextInRect:(CGRect)rect
{
    //DLog();
    [_text drawInRect:rect withFont:_font lineBreakMode:_lineBreakMode alignment:_textAlignment];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    size = CGSizeMake(((_numberOfLines > 0)? CGFLOAT_MAX : size.width), ((_numberOfLines <= 0)? CGFLOAT_MAX : (_font.lineHeight*_numberOfLines)));
    //DLog(@"_lineBreakMode: %d", _lineBreakMode);
    CGSize result = [_text sizeWithFont:_font constrainedToSize:size lineBreakMode:_lineBreakMode];
    return CGSizeMake(result.width+2, result.height+2);
}

@end

