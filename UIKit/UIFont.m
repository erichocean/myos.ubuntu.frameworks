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

#import <UIKit/UIFont.h>

static NSString *const UIFontSystemFontName = @"Helvetica";
static NSString *const UIFontBoldSystemFontName = @"Helvetica-Bold";

//UIFont *_UIFontGetFontWithCTFont(CTFontRef aFont);

#pragma mark - Static functions

static NSArray *_getFontCollectionNames(CTFontCollectionRef collection, CFStringRef nameAttr)
{
    NSMutableSet *names = [NSMutableSet set];
    if (collection) {
        CFArrayRef descriptors = CTFontCollectionCreateMatchingFontDescriptors(collection);
        if (descriptors) {
            NSInteger count = CFArrayGetCount(descriptors);
            for (NSInteger i = 0; i < count; i++) {
                CTFontDescriptorRef descriptor = (CTFontDescriptorRef) CFArrayGetValueAtIndex(descriptors, i);
                CFTypeRef name = CTFontDescriptorCopyAttribute(descriptor, nameAttr);
                if(name) {
                    if (CFGetTypeID(name) == CFStringGetTypeID()) {
                        [names addObject:(__bridge NSString*)name];
                    }
                    CFRelease(name);
                }
            }
            CFRelease(descriptors);
        }
    }
    return [names allObjects];
}

static UIFont *_UIFontGetFontWithCTFont(CTFontRef aFont)
{
    UIFont *theFont = [[UIFont alloc] init];
    theFont->_font = CFRetain(aFont);
    return [theFont autorelease];
}

@implementation UIFont

#pragma mark - Life cycle

- (id)initWithName:(NSString *)name size:(CGFloat)size
{
    //DLog();
    self = [super init];
    if (self) {
        //DLog(@"name: %@", name);
        //DLog(@"size: %@", NSStringFromCGSize(size));
        _font = CTFontCreateWithName(name, size, NULL);
    }
    return self;
}

- (void)dealloc
{
    CFRelease(_font);
    [super dealloc];
}

#pragma mark - Class methods

+ (UIFont *)fontWithName:(NSString *)fontName size:(CGFloat)fontSize
{
    return [[[UIFont alloc] initWithName:fontName size:fontSize] autorelease];
}

+ (NSArray *)familyNames
{
    CTFontCollectionRef collection = CTFontCollectionCreateFromAvailableFonts(NULL);
    NSArray* names = _getFontCollectionNames(collection, kCTFontFamilyNameAttribute);
    if (collection) {
        CFRelease(collection);
    }
    return names;
}

+ (NSArray *)fontNamesForFamilyName:(NSString *)familyName
{
    NSArray *names = nil;
    CTFontDescriptorRef descriptor = CTFontDescriptorCreateWithAttributes((__bridge CFDictionaryRef)
        [NSDictionary dictionaryWithObjectsAndKeys: familyName, (NSString*)kCTFontFamilyNameAttribute, nil, nil]);
    if (descriptor) {
        CFArrayRef descriptors = CFArrayCreate(NULL, (CFTypeRef*) &descriptor, 1, &kCFTypeArrayCallBacks);
        if (descriptors) {
            CTFontCollectionRef collection = CTFontCollectionCreateWithFontDescriptors(descriptors, NULL);
            names = _getFontCollectionNames(collection, kCTFontNameAttribute);
            if (collection) {
                CFRelease(collection);
            }
            CFRelease(descriptors);
        }
        CFRelease(descriptor);
    }
    return names;
}

+ (UIFont *)systemFontOfSize:(CGFloat)fontSize
{
    return [[[UIFont alloc] initWithName:UIFontSystemFontName size:fontSize] autorelease];
}

+ (UIFont *)boldSystemFontOfSize:(CGFloat)fontSize
{
    return [[[UIFont alloc] initWithName:UIFontBoldSystemFontName size:fontSize] autorelease];
}

+ (CGFloat)labelFontSize
{
    return 17.0;
}

+ (CGFloat)buttonFontSize
{
    return 20.0;
}

+ (CGFloat)smallSystemFontSize
{
    return 12.0;
}

+ (CGFloat)systemFontSize
{
    return 17.0;
}

#pragma mark - Accessors

- (NSString *)fontName
{
    return [(NSString *)CTFontCopyFullName(_font) autorelease];
}

- (CGFloat)ascender
{
    return CTFontGetAscent(_font);
}

- (CGFloat)descender
{
    return -CTFontGetDescent(_font);
}

- (CGFloat)pointSize
{
    return CTFontGetSize(_font);
}

- (CGFloat)xHeight
{
    return CTFontGetXHeight(_font);
}

- (CGFloat)capHeight
{
    return CTFontGetCapHeight(_font);
}

- (CGFloat)lineHeight
{
    // this seems to compute heights that are very close to what I'm seeing on iOS for fonts at
    // the same point sizes. however there's still subtle differences between fonts on the two
    // platforms (iOS and Mac) and I don't know if it's ever going to be possible to make things
    // return exactly the same values in all cases.
    return [self pointSize];
}

- (NSString *)familyName
{
    return [(NSString *)CTFontCopyFamilyName(_font) autorelease];
}

- (UIFont *)fontWithSize:(CGFloat)fontSize
{
    CTFontRef newFont = CTFontCreateCopyWithAttributes(_font, fontSize, NULL, NULL);
    if (newFont) {
        UIFont *theFont = _UIFontGetFontWithCTFont(newFont);
        CFRelease(newFont);
        return theFont;
    } else {
        return nil;
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; fontName: %@; pointSize: %0.0f>", [self className], self, self.fontName, self.pointSize];
}

@end
