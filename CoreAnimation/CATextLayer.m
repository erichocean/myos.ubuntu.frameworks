/*
 Copyright © 2014 myOS Group.
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 Lesser General Public License for more details.
 
 Contributor(s):
 Amr Aboelela <amraboelela@gmail.com>
 */

#import "CATextLayer.h"
#import <CoreText/CoreText.h>
#import <CoreFoundation/CFAttributedString.h>

NSString *const kCATruncationNone = @"CATruncationNone";
NSString *const kCATruncationStart = @"CATruncationStart";
NSString *const kCATruncationEnd = @"CATruncationEnd";
NSString *const kCATruncationMiddle = @"CATruncationMiddle";

NSString *const kCAAlignmentNatural = @"CAAlignmentNatural";
NSString *const kCAAlignmentLeft = @"CAAlignmentLeft";
NSString *const kCAAlignmentRight = @"CAAlignmentRight";
NSString *const kCAAlignmentCenter = @"CAAlignmentCenter";
NSString *const kCAAlignmentJustified = @"CAAlignmentJustified";

static CGFloat CTFontGetLineHeight(CTFontRef theFont)
{
	CGFloat ascent = CTFontGetAscent(theFont);
	CGFloat descent = CTFontGetDescent(theFont);
	CGFloat leading = CTFontGetLeading(theFont);
	if (leading < 0) {
        leading = 0;
    }
	leading = floor(leading + 0.5);
	CGFloat lineHeight = floor(ascent + 0.5) + floor(descent + 0.5) + leading;
	CGFloat ascenderDelta;
	if (leading > 0) {
        ascenderDelta = 0;
    } else {
        ascenderDelta = floor(0.2 * lineHeight + 0.5);
    }
	CGFloat defaultLineHeight = lineHeight + ascenderDelta;
	return defaultLineHeight;
}

static CFArrayRef CreateCTLinesForAttributedString(NSAttributedString *attributedString, CGSize constrainedToSize, NSString *lineBreakMode, CGSize *renderSize)
{
    CFMutableArrayRef lines = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
    CGSize drawSize = CGSizeZero;
    CTFontRef fontRef = CFAttributedStringGetAttribute(attributedString, 0, kCTFontAttributeName, NULL);
    if (attributedString && fontRef) {
        CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString(attributedString);
        const CFIndex stringLength = CFAttributedStringGetLength(attributedString);
        const CGFloat lineHeight = CTFontGetLineHeight(fontRef);
        const CGFloat capHeight = CTFontGetCapHeight(fontRef);
        CFIndex start = 0;
        BOOL isLastLine = NO;
        while (start < stringLength && !isLastLine) {
            drawSize.height += lineHeight;
            isLastLine = (drawSize.height+capHeight >= constrainedToSize.height);
            CFIndex usedCharacters = 0;
            CTLineRef line = NULL;
            if (isLastLine) {
				CTLineTruncationType truncType;
				if ([lineBreakMode isEqualToString:kCATruncationStart]) {
					truncType = kCTLineTruncationStart;
				} else if ([lineBreakMode isEqualToString:kCATruncationEnd]) {
					truncType = kCTLineTruncationEnd;
				} else {
					truncType = kCTLineTruncationMiddle;
				}
				usedCharacters = stringLength - start;
				// revise ellipsisString
				CFMutableDictionaryRef attributes = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
				CFAttributedStringRef ellipsisString = CFAttributedStringCreate(NULL, CFSTR("…"), attributes);
                CTLineRef ellipsisLine = CTLineCreateWithAttributedString(ellipsisString);
                CTLineRef tempLine = CTTypesetterCreateLine(typesetter, CFRangeMake(start, usedCharacters));
                line = CTLineCreateTruncatedLine(tempLine, constrainedToSize.width, truncType, ellipsisLine);
                CFRelease(tempLine);
                CFRelease(ellipsisLine);
                CFRelease(ellipsisString);
                CFRelease(attributes);
            } else {
                //DLog();
                usedCharacters = CTTypesetterSuggestLineBreak(typesetter, start, constrainedToSize.width);
                line = CTTypesetterCreateLine(typesetter, CFRangeMake(start, usedCharacters));
            }
            if (line) {
                drawSize.width = MAX(drawSize.width, ceilf(CTLineGetTypographicBounds(line,NULL,NULL,NULL)));
                //DLog(@"drawSize.width: %0.1f", drawSize.width);
                CFArrayAppendValue(lines, line);
                CFRelease(line);
            }
            start += usedCharacters;
        }
        CFRelease(typesetter);
    }
    if (renderSize) {
        *renderSize = drawSize;
    }
    return lines;
}

