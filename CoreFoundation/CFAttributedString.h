/*
   CFAttributedString.h

   Copyright (C) 2011-2012 Free Software Foundation, Inc.

   Author: Amr Aboelela <amraboelela@gmail.com>
   Date: December, 2011

   This file is part of CoreFoundation.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#ifndef __COREFOUNDATION_CFATTRIBUTEDSTRING_H__
#define __COREFOUNDATION_CFATTRIBUTEDSTRING_H__

#import <CoreFoundation/CFBase.h>
#import <CoreFoundation/CFDictionary.h>
#import <CoreFoundation/CFString.h>

CF_EXTERN_C_BEGIN



#ifdef __OBJC__
@class NSAttributedString;
@class NSMutableAttributedString;
typedef NSAttributedString* CFAttributedStringRef;
typedef NSMutableAttributedString* CFMutableAttributedStringRef;
#else
typedef const struct __CFAttributedString* CFAttributedStringRef;
typedef struct __CFAttributedString* CFMutableAttributedStringRef;
#endif




//
// Creating an AttributedString
//

/*

@params alloc The allocator to use to allocate memory for the new attributed string.
 - Pass NULL or kCFAllocatorDefault to use the current default allocator.

@params str A string that specifies the characters to use in the new attributed string. 
- This value is copied.

attributes  A dictionary that contains the attributes to apply to the new attributed string. 
- This value is copied.

Return Value An attributed string that contains the characters from str and the attributes specified by attributes.
- The result is NULL if there was a problem in creating the attributed string. Ownership follows the Create Rule


*/

CF_EXPORT CFAttributedStringRef 
CFAttributedStringCreate (CFAllocatorRef alloc,CFStringRef str,CFDictionaryRef attributes);



CF_EXPORT CFAttributedStringRef 
CFAttributedStringCreateCopy (CFAllocatorRef alloc,CFAttributedStringRef aStr);


CF_EXPORT CFAttributedStringRef 
CFAttributedStringCreateWithSubstring (CFAllocatorRef alloc,CFAttributedStringRef aStr,CFRange range);


CF_EXPORT CFTypeRef 
CFAttributedStringGetAttribute (CFAttributedStringRef aStr,CFIndex loc,CFStringRef attrName,CFRange *effectiveRange);

CF_EXPORT CFTypeRef 
CFAttributedStringGetAttributeAndLongestEffectiveRange (CFAttributedStringRef aStr,CFIndex loc,CFStringRef attrName,CFRange inRange,CFRange *longestEffectiveRange);


CF_EXPORT CFDictionaryRef CFAttributedStringGetAttributesAndLongestEffectiveRange (
   CFAttributedStringRef aStr,
   CFIndex loc,
   CFRange inRange,
   CFRange *longestEffectiveRange);

CF_EXPORT CFDictionaryRef 
CFAttributedStringGetAttributes (CFAttributedStringRef aStr,CFIndex loc,CFRange *effectiveRange);

CF_EXPORT CFDictionaryRef 
CFAttributedStringGetAttributesAndLongestEffectiveRange (CFAttributedStringRef aStr,CFIndex loc,CFRange inRange,CFRange *longestEffectiveRange);

CF_EXPORT CFMutableAttributedStringRef 
CFAttributedStringCreateMutableCopy (CFAllocatorRef alloc,CFIndex maxLength,CFAttributedStringRef aStr);


CF_EXPORT CFMutableStringRef
CFAttributedStringGetMutableString (CFMutableAttributedStringRef aStr);


CF_EXPORT void CFAttributedStringRemoveAttribute(CFMutableAttributedStringRef aStr, CFRange range,
   CFStringRef attrName);


CF_EXPORT CFIndex 
CFAttributedStringGetLength (CFAttributedStringRef aStr);


CF_EXPORT CFStringRef 
CFAttributedStringGetString (CFAttributedStringRef aStr);



CF_EXPORT void 
CFAttributedStringSetAttribute (CFMutableAttributedStringRef aStr,CFRange range,CFStringRef attrName,CFTypeRef value);



CF_EXPORT CFTypeID 
CFAttributedStringGetTypeID (void);


//------------------------------------------------- MUtable AttributedString ----------------------------------//

CF_EXPORT void 
CFAttributedStringBeginEditing (CFMutableAttributedStringRef aStr);

CF_EXPORT CFMutableAttributedStringRef 
CFAttributedStringCreateMutable (CFAllocatorRef alloc, CFIndex maxLength);


CF_EXPORT CFMutableAttributedStringRef 
CFAttributedStringCreateMutableCopy (CFAllocatorRef alloc,CFIndex maxLength,CFAttributedStringRef aStr);


CF_EXPORT void
CFAttributedStringEndEditing (CFMutableAttributedStringRef aStr);

CF_EXPORT CFMutableStringRef
 CFAttributedStringGetMutableString (CFMutableAttributedStringRef aStr);


CF_EXPORT void 
CFAttributedStringRemoveAttribute (CFMutableAttributedStringRef aStr,CFRange range, CFStringRef attrName);


CF_EXPORT void 
CFAttributedStringReplaceAttributedString (CFMutableAttributedStringRef aStr,CFRange range,CFAttributedStringRef replacement);

CF_EXPORT void 
CFAttributedStringReplaceString (CFMutableAttributedStringRef aStr,
   CFRange range,
   CFStringRef replacement
);


CF_EXPORT void 
CFAttributedStringSetAttribute (CFMutableAttributedStringRef aStr,CFRange range,
   CFStringRef attrName,
   CFTypeRef value
);

CF_EXPORT void 
CFAttributedStringSetAttributes (CFMutableAttributedStringRef aStr,CFRange range,
   CFDictionaryRef replacement,
   Boolean clearOtherAttributes
);

void CFAttributedStringInitialize (void);

CF_EXTERN_C_END

#endif
