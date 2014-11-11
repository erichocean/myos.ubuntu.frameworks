/** <title>CTNSFont</title>

   <abstract>The font class</abstract>

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: February 1997
   A completely rewritten version of the original source by Scott Christley.

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#import <Foundation/NSAffineTransform.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSException.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSValue.h>

//#import <CoreGraphics/StandardGlyphNames.h>

#import "OPFreeTypeUtil.h"
#import "CTNSFont.h"

#define REAL_SIZE(x) CGFloatFromFontUnits(x, [_descriptor pointSize], ft_face->units_per_EM)

// FIXME: This definitions need to be ammended to take vertical typesetting into
// account.
#define TRANSFORMED_SIZE(x,y)\
  ((CGSize)(CGSizeApplyAffineTransform(CGSizeMake(REAL_SIZE(x), REAL_SIZE(y)), _matrix.CGTransform)))

#define TRANSFORMED_POINT(x,y)\
  ((CGPoint)(CGPointApplyAffineTransform(CGPointMake(REAL_SIZE(x), REAL_SIZE(y)), _matrix.CGTransform)))

#define TRANSFORMED_RECT(x,y,w,h)\
  ((CGRect)(CGRectApplyAffineTransform(CGRectMake(REAL_SIZE(x), REAL_SIZE(y), REAL_SIZE(w), REAL_SIZE(h)), _matrix.CGTransform)))

const CGFloat *CTNSFontIdentityMatrix;

//static CFDictionaryRef StandardGlyphNamesDictionary;
static NSDictionary * StandardGlyphNamesDictionary;

@implementation CTNSFont

+ (void)load
{
  static CGFloat identity[6] = {1.0, 0.0, 1.0, 0.0, 0.0, 0.0};
  CTNSFontIdentityMatrix = identity;
  //StandardGlyphNamesDictionary = CFDictionaryCreate (NULL, StandardGlyphNamesKeys, StandardGlyphNames, 258, NULL, NULL);
}

//
// Querying the Font
//
- (NSRect) boundingRectForFont
{
  return NSMakeRect(0,0,0,0);
}

- (NSString*) displayName
{
  return familyName;
}

- (NSString*) familyName
{
    return familyName;
}

- (NSString*) fontName
{
    return fontName;
}

- (BOOL) isFixedPitch
{
  return isFixedPitch;
}

- (const CGFloat*) matrix
{
  return _matrix.PSMatrix;
}

- (NSAffineTransform*) textTransform
{
  // FIXME: Need to implement bridging between CTNSFontMatrixAttribute and kCTFontMatrixAttribute somewhere
  NSAffineTransform *transform = [NSAffineTransform transform];
  [transform setTransformStruct: _matrix.NSTransform];
  return transform;
}

- (CGFloat) pointSize
{
  return [[[self fontDescriptor] objectForKey: kCTFontSizeAttribute] doubleValue];
}

- (CTNSFont*) printerFont
{
  return nil;
}

- (CTNSFont*) screenFont
{
  return nil;
}

- (CGFloat) ascender
{
  return ascender;
}

- (CGFloat) descender
{
  return descender;
}

- (CGFloat) capHeight
{
  return capHeight;
}

- (CGFloat) italicAngle
{
    return italicAngle;
}

- (CGFloat) leading
{
    return leading;
}

- (NSSize) maximumAdvancement
{
    return NSMakeSize(0,0);
}

- (CGFloat) underlinePosition
{
    return underlinePosition;
}

- (CGFloat) underlineThickness
{
    return underlineThickness;
}

- (CGFloat) xHeight
{
    return xHeight;
}

- (NSUInteger) numberOfGlyphs
{
    return numberOfGlyphs;
}

- (NSCharacterSet*) coveredCharacterSet
{
    return [[self fontDescriptor] objectForKey: kCTFontCharacterSetAttribute];
}

- (CTNSFontDescriptor*) fontDescriptor
{
    return _descriptor;
}

- (CTNSFontRenderingMode) renderingMode
{
    return 0;
}

- (CTNSFont*) screenFontWithRenderingMode: (CTNSFontRenderingMode)mode
{
    return nil;
}

//
// Manipulating Glyphs
//
- (CGSize)advancementForGlyph: (CGGlyph)glyph
{
    if ((NSNullGlyph == glyph) || (NSControlGlyph == glyph)) {
        return CGSizeMake(0,0);
    }
    
    FT_Face ft_face = cairo_ft_scaled_font_lock_face(_descriptor->cairofont);
    
    FT_Load_Glyph(ft_face, glyph, FT_LOAD_NO_SCALE);
    CGSize size = CGSizeMake(REAL_SIZE(ft_face->glyph->metrics.horiAdvance),
                             REAL_SIZE(ft_face->glyph->metrics.vertAdvance));
    
    cairo_ft_scaled_font_unlock_face(_descriptor->cairofont);
    
    return size;
    /*
     * FIXME: Add fast path for integer rendering modes. We don't need to do
     * so many integer->float conversions then.
     */
}

