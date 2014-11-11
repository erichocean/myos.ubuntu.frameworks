/* 
   CTNSFontDescriptor.h

   Holds an image to use as a cursor

   Copyright (C) 2007 Free Software Foundation, Inc.

   Author:  Dr. H. Nikolaus Schaller <hns@computer.org>
   Date: 2006
   
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


#ifndef _GNUstep_H_CTNSFontDescriptor
#define _GNUstep_H_CTNSFontDescriptor

#import <Foundation/NSObject.h>

#import <cairo/cairo-ft.h>

@class NSArray;
@class NSCoder;
@class NSDictionary;
@class NSSet;
@class NSString;
@class NSAffineTransform;


typedef uint32_t CTNSFontSymbolicTraits;

typedef enum _CTNSFontFamilyClass
{
  CTNSFontUnknownClass = 0 << 28,
  CTNSFontOldStyleSerifsClass = 1U << 28,
  CTNSFontTransitionalSerifsClass = 2U << 28,
  CTNSFontModernSerifsClass = 3U << 28,
  CTNSFontClarendonSerifsClass = 4U << 28,
  CTNSFontSlabSerifsClass = 5U << 28,
  CTNSFontFreeformSerifsClass = 7U << 28,
  CTNSFontSansSerifClass = 8U << 28,
  CTNSFontOrnamentalsClass = 9U << 28,
  CTNSFontScriptsClass = 10U << 28,
  CTNSFontSymbolicClass = 12U << 28
} CTNSFontFamilyClass;

enum _CTNSFontFamilyClassMask {
    CTNSFontFamilyClassMask = 0xF0000000
};

enum _CTNSFontTrait
{
  CTNSFontItalicTrait = 0x0001,
  CTNSFontBoldTrait = 0x0002,
  CTNSFontExpandedTrait = 0x0020,
  CTNSFontCondensedTrait = 0x0040,
  CTNSFontMonoSpaceTrait = 0x0400,
  CTNSFontVerticalTrait = 0x0800,
  CTNSFontUIOptimizedTrait = 0x1000
};

// FIXME: Document these with the value type

NSString *CTNSFontFamilyAttribute;
NSString *CTNSFontNameAttribute;
NSString *CTNSFontFaceAttribute;
NSString *CTNSFontSizeAttribute; 
NSString *CTNSFontVisibleNameAttribute; 
NSString *CTNSFontColorAttribute;
/**
 * NOTE: CTNSFontMatrixAttribute is a NSAffineTransform, unlike kCTFontMatrixAttribute which 
 * is an NSData containing a CGAffineTransform struct.
 */
NSString *CTNSFontMatrixAttribute;
NSString *CTNSFontVariationAttribute;
NSString *CTNSFontCharacterSetAttribute;
NSString *CTNSFontCascadeListAttribute;
NSString *CTNSFontTraitsAttribute;
NSString *CTNSFontFixedAdvanceAttribute;

NSString *CTNSFontSymbolicTrait;
NSString *CTNSFontWeightTrait;
NSString *CTNSFontWidthTrait;
NSString *CTNSFontSlantTrait;

NSString *CTNSFontVariationAxisIdentifierKey;
NSString *CTNSFontVariationAxisMinimumValueKey;
NSString *CTNSFontVariationAxisMaximumValueKey;
NSString *CTNSFontVariationAxisDefaultValueKey;
NSString *CTNSFontVariationAxisNameKey;

@interface CTNSFontDescriptor : NSObject <NSCopying>{
@package
    /**
     * CTNSFontDescriptor can be used simultaneously by multiple threads, so it is
     * necessary to lock before we call FreeType, because an FT_Face
     * object may be used by only one thread.
     */
    NSLock *fontFaceLock;
    NSDictionary *_attributes;
    FT_Face fontFace;
    
    cairo_scaled_font_t *cairofont;
}

+ (id) fontDescriptorWithFontAttributes: (NSDictionary *)attributes;
+ (id) fontDescriptorWithName: (NSString *)name
                         size: (CGFloat)size;
+ (id) fontDescriptorWithName: (NSString *)name
                       matrix: (NSAffineTransform *)matrix;
/**
 * Returns the attribute dictionary for this descriptor.
 * NOTE: This dictionary won't necessairly contain everything -objectForKey:
 * returns a value for (i.e. -objectForKey: may access a system font pattern)
 */
- (NSDictionary *) fontAttributes;
- (id) initWithFontAttributes: (NSDictionary *)attributes;

- (CTNSFontDescriptor *) fontDescriptorByAddingAttributes:
  (NSDictionary *)attributes;
- (CTNSFontDescriptor *) fontDescriptorWithFace: (NSString *)face;
- (CTNSFontDescriptor *) fontDescriptorWithFamily: (NSString *)family;
- (CTNSFontDescriptor *) fontDescriptorWithMatrix: (NSAffineTransform *)matrix;
- (CTNSFontDescriptor *) fontDescriptorWithSize: (CGFloat)size;
- (CTNSFontDescriptor *) fontDescriptorWithSymbolicTraits:
  (CTNSFontSymbolicTraits)traits;
- (NSArray *) matchingFontDescriptorsWithMandatoryKeys: (NSSet *)keys;

- (id) objectForKey: (NSString *)attribute;
- (NSAffineTransform *) matrix;
- (CGFloat) pointSize;
- (NSString *) postscriptName;
- (CTNSFontSymbolicTraits) symbolicTraits;
- (CTNSFontDescriptor *) matchingFontDescriptorWithMandatoryKeys: (NSSet *)keys;

//
// CTFontDescriptor private
//

- (id) localizedObjectForKey: (NSString*)key language: (NSString*)language;

//
// CTFontDescriptor private; to be overridden in subclasses
//

- (NSArray *) matchingFontDescriptorsWithMandatoryKeys: (NSSet *)keys;
- (id) objectFromPlatformFontPatternForKey: (NSString *)attribute;
- (id) localizedObjectFromPlatformFontPatternForKey: (NSString*)key language: (NSString*)language;

@end

#endif /* _GNUstep_H_CTNSFontDescriptor */