static CFArrayRef CreateCTLinesForString(NSString *string, CGSize constrainedToSize, CTFontRef font, CGColorRef textColor, NSString *lineBreakMode, CGSize *renderSize)
{
    CFAttributedStringRef attributedString;
    CFArrayRef lines;
    if (font) {
        CFMutableDictionaryRef attributes = CFDictionaryCreateMutable(NULL, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(attributes, kCTFontAttributeName, font);
        CFDictionarySetValue(attributes, kCTForegroundColorAttributeName, textColor);
        attributedString = CFAttributedStringCreate(NULL, (__bridge CFStringRef)string, attributes);
        lines = CreateCTLinesForAttributedString(attributedString, constrainedToSize, lineBreakMode, renderSize);
        CFRelease(attributes);
        CFRelease(attributedString);
    }
    return lines;
}

@implementation CATextLayer

@synthesize string;
@synthesize font;
@synthesize fontSize;
@synthesize textColor = foregroundColor;
@synthesize wrapped;
@synthesize alignmentMode;
@synthesize truncationMode;
@synthesize secureTextEntry;
@synthesize selectedRange;

#pragma mark - Life cycle

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		font = CFSTR("Helvetica");
		fontSize = 36.0;
		foregroundColor = CGColorCreateGenericRGB(1, 1, 1, 1); //white
		wrapped = NO;
		alignmentMode = [kCAAlignmentNatural copy];
		truncationMode = [kCATruncationNone copy];

	}
	return self;
}

- (void)dealloc
{
	[string release];
	[alignmentMode release];
	[truncationMode release];
	[super dealloc];
}

#pragma mark - Overriden methods

- (void)drawInContext:(CGContextRef)ctx
{
    //DLog();
    CGContextSaveGState(ctx);
    CGSize actualSize = CGSizeZero;
    CFArrayRef lines = nil;
    if ([string isKindOfClass:[NSAttributedString class]]) {
        //TFB used here with NSAttributedString
        // FIXME lines = CreateCTLinesForAttributedString((__bridge CFAttributedString *)string, self.frame.size, truncationMode, &actualSize);
    } else {
        CTFontRef _font;
        if (CFGetTypeID(font) == CFStringGetTypeID()) {
            _font = CTFontCreateWithName(font, fontSize, NULL);
        } else if (CFGetTypeID(font) == CGFontGetTypeID()) {
            _font = CTFontCreateWithGraphicsFont(font, fontSize, NULL, NULL);
        } else if (CFGetTypeID(font) == CTFontGetTypeID()) {
            _font = font;
        }
        DLog();
        lines = CreateCTLinesForString(string, self.frame.size, _font, foregroundColor, truncationMode, &actualSize);
    }
    if (lines) {
        const CFIndex numberOfLines = CFArrayGetCount(lines);
        const CGFloat fontlineHeight = actualSize.height / numberOfLines;
        CGFloat textOffset = 0;
        for (CFIndex lineNumber = 0; lineNumber < numberOfLines; ++lineNumber) {
            CTLineRef line = CFArrayGetValueAtIndex(lines, lineNumber);
            CGFloat penOffset = CTLineGetPenOffsetForFlush(line, 0, self.frame.size.width);
            CGContextSetTextPosition(ctx, penOffset, textOffset);
            CTLineDraw(line, ctx);
            textOffset += fontlineHeight;
        }
    }
    CGContextRestoreGState(ctx);
    CFRelease(lines);
    
    [super drawInContext:ctx];
}

@end