- (CGRect) boundingRectForGlyph: (CGGlyph)aGlyph
{
    FT_Face ft_face = cairo_ft_scaled_font_lock_face(_descriptor->cairofont);
    
    FT_Load_Glyph(ft_face, aGlyph, FT_LOAD_NO_SCALE);
    FT_Glyph_Metrics m = ft_face->glyph->metrics;
    CGRect bbox = CGRectMake(m.horiBearingX, m.horiBearingY - m.height, m.width, m.height);
    
    cairo_ft_scaled_font_unlock_face(_descriptor->cairofont);
    
    return bbox;
}

- (void) getAdvancements: (CGSize [])advancements
               forGlyphs: (const CGGlyph [])glyphs
                   count: (NSUInteger)count
{
    CGSize nullSize = CGSizeMake(0,0);
    for (int i = 0; i < count; i++) {
        if ((NSNullGlyph == glyphs[i]) || (NSControlGlyph == glyphs[i])) {
            advancements[i] = nullSize;
        } else {
            //TODO: Optimize if too slow.
            advancements[i] = [self advancementForGlyph: glyphs[i]];
        }
    }
}

- (void) getAdvancements: (CGSize [])advancements
         forPackedGlyphs: (const void*)packedGlyphs
                  length: (NSUInteger)count
{
}

- (void) getBoundingRects: (CGRect [])boundingRects
                forGlyphs: (const CGGlyph [])glyphs
                    count: (NSUInteger)count
{
    for (int i = 0; i < count; i++) {
        if ((NSNullGlyph == glyphs[i]) || (NSControlGlyph == glyphs[i])) {
            boundingRects[i] = CGRectZero;
        } else {
            //TODO: Optimize if too slow.
            boundingRects[i] = [self boundingRectForGlyph:glyphs[i]];
        }
    }
}

