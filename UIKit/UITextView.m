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

#import <UITextView.h>
#import <UIKit/UIColor.h>
#import <UIKit/UIFont.h>
#import <UIKit/UIScrollView.h>

NSString *const UITextViewTextDidBeginEditingNotification = @"UITextViewTextDidBeginEditingNotification";
NSString *const UITextViewTextDidChangeNotification = @"UITextViewTextDidChangeNotification";
NSString *const UITextViewTextDidEndEditingNotification = @"UITextViewTextDidEndEditingNotification";

//@interface UIScrollView () <UITextLayerContainerViewProtocol>
//@end

//@interface UITextView () <UITextLayerTextDelegate>
//@end


@implementation UITextView

@synthesize dataDetectorTypes=_dataDetectorTypes, inputAccessoryView=_inputAccessoryView, inputView=_inputView;
@synthesize editable = _editable;
@dynamic delegate;

- (id)initWithFrame:(CGRect)frame
{
    if ((self=[super initWithFrame:frame])) {
        _textLayer = [[CATextLayer alloc] initWithBounds:frame];
        [self.layer insertSublayer:_textLayer atIndex:0];

        _textColor = [[UIColor blackColor] retain];
        _font = [[UIFont systemFontOfSize:17] retain];
        _dataDetectorTypes = UIDataDetectorTypeAll;
        _editable = YES;
        _contentMode = UIViewContentModeScaleToFill;
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)dealloc
{
    [_textLayer removeFromSuperlayer];
    [_textLayer release];
    [_inputAccessoryView release];
    [_inputView release];
    [_textColor release];
    [_font release];
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _textLayer.frame = self.bounds;
}

- (void)setContentOffset:(CGPoint)theOffset animated:(BOOL)animated
{
    [super setContentOffset:theOffset animated:animated];
    [_textLayer setContentOffset:theOffset];
}

- (void)scrollRangeToVisible:(NSRange)range
{
    [_textLayer scrollRangeToVisible:range];
}

- (UITextAutocapitalizationType)autocapitalizationType
{
    return UITextAutocapitalizationTypeNone;
}

- (void)setAutocapitalizationType:(UITextAutocapitalizationType)type
{
}

- (UITextAutocorrectionType)autocorrectionType
{
    return UITextAutocorrectionTypeDefault;
}

- (void)setAutocorrectionType:(UITextAutocorrectionType)type
{
}

- (BOOL)enablesReturnKeyAutomatically
{
    return YES;
}

- (void)setEnablesReturnKeyAutomatically:(BOOL)enabled
{
}

- (UIKeyboardAppearance)keyboardAppearance
{
    return UIKeyboardAppearanceDefault;
}

- (void)setKeyboardAppearance:(UIKeyboardAppearance)type
{
}

- (UIKeyboardType)keyboardType
{
    return UIKeyboardTypeDefault;
}

- (void)setKeyboardType:(UIKeyboardType)type
{
}

- (UIReturnKeyType)returnKeyType
{
    return UIReturnKeyDefault;
}

- (void)setReturnKeyType:(UIReturnKeyType)type
{
}

- (BOOL)isSecureTextEntry
{
    return [_textLayer isSecureTextEntry];
}

- (void)setSecureTextEntry:(BOOL)secure
{
    [_textLayer setSecureTextEntry:secure];
}


- (BOOL)canBecomeFirstResponder
{
    return (self.window != nil);
}

- (BOOL)becomeFirstResponder
{
    if ([super becomeFirstResponder] ){
        return [_textLayer becomeFirstResponder];
    } else {
        return NO;
    }
}

- (BOOL)resignFirstResponder
{
    if ([super resignFirstResponder]) {
        return [_textLayer resignFirstResponder];
    } else {
        return NO;
    }
}

- (UIFont *)font
{
    return _textLayer.font;
}

- (void)setFont:(UIFont *)newFont
{
    _textLayer.font = newFont;
}

- (UIColor *)textColor
{
    return [UIColor colorWithCGColor:_textLayer.textColor];
}

- (void)setTextColor:(UIColor *)newColor
{
    _textLayer.textColor = newColor.CGColor;
}

- (UITextAlignment)textAlignment
{
    if ([_textLayer.alignmentMode isEqualToString:kCAAlignmentCenter]) {
        return UITextAlignmentCenter;
    } else if ([_textLayer.alignmentMode isEqualToString:kCAAlignmentLeft]) {
        return UITextAlignmentLeft;
    } else {
        return UITextAlignmentRight;
    }
}

- (void)setTextAlignment:(UITextAlignment)textAlignment
{
    if (textAlignment == UITextAlignmentCenter) {
        _textLayer.alignmentMode = kCAAlignmentCenter;
    } else if (textAlignment == UITextAlignmentLeft) {
        _textLayer.alignmentMode = kCAAlignmentLeft;
    } else {
        _textLayer.alignmentMode = kCAAlignmentRight;
    }
}

- (NSString *)text
{
    return _textLayer.string;
}

- (void)setText:(NSString *)newText
{
    _textLayer.string = newText;
}

- (NSRange)selectedRange
{
    return _textLayer.selectedRange;
}

- (void)setSelectedRange:(NSRange)range
{
    _textLayer.selectedRange = range;
}

- (BOOL)hasText
{
  return [_textLayer.string length] > 0;
}


- (void)setDelegate:(id<UITextViewDelegate>)theDelegate
{
    if (theDelegate != self.delegate) {
        [super setDelegate:theDelegate];
        _delegateHas.shouldBeginEditing = [theDelegate respondsToSelector:@selector(textViewShouldBeginEditing:)];
        _delegateHas.didBeginEditing = [theDelegate respondsToSelector:@selector(textViewDidBeginEditing:)];
        _delegateHas.shouldEndEditing = [theDelegate respondsToSelector:@selector(textViewShouldEndEditing:)];
        _delegateHas.didEndEditing = [theDelegate respondsToSelector:@selector(textViewDidEndEditing:)];
        _delegateHas.shouldChangeText = [theDelegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)];
        _delegateHas.didChange = [theDelegate respondsToSelector:@selector(textViewDidChange:)];
        _delegateHas.didChangeSelection = [theDelegate respondsToSelector:@selector(textViewDidChangeSelection:)];
    }
}


