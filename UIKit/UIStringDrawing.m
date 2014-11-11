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

#import <UIKit/UIStringDrawing.h>
#import <UIKit/UIFont.h>

static CFArrayRef CreateCTLinesForString(NSString *string, CGSize constrainedToSize, UIFont *font, UILineBreakMode lineBreakMode, CGSize *renderSize)
{
    //DLog(@"string: %@", string);
    CFMutableArrayRef lines = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
    CGSize drawSize = CGSizeZero;
    if (font) {
        CFMutableDictionaryRef attributes = CFDictionaryCreateMutable(NULL, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(attributes, kCTFontAttributeName, font->_font);
        CFDictionarySetValue(attributes, kCTForegroundColorFromContextAttributeName, kCFBooleanTrue);
        
        //NSAttributedString * attributedString = CFAttributedStringCreate(NULL, (__bridge CFStringRef)string, attributes);
        //TODO uncomment the previous line when memory issue is done.
        CFStringRef tmpStr = CFStringCreateWithCString(NULL, [string UTF8String], kCFStringEncodingUTF8);
        NSAttributedString *attributedString = CFAttributedStringCreate(NULL, tmpStr, attributes);
        CFRelease(tmpStr);
        //////////////Work around

        CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString(attributedString);
        
        const CFIndex stringLength = CFAttributedStringGetLength(attributedString);
        const CGFloat lineHeight = font.lineHeight;
        //const CGFloat capHeight = font.capHeight;
        //DLog(@"capHeight %f", capHeight);
        //DLog(@"lineHeight %f", lineHeight);
        //DLog(@"stringLength %d", stringLength);
        //DLog(@"constrainedToSize: %@", NSStringFromCGSize(constrainedToSize));
        CFIndex start = 0;
        BOOL isLastLine = NO;
        
        while (start < stringLength && !isLastLine) {
            //DLog(@"start: %d", start);
            drawSize.height += lineHeight;
            isLastLine = (drawSize.height+lineHeight >= constrainedToSize.height);
            //DLog(@"isLastLine: %d", isLastLine);
            //DLog(@"lineBreakMode: %d", lineBreakMode);
            CFIndex usedCharacters = 0;
            CTLineRef line = NULL;
            //DLog(@"2");
            
            if (isLastLine && (lineBreakMode != UILineBreakModeWordWrap && lineBreakMode != UILineBreakModeCharacterWrap)) {
                //DLog(@"2");
                if (lineBreakMode == UILineBreakModeClip) {
                    usedCharacters = CTTypesetterSuggestClusterBreak(typesetter, start, constrainedToSize.width);
                    line = CTTypesetterCreateLine(typesetter, CFRangeMake(start, usedCharacters));
                } else {
                    CTLineTruncationType truncType;
                    if (lineBreakMode == UILineBreakModeHeadTruncation) {
                        truncType = kCTLineTruncationStart;
                    } else if (lineBreakMode == UILineBreakModeTailTruncation) {
                        truncType = kCTLineTruncationEnd;
                    } else {
                        truncType = kCTLineTruncationMiddle;
                    }
                    //DLog(@"3");
                    usedCharacters = stringLength - start;
                    //DLog(@"usedCharacters: %d", usedCharacters);
                    NSAttributedString *ellipsisString = CFAttributedStringCreate(NULL, CFSTR("..."), attributes);
                    CTLineRef ellipsisLine = CTLineCreateWithAttributedString(ellipsisString);
                    CTLineRef tempLine = CTTypesetterCreateLine(typesetter, CFRangeMake(start, usedCharacters));
                    line = CTLineCreateTruncatedLine(tempLine, constrainedToSize.width, truncType, ellipsisLine);
                    CFRelease(tempLine);
                    CFRelease(ellipsisLine);
                    CFRelease(ellipsisString);
                }
            } else {
                //DLog(@"4");
                if (lineBreakMode == UILineBreakModeCharacterWrap) {
                    //DLog(@"4.1");
                    usedCharacters = CTTypesetterSuggestClusterBreak(typesetter, start, constrainedToSize.width);
                } else {
                    //DLog(@"4.2");
                    usedCharacters = CTTypesetterSuggestLineBreak(typesetter, start, constrainedToSize.width);
                }
                // FIXME
                if (usedCharacters == 0) {
                    //lineBreakMode = UILineBreakModeTailTruncation;
                    usedCharacters = 7;
                    break;
                }
                //DLog(@"start: %d, usedCharacters: %d", start, usedCharacters);
                line = CTTypesetterCreateLine(typesetter, CFRangeMake(start, usedCharacters));
            }
            //DLog(@"line: %@", line);
            if (line) {
                drawSize.width = MAX(drawSize.width, ceilf(CTLineGetTypographicBounds(line,NULL,NULL,NULL)));
                CFArrayAppendValue(lines, line);
                CFRelease(line);
            }
            start += usedCharacters;
        }
        //DLog(@"6");
        CFRelease(typesetter);
        CFRelease(attributedString);
        CFRelease(attributes);
    }
    //DLog(@"7");
    if (renderSize) {
        *renderSize = drawSize;
    }
    //DLog(@"8");
    return lines;
}

@implementation NSString (UIStringDrawing)

- (CGSize)sizeWithFont:(UIFont *)font
{
    return [self sizeWithFont:font constrainedToSize:CGSizeMake(CGFLOAT_MAX,font.lineHeight)];
}

- (CGSize)sizeWithFont:(UIFont *)font forWidth:(CGFloat)width lineBreakMode:(UILineBreakMode)lineBreakMode
{
    return [self sizeWithFont:font constrainedToSize:CGSizeMake(width,font.lineHeight) lineBreakMode:lineBreakMode];
}

- (CGSize)sizeWithFont:(UIFont *)font minFontSize:(CGFloat)minFontSize actualFontSize:(CGFloat *)actualFontSize forWidth:(CGFloat)width lineBreakMode:(UILineBreakMode)lineBreakMode
{
    return CGSizeZero;
}

- (CGSize)sizeWithFont:(UIFont *)font constrainedToSize:(CGSize)size lineBreakMode:(UILineBreakMode)lineBreakMode
{
    CGSize resultingSize = CGSizeZero;
    //DLog(@"size: %@", NSStringFromCGSize(size));
    CFArrayRef lines = CreateCTLinesForString(self, size, font, lineBreakMode, &resultingSize);
    //DLog(@"2");
    if (lines) {
        CFRelease(lines);
    }
    //DLog(@"resultingSize: %@", NSStringFromCGSize(resultingSize));
    return resultingSize;
}

- (CGSize)sizeWithFont:(UIFont *)font constrainedToSize:(CGSize)size
{
    //DLog(@"size: %@", NSStringFromCGSize(size));
    return [self sizeWithFont:font constrainedToSize:size lineBreakMode:UILineBreakModeWordWrap];
}

- (CGSize)drawAtPoint:(CGPoint)point withFont:(UIFont *)font
{
    return [self drawAtPoint:point forWidth:CGFLOAT_MAX withFont:font lineBreakMode:UILineBreakModeWordWrap];
}

- (CGSize)drawAtPoint:(CGPoint)point forWidth:(CGFloat)width withFont:(UIFont *)font minFontSize:(CGFloat)minFontSize actualFontSize:(CGFloat *)actualFontSize lineBreakMode:(UILineBreakMode)lineBreakMode baselineAdjustment:(UIBaselineAdjustment)baselineAdjustment
{
    return CGSizeZero;
}

- (CGSize)drawAtPoint:(CGPoint)point forWidth:(CGFloat)width withFont:(UIFont *)font fontSize:(CGFloat)fontSize lineBreakMode:(UILineBreakMode)lineBreakMode baselineAdjustment:(UIBaselineAdjustment)baselineAdjustment
{
    UIFont *adjustedFont = ([font pointSize] != fontSize)? [font fontWithSize:fontSize] : font;
    return [self drawInRect:CGRectMake(point.x,point.y,width,adjustedFont.lineHeight) withFont:adjustedFont lineBreakMode:lineBreakMode];
}

- (CGSize)drawAtPoint:(CGPoint)point forWidth:(CGFloat)width withFont:(UIFont *)font lineBreakMode:(UILineBreakMode)lineBreakMode
{
    return [self drawAtPoint:point forWidth:width withFont:font fontSize:[font pointSize] lineBreakMode:lineBreakMode baselineAdjustment:UIBaselineAdjustmentNone];
}
 
- (CGSize)drawInRect:(CGRect)rect withFont:(UIFont *)font lineBreakMode:(UILineBreakMode)lineBreakMode alignment:(UITextAlignment)alignment
{
    //DLog();
    CGSize actualSize = CGSizeZero;
    CFArrayRef lines = CreateCTLinesForString(self,rect.size,font,lineBreakMode,&actualSize);
    if (lines) {
        const CFIndex numberOfLines = CFArrayGetCount(lines);
        const CGFloat fontLineHeight = font.lineHeight;
        CGFloat textOffset = 0;

        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSaveGState(ctx);
        CGContextTranslateCTM(ctx, rect.origin.x, rect.origin.y+font.ascender);
        CGContextSetTextMatrix(ctx, CGAffineTransformMakeScale(1,-1));
        
        for (CFIndex lineNumber=0; lineNumber<numberOfLines; lineNumber++) {
            CTLineRef line = CFArrayGetValueAtIndex(lines, lineNumber);
            float flush;
            switch (alignment) {
                case UITextAlignmentCenter:	flush = 0.5;	break;
                case UITextAlignmentRight:	flush = 1;		break;
                case UITextAlignmentLeft:
                default:					flush = 0;		break;
            }
            
            CGFloat penOffset = CTLineGetPenOffsetForFlush(line, flush, rect.size.width);
            CGContextSetTextPosition(ctx, penOffset, textOffset);
            CTLineDraw(line, ctx);
            textOffset += fontLineHeight;
        }

        CGContextRestoreGState(ctx);

        CFRelease(lines);
    }

    // the real UIKit appears to do this.. so shall we.
    actualSize.height = MIN(actualSize.height, rect.size.height);

    return actualSize;
}

- (CGSize)drawInRect:(CGRect)rect withFont:(UIFont *)font
{
    return [self drawInRect:rect withFont:font lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentLeft];
}

- (CGSize)drawInRect:(CGRect)rect withFont:(UIFont *)font lineBreakMode:(UILineBreakMode)lineBreakMode
{
    return [self drawInRect:rect withFont:font lineBreakMode:lineBreakMode alignment:UITextAlignmentLeft];
}

@end