- (FT_String*)glyphNameForKey:(NSString*)glyphKey
{
    if (!StandardGlyphNamesDictionary) {
        NSString * _StandardGlyphNames[258] = {
            @".notdef",
            @".null",
            @"nonmarkingreturn",
            @"space",
            @"exclam",
            @"quotedbl",
            @"numbersign",
            @"dollar",
            @"percent",
            @"ampersand",
            @"quotesingle",
            @"parenleft",
            @"parenright",
            @"asterisk",
            @"plus",
            @"comma",
            @"hyphen",
            @"period",
            @"slash",
            @"zero",
            @"one",
            @"two",
            @"three",
            @"four",
            @"five",
            @"six",
            @"seven",
            @"eight",
            @"nine",
            @"colon",
            @"semicolon",
            @"less",
            @"equal",
            @"greater",
            @"question",
            @"at",
            @"A",
            @"B",
            @"C",
            @"D",
            @"E",
            @"F",
            @"G",
            @"H",
            @"I",
            @"J",
            @"K",
            @"L",
            @"M",
            @"N",
            @"O",
            @"P",
            @"Q",
            @"R",
            @"S",
            @"T",
            @"U",
            @"V",
            @"W",
            @"X",
            @"Y",
            @"Z",
            @"bracketleft",
            @"backslash",
            @"bracketright",
            @"asciicircum",
            @"underscore",
            @"grave",
            @"a",
            @"b",
            @"c",
            @"d",
            @"e",
            @"f",
            @"g",
            @"h",
            @"i",
            @"j",
            @"k",
            @"l",
            @"m",
            @"n",
            @"o",
            @"p",
            @"q",
            @"r",
            @"s",
            @"t",
            @"u",
            @"v",
            @"w",
            @"x",
            @"y",
            @"z",
            @"braceleft",
            @"bar",
            @"braceright",
            @"asciitilde",
            @"Adieresis",
            @"Aring",
            @"Ccedilla",
            @"Eacute",
            @"Ntilde",
            @"Odieresis",
            @"Udieresis",
            @"aacute",
            @"agrave",
            @"acircumflex",
            @"adieresis",
            @"atilde",
            @"aring",
            @"ccedilla",
            @"eacute",
            @"egrave",
            @"ecircumflex",
            @"edieresis",
            @"iacute",
            @"igrave",
            @"icircumflex",
            @"idieresis",
            @"ntilde",
            @"oacute",
            @"ograve",
            @"ocircumflex",
            @"odieresis",
            @"otilde",
            @"uacute",
            @"ugrave",
            @"ucircumflex",
            @"udieresis",
            @"dagger",
            @"degree",
            @"cent",
            @"sterling",
            @"section",
            @"bullet",
            @"paragraph",
            @"germandbls",
            @"registered",
            @"copyright",
            @"trademark",
            @"acute",
            @"dieresis",
            @"notequal",
            @"AE",
            @"Oslash",
            @"infinity",
            @"plusminus",
            @"lessequal",
            @"greaterequal",
            @"yen",
            @"mu",
            @"partialdiff",
            @"summation",
            @"product",
            @"pi",
            @"integral",
            @"ordfeminine",
            @"ordmasculine",
            @"Omega",
            @"ae",
            @"oslash",
            @"questiondown",
            @"exclamdown",
            @"logicalnot",
            @"radical",
            @"florin",
            @"approxequal",
            @"Delta",
            @"guillemotleft",
            @"guillemotright",
            @"ellipsis",
            @"nonbreakingspace",
            @"Agrave",
            @"Atilde",
            @"Otilde",
            @"OE",
            @"oe",
            @"endash",
            @"emdash",
            @"quotedblleft",
            @"quotedblright",
            @"quoteleft",
            @"quoteright",
            @"divide",
            @"lozenge",
            @"ydieresis",
            @"Ydieresis",
            @"fraction",
            @"currency",
            @"guilsinglleft",
            @"guilsinglright",
            @"fi",
            @"fl",
            @"daggerdbl",
            @"periodcentered",
            @"quotesinglbase",
            @"quotedblbase",
            @"perthousand",
            @"Acircumflex",
            @"Ecircumflex",
            @"Aacute",
            @"Edieresis",
            @"Egrave",
            @"Iacute",
            @"Icircumflex",
            @"Idieresis",
            @"Igrave",
            @"Oacute",
            @"Ocircumflex",
            @"apple",
            @"Ograve",
            @"Uacute",
            @"Ucircumflex",
            @"Ugrave",
            @"dotlessi",
            @"circumflex",
            @"tilde",
            @"macron",
            @"breve",
            @"dotaccent",
            @"ring",
            @"cedilla",
            @"hungarumlaut",
            @"ogonek",
            @"caron",
            @"Lslash",
            @"lslash",
            @"Scaron",
            @"scaron",
            @"Zcaron",
            @"zcaron",
            @"brokenbar",
            @"Eth",
            @"eth",
            @"Yacute",
            @"yacute",
            @"Thorn",
            @"thorn",
            @"minus",
            @"multiply",
            @"onesuperior",
            @"twosuperior",
            @"threesuperior",
            @"onehalf",
            @"onequarter",
            @"threequarters",
            @"franc",
            @"Gbreve",
            @"gbreve",
            @"Idotaccent",
            @"Scedilla",
            @"scedilla",
            @"Cacute",
            @"cacute",
            @"Ccaron",
            @"ccaron",
            @"dcroat"
        };
        NSString * _StandardGlyphNamesKeys[258] = {
            @".notdef",
            @".null",
            @"nonmarkingreturn",
            @" ",
            @"!",
            @"\"",
            @"#",
            @"$",
            @"%",
            @"&",
            @"'",
            @"(",
            @")",
            @"*",
            @"+",
            @",",
            @"-",
            @".",
            @"\\",
            @"0",
            @"1",
            @"2",
            @"3",
            @"4",
            @"5",
            @"6",
            @"7",
            @"8",
            @"9",
            @":",
            @";",
            @"<",
            @"=",
            @">",
            @"?",
            @"@",
            @"A",
            @"B",
            @"C",
            @"D",
            @"E",
            @"F",
            @"G",
            @"H",
            @"I",
            @"J",
            @"K",
            @"L",
            @"M",
            @"N",
            @"O",
            @"P",
            @"Q",
            @"R",
            @"S",
            @"T",
            @"U",
            @"V",
            @"W",
            @"X",
            @"Y",
            @"Z",
            @"bracketleft",
            @"backslash",
            @"bracketright",
            @"asciicircum",
            @"_",
            @"grave",
            @"a",
            @"b",
            @"c",
            @"d",
            @"e",
            @"f",
            @"g",
            @"h",
            @"i",
            @"j",
            @"k",
            @"l",
            @"m",
            @"n",
            @"o",
            @"p",
            @"q",
            @"r",
            @"s",
            @"t",
            @"u",
            @"v",
            @"w",
            @"x",
            @"y",
            @"z",
            @"braceleft",
            @"bar",
            @"braceright",
            @"asciitilde",
            @"Adieresis",
            @"Aring",
            @"Ccedilla",
            @"Eacute",
            @"Ntilde",
            @"Odieresis",
            @"Udieresis",
            @"aacute",
            @"agrave",
            @"acircumflex",
            @"adieresis",
            @"atilde",
            @"aring",
            @"ccedilla",
            @"eacute",
            @"egrave",
            @"ecircumflex",
            @"edieresis",
            @"iacute",
            @"igrave",
            @"icircumflex",
            @"idieresis",
            @"ntilde",
            @"oacute",
            @"ograve",
            @"ocircumflex",
            @"odieresis",
            @"otilde",
            @"uacute",
            @"ugrave",
            @"ucircumflex",
            @"udieresis",
            @"dagger",
            @"degree",
            @"cent",
            @"sterling",
            @"section",
            @"bullet",
            @"paragraph",
            @"germandbls",
            @"registered",
            @"copyright",
            @"trademark",
            @"acute",
            @"dieresis",
            @"notequal",
            @"AE",
            @"Oslash",
            @"infinity",
            @"plusminus",
            @"lessequal",
            @"greaterequal",
            @"yen",
            @"mu",
            @"partialdiff",
            @"summation",
            @"product",
            @"pi",
            @"integral",
            @"ordfeminine",
            @"ordmasculine",
            @"Omega",
            @"ae",
            @"oslash",
            @"questiondown",
            @"exclamdown",
            @"logicalnot",
            @"radical",
            @"florin",
            @"approxequal",
            @"Delta",
            @"guillemotleft",
            @"guillemotright",
            @"ellipsis",
            @"nonbreakingspace",
            @"Agrave",
            @"Atilde",
            @"Otilde",
            @"OE",
            @"oe",
            @"endash",
            @"emdash",
            @"quotedblleft",
            @"quotedblright",
            @"quoteleft",
            @"quoteright",
            @"divide",
            @"lozenge",
            @"ydieresis",
            @"Ydieresis",
            @"fraction",
            @"currency",
            @"guilsinglleft",
            @"guilsinglright",
            @"fi",
            @"fl",
            @"daggerdbl",
            @"periodcentered",
            @"quotesinglbase",
            @"quotedblbase",
            @"perthousand",
            @"Acircumflex",
            @"Ecircumflex",
            @"Aacute",
            @"Edieresis",
            @"Egrave",
            @"Iacute",
            @"Icircumflex",
            @"Idieresis",
            @"Igrave",
            @"Oacute",
            @"Ocircumflex",
            @"apple",
            @"Ograve",
            @"Uacute",
            @"Ucircumflex",
            @"Ugrave",
            @"dotlessi",
            @"circumflex",
            @"tilde",
            @"macron",
            @"breve",
            @"dotaccent",
            @"ring",
            @"cedilla",
            @"hungarumlaut",
            @"ogonek",
            @"caron",
            @"Lslash",
            @"lslash",
            @"Scaron",
            @"scaron",
            @"Zcaron",
            @"zcaron",
            @"brokenbar",
            @"Eth",
            @"eth",
            @"Yacute",
            @"yacute",
            @"Thorn",
            @"thorn",
            @"minus",
            @"multiply",
            @"onesuperior",
            @"twosuperior",
            @"threesuperior",
            @"onehalf",
            @"onequarter",
            @"threequarters",
            @"franc",
            @"Gbreve",
            @"gbreve",
            @"Idotaccent",
            @"Scedilla",
            @"scedilla",
            @"Cacute",
            @"cacute",
            @"Ccaron",
            @"ccaron",
            @"dcroat"
        };
        StandardGlyphNamesDictionary = [[NSDictionary dictionaryWithObjects:_StandardGlyphNames forKeys:_StandardGlyphNamesKeys count:258] retain];
    }
    return (FT_String*)[[StandardGlyphNamesDictionary objectForKey:glyphKey] UTF8String];
}