- (NSString *)description
{
    NSString *textAlignment = @"";
    switch (self.textAlignment) {
        case UITextAlignmentLeft:
            textAlignment = @"Left";
            break;
        case UITextAlignmentCenter:
            textAlignment = @"Center";
            break;
        case UITextAlignmentRight:
            textAlignment = @"Right";
            break;
    }
    return [NSString stringWithFormat:@"<%@: %p; textAlignment = %@; selectedRange = %@; editable = %@; textColor = %@; font = %@; delegate = %@>", [self className], self, textAlignment, NSStringFromRange(self.selectedRange), (self.editable ? @"YES" : @"NO"), self.textColor, self.font, self.delegate];
}



- (BOOL)_UITextViewTextShouldBeginEditing
{
    return _delegateHas.shouldBeginEditing? [self.delegate textViewShouldBeginEditing:self] : YES;
}

- (void)_UITextViewTextDidBeginEditing
{
    if (_delegateHas.didBeginEditing) {
        [self.delegate textViewDidBeginEditing:self];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidBeginEditingNotification object:self];
}

- (BOOL)_UITextViewTextShouldEndEditing
{
    return _delegateHas.shouldEndEditing? [self.delegate textViewShouldEndEditing:self] : YES;
}

- (void)_UITextViewTextDidEndEditing
{
    if (_delegateHas.didEndEditing) {
        [self.delegate textViewDidEndEditing:self];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidEndEditingNotification object:self];
}

- (BOOL)_UITextViewTextShouldChangeText:(NSString*)text inRange:(NSRange)range
{
    return _delegateHas.shouldChangeText? [self.delegate textView:self shouldChangeTextInRange:range replacementText:text] : YES;
}

-(void)_UITextViewTextDidChange
{
    if (_delegateHas.didChange) {
        [self.delegate textViewDidChange:self];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self];
}

-(void)_UITextViewTextDidChangeSelection
{
    if (_delegateHas.didChangeSelection) {
        [self.delegate textViewDidChangeSelection:self];
    }
}

@end

