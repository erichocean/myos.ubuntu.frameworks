/** <title>OPSimpleLayoutEngine</title>

   <abstract>C Interface to text layout library</abstract>

   Copyright <copy>(C) 2011 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen
   Date: Mar 2011

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   */

#import "OPSimpleLayoutEngine.h"
#import "CTRun-private.h"
#import <CoreText/CTFont.h>
#import <CoreText/CTStringAttributes.h>

@implementation OPSimpleLayoutEngine

- (CTRunRef)layoutString:(NSString *)chars withAttributes:(NSDictionary *)attribs
{
    const NSUInteger length = [chars length];
    CGGlyph *glyphs = malloc(sizeof(CGGlyph) * length);
    unichar *characters = malloc(sizeof(unichar) * length);
    CGSize *advances = malloc(sizeof(CGSize) * length);
    CTFontRef font = [attribs objectForKey: kCTFontAttributeName];
    if (font == nil) {
        NSLog(@"OPSimpleLayoutEngine: Error, layoutString:withAttributes: called without a font");
        DLog(@"attribs: %@", attribs);
        return nil;
    } else {
        [chars getCharacters:characters range:NSMakeRange(0, length)];
        int len = [chars length];
        for (int i=0; i<len; i++) {
            CFStringRef chr = CFStringCreateWithBytes (NULL, (unsigned char*)(&characters[i]), 1, kCFStringEncodingUTF8, false);
            glyphs[i] = CTFontGetGlyphWithName(font, chr);
            CFRelease(chr);
        }
        
        CTFontGetAdvancesForGlyphs(font,
                                   kCTFontDefaultOrientation,
                                   glyphs,
                                   advances,
                                   length);
    }
    CTRunRef run = [[[CTRun alloc ] initWithGlyphs:glyphs advances:advances range:CFRangeMake(0, length) attributes:attribs] autorelease];
    free(glyphs);
    free(characters);
    free(advances);
    return run;
}

@end