- (CGGlyph) glyphWithName: (NSString*)glyphName
{
    FT_Face ft_face = cairo_ft_scaled_font_lock_face(_descriptor->cairofont);
    CGGlyph result = 0;
    //TODO using #import <CoreGraphics/StandardGlyphNames.h>
    result = (CGGlyph)FT_Get_Name_Index(ft_face, (FT_String*)[glyphName UTF8String]);
    
    if (result == 0) {
        FT_String* nameFromKey = [self glyphNameForKey:glyphName];
        if (nameFromKey != NULL) {
            result = (CGGlyph)FT_Get_Name_Index(ft_face, nameFromKey);
        }
    }
    
    
    cairo_ft_scaled_font_unlock_face(_descriptor->cairofont);
    
    return result;
}

- (NSStringEncoding) mostCompatibleStringEncoding
{
    return mostCompatibleStringEncoding;
}

//
// CTFont private
//
+ (CTNSFont*) fontWithDescriptor: (CTNSFontDescriptor*)descriptor
                       options: (CTFontOptions)options
{
    // FIXME: placeholder code.
    return [[[CTNSFont alloc] _initWithDescriptor: descriptor
                                          options: options] autorelease];
}

+ (CTNSFont*) fontWithGraphicsFont: (CGFontRef)graphics
            additionalDescriptor: (CTNSFontDescriptor*)descriptor
{
	return nil;
}

- (id)_initWithDescriptor: (CTNSFontDescriptor*)aDescriptor
                  options: (CTFontOptions)options
{
    if (nil == (self = [super init])) {
        return nil;
    }
    ASSIGN(_descriptor, aDescriptor);
    NSAffineTransform *transform = [_descriptor objectForKey: CTNSFontMatrixAttribute];
    if (transform == nil) {
        _matrix.CGTransform = CGAffineTransformIdentity;
    } else {
        _matrix.NSTransform = [transform transformStruct];
    }
    // TODO set the rest of the attributes:
    FT_Face ft_face = cairo_ft_scaled_font_lock_face(_descriptor->cairofont);
    
    ascender = REAL_SIZE(ft_face->ascender);
    descender = REAL_SIZE(ft_face->descender);
    leading = TRANSFORMED_SIZE(0, ft_face->height - (ascender - descender)).height;
    underlinePosition = TRANSFORMED_POINT(0, ft_face->underline_position).y;
    underlineThickness = TRANSFORMED_SIZE(0, ft_face->underline_thickness).height;
    
    // TT_OS2* OS2Table = FT_Get_Sfnt_Table(ft_face, TTAG_OS2);
    // if (NULL != OS2Table) {
    //   capHeight = TRANSFORMED_SIZE(0, OS2Table->sCapHeight).height;
    //   xHeight = = TRANSFORMED_SIZE(0, OS2Table->sxHeight).height;
    // }
    
    // TT_Postscript *postTable = FT_Get_Sfnt_Table(fontFace, TTAG_post);
    // if (NULL != postTable) {
    //   isFixedPitch = postTable->isFixedPitch;
    //   italicAngle = CGFloatFromFT_Fixed(postTable->italicAngle);
    // }
    
    numberOfGlyphs = ft_face->num_glyphs;
    
    fontName = [[[_descriptor fontAttributes] objectForKey:kCTFontNameAttribute] retain];
    familyName = [[NSString alloc] initWithUTF8String:ft_face->family_name];
    
    cairo_ft_scaled_font_unlock_face(_descriptor->cairofont);
    return self;
}

- (void)dealloc
{
    [fontName release];
    [familyName release];
    [super dealloc];
}

- (CGFloat) unitsPerEm
{
	return 0;
}

- (NSString*) localizedNameForKey: (NSString*)nameKey
                         language: (NSString**)languageOut
{
	return nil;
}

- (bool) getGraphicsGlyphsForCharacters: (const unichar *)characters
                         graphicsGlyphs: (const CGGlyph *)glyphs
                                  count: (CFIndex)count
{
  memcpy((void*)glyphs, characters, count*sizeof(unichar));
  return true;
}

- (double) getAdvancesForGraphicsGlyphs: (const CGGlyph [])glyphs
                               advances: (CGSize [])advances
                            orientation: (CTFontOrientation)orientation
                                  count: (CFIndex)count
{
  //TODO
  [self getAdvancements:advances forGlyphs:glyphs count:count];

	return 0;
}

- (CGRect) getBoundingRectsForGraphicsGlyphs: (const CGGlyph *)glyphs
                                       rects: (CGRect*)rects
                                 orientation: (CTFontOrientation)orientation
                                       count: (CFIndex)count
{
	CGRect r = {{0,0},{0,0}};
	return r;
}

- (void) getVerticalTranslationForGraphicsGlyphs: (const CGGlyph*)glyphs
                                     translation: (CGSize*)translation
                                           count: (CFIndex)count
{
}

- (CGPathRef) graphicsPathForGlyph: (CGGlyph)glyph
                         transform: (const CGAffineTransform *)xform
{
	return nil;
}

- (NSArray*) variationAxes
{
	return nil;
}

- (NSDictionary*) variation
{
	return nil;
}

- (CGFontRef) graphicsFontWithDescriptor: (CTNSFontDescriptor**)descriptorOut
{
	return nil;
}

- (NSArray*) availableTablesWithOptions: (CTFontTableOptions)options
{
	return nil;
}

- (NSData*) tableForTag: (CTFontTableTag)tag
            withOptions: (CTFontTableOptions)options
{
	return nil;
}

//
// CGFont private
//
- (NSString*) nameForGlyph: (CGGlyph)graphicsGlyph
{
	return nil;
}

+ (CTFontRef) fontWithData: (NSData*)fontData
                      size: (CGFloat)size
       		          matrix: (const CGFloat*)fontMatrix
      additionalDescriptor: (CTNSFontDescriptor*)descriptor
{
	return nil;
}

- (NSString *)nameForKey:(NSString *)nameKey
{
    return nil;
}

+ (CTNSFont *)UIFontWithType:(CTFontUIFontType)type
                      size:(CGFloat)size
               forLanguage:(NSString*)languageCode
{
    return nil;
}

@end

