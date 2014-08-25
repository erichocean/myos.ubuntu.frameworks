/* GSPrivate.h
   
   Copyright (C) 2011 Free Software Foundation, Inc.
   
   Written by: Stefan Bidigaray
   Date: December, 2011
   
   This file is part of GNUstep CoreBase library.
   
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

#ifndef __GSPRIVATE_H__
#define __GSPRIVATE_H__

#include <CoreFoundation/CFBase.h>
#include <CoreFoundation/CFRuntime.h>
#include <CoreFoundation/CFLocale.h>
#include <CoreFoundation/CFString.h>
#include <CoreFoundation/CFStringEncodingExt.h>



#define UDATE_TO_ABSOLUTETIME(d) \
  (((d) / 1000.0) - kCFAbsoluteTimeIntervalSince1970)
#define ABSOLUTETIME_TO_UDATE(at) \
  (((at) + kCFAbsoluteTimeIntervalSince1970) * 1000.0)

#if defined(_WIN32)

#include <windows.h>

#define GSMutex CRITICAL_SECTION
#define GSMutexInitialize(x) InitializeCriticalSection(x)
#define GSMutexLock(x) EnterCriticalSection(x)
#define GSMutexUnlock(x) LeaveCriticalSection(x)
#define GSMutexDestroy(x) DeleteCriticalSection(x)

#if defined(_WIN64)
#define GSAtomicIncrementCFIndex(ptr) \
  InterlockedIncrement64((LONGLONG volatile*)(ptr))
#define GSAtomicDecrementCFIndex(ptr) \
  InterlockedDecrement64((LONGLONG volatile*)(ptr))
#define GSAtomicCompareAndSwapCFIndex(ptr, oldv, newv) \
  InterlockedCompareExchange64((LONGLONG volatile*)(ptr), (newv), (oldv))
#else
#define GSAtomicIncrementCFIndex(ptr) \
  InterlockedIncrement((LONG volatile*)(ptr))
#define GSAtomicDecrementCFIndex(ptr) \
  InterlockedDecrement((LONG volatile*)(ptr))
#define GSAtomicCompareAndSwapCFIndex(ptr, oldv, newv) \
  InterlockedCompareExchange((LONG volatile*)(ptr), (newv), (oldv))
#endif /* _WIN64 */


#define GSAtomicCompareAndSwapPointer(ptr, oldv, newv) \
  InterlockedCompareExchangePointer((ptr), (newv), (oldv))

#else /* _WIN32 */

#include <pthread.h>

#define GSMutex pthread_mutex_t
#define GSMutexInitialize(x) pthread_mutex_init(x, NULL)
#define GSMutexLock(x) pthread_mutex_lock(x)
#define GSMutexUnlock(x) pthread_mutex_unlock(x)
#define GSMutexDestroy(x) pthraed_mutex_destroy(x)

#if defined(__llvm__) \
      || (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 1))

#define GSAtomicIncrementCFIndex(ptr) __sync_add_and_fetch((long*)(ptr), 1)
#define GSAtomicDecrementCFIndex(ptr) __sync_sub_and_fetch((long*)(ptr), 1)
#define GSAtomicCompareAndSwapCFIndex(ptr, oldv, newv) \
  __sync_val_compare_and_swap((long*)(ptr), (long)(oldv), (long)(newv))
#define GSAtomicCompareAndSwapPointer(ptr, oldv, newv) \
  __sync_val_compare_and_swap((void**)(ptr), (void*)(oldv), (void*)(newv))

#endif

#endif /* _WIN32 */

CFIndex
GSBSearch (const void *array, const void *key, CFRange range, CFIndex size,
  CFComparatorFunction comp, void *ctxt);

CFTypeRef
GSTypeCreateCopy (CFAllocatorRef alloc, CFTypeRef cf, CFTypeID typeID);


/* All three of these function are taken from Thomas Wang's website
 * (http://www.concentric.net/~Ttwang/tech/inthash.htm).  As far as I know,
 * these algorithm are in the public domain.
 */
CF_INLINE UInt64
GSHashInt64 (UInt64 value)
{
  register UInt64 hash = value;
  hash = (~hash) + (hash << 21);
  hash = hash ^ (hash >> 24);
  hash = (hash + (hash << 3)) + (hash << 8);
  hash = hash ^ (hash >> 14);
  hash = (hash + (hash << 2)) + (hash << 4);
  hash = hash ^ (hash >> 28);
  hash = hash + (hash << 31);
  return hash;
}

CF_INLINE UInt32
GSHashInt32 (UInt32 value)
{
  register UInt32 hash = value;
  hash = ~hash + (hash << 15);
  hash = hash ^ (hash >> 12);
  hash = hash + (hash << 2);
  hash = hash ^ (hash >> 4);
  hash = (hash + (hash << 3)) + (hash << 11);
  hash = hash ^ (hash >> 16);
  return hash;
}

CF_INLINE UInt32
GSHashInt64ToInt32 (UInt64 value)
{
  register UInt64 hash = value;
  hash = (~hash) + (hash << 18);
  hash = hash ^ (hash >> 31);
  hash = (hash + (hash << 2)) + (hash << 4);
  hash = hash ^ (hash >> 11);
  hash = hash + (hash << 6);
  hash = hash ^ (hash >> 22);
  return (UInt32)hash;
}

CF_INLINE CFHashCode
GSHashPointer (const void *value)
{
#if defined(__LP64__) || defined(_WIN64)
/* 64-bit operating systems */
  return (CFHashCode)GSHashInt64 ((UInt64)value);
#else
/* 32-bit operating systems */
  return (CFHashCode)GSHashInt32 ((UInt32)value);
#endif
}

CF_INLINE CFHashCode
GSHashBytes (const void *bytes, CFIndex length)
{
  CFHashCode ret = 0;
  if (length > 0)
    {
      register CFIndex idx;
      register const char *p = bytes;
      
      for (idx = 0 ; idx < length ; ++idx)
        ret = (ret << 5) + ret + p[idx];
      
      ret &= 0x0fffffff;
      if (ret == 0)
        ret = 0x0fffffff;
    }
  else
    {
      ret = 0x0ffffffe;
    }
  
  return ret;
}



struct __CFConstantString
{
  CFRuntimeBase  _parent;
  void          *_contents;
  CFIndex        _count;
  CFHashCode     _hash;
  CFAllocatorRef _deallocator;
};

#if defined (_WIN32)
#define DLL_EXPORT __declspec(dllexport)
#else
#define DLL_EXPORT
#endif

#define CONST_STRING_DECL(var, str) \
  static struct __CFConstantString __ ## var ## __ = \
    { {0, 0, {1, 0, 0}}, (void*)str, sizeof(str) - 1, 0, NULL }; \
  DLL_EXPORT const CFStringRef var = (CFStringRef) & __ ## var ## __;

#define CHAR_SPACE      0x0020
#define CHAR_EXCLAMATION 0x0021
#define CHAR_QUOTATION  0x0022
#define CHAR_NUMBER     0x0023
#define CHAR_DOLLAR     0x0024
#define CHAR_PERCENT    0x0025
#define CHAR_AMPERSAND  0x0026
#define CHAR_APOSTROPHE 0x0027
#define CHAR_L_PARANTHESIS 0x0028
#define CHAR_R_PARANTHESIS 0x0029
#define CHAR_ASTERISK   0x002A
#define CHAR_PLUS       0x002B
#define CHAR_COMMA      0x002C
#define CHAR_MINUS      0x002D
#define CHAR_PERIOD     0x002E
#define CHAR_SLASH      0x002F

#define CHAR_ZERO  0x0030
#define CHAR_ONE   0x0031
#define CHAR_TWO   0x0032
#define CHAR_THREE 0x0033
#define CHAR_FOUR  0x0034
#define CHAR_FIVE  0x0035
#define CHAR_SIX   0x0036
#define CHAR_SEVEN 0x0037
#define CHAR_EIGHT 0x0038
#define CHAR_NINE  0x0039

#define CHAR_COLON     0x003A
#define CHAR_SEMICOLON 0x003B
#define CHAR_LESS_THAN 0x003C
#define CHAR_EQUAL     0x003D
#define CHAR_GREATER_THAN 0x003E
#define CHAR_QUESTION  0x003F
#define CHAR_AT        0x0040

#define CHAR_CAP_A 0x0041
#define CHAR_CAP_F 0x0046
#define CHAR_CAP_L 0x004C
#define CHAR_CAP_X 0x0058
#define CHAR_CAP_Z 0x005A

#define CHAR_L_SQUARE_BRACKET 0x005B
#define CHAR_BACKSLASH  0x005C
#define CHAR_R_SQUARE_BRACKET 0x005D
#define CHAR_CIRCUMFLEX 0x005E
#define CHAR_LOW_LINE   0x005F
#define CHAR_GRAVE      0x0060

#define CHAR_A 0x0061
#define CHAR_F 0x0066
#define CHAR_H 0x0068
#define CHAR_J 0x006A
#define CHAR_L 0x006C
#define CHAR_T 0x0074
#define CHAR_V 0x0076
#define CHAR_X 0x0078
#define CHAR_Z 0x007A

#define CHAR_L_BRACE 0x007B
#define CHAR_VERTICAL_LINE 0x007C
#define CHAR_R_BRACE 0x007D
#define CHAR_TILDE   0x007E

#define CHAR_IS_DIGIT(c) ((c) >= CHAR_ZERO && (c) <= CHAR_NINE)
#define CHAR_IS_HEX(c) (CHAR_IS_DIGIT(c) \
  || ((c >= CHAR_CAP_A && c <= CHAR_CAP_F) || (c >= CHAR_A && c <= CHAR_F))
#define CHAR_IS_ASCII(c) ((c) < 128)
#define CHAR_IS_UPPER_CASE(c) ((c) >= CHAR_CAP_A && (c) <= CHAR_CAP_Z)
#define CHAR_IS_LOWER_CASE(c) ((c) >= CHAR_A && (c) <= CHAR_Z)
#define CHAR_IS_ALPHA(c) (CHAR_IS_UPPER_CASE(c) || CHAR_IS_LOWER_CASE(c))


CF_INLINE Boolean
__CFStringEncodingIsSupersetOfASCII (CFStringEncoding encoding)
{
  if (encoding == kCFStringEncodingASCII)
    return true;  

  switch (encoding & 0xF00)
    {
      case 0x100:
        return encoding == kCFStringEncodingUTF8 ? true : false;
      case 0x000: // MacOS codepage
        if (encoding == kCFStringEncodingMacJapanese
            || encoding == kCFStringEncodingMacArabic
            || encoding == kCFStringEncodingMacHebrew
            || encoding == kCFStringEncodingMacUkrainian
            || encoding == kCFStringEncodingMacSymbol
            || encoding == kCFStringEncodingMacDingbats)
          return false;
      case 0x200: // ISO-8859-*
      case 0x400: // DOS codepage
      case 0x500: // Windows codepage
        return true;
      case 0x600:
        return encoding == kCFStringEncodingASCII ? true : false;
    }
  return false;
}

CF_INLINE CFStringEncoding
GSStringGetFileSystemEncoding (void)
{
#if defined(_WIN32)
  return kCFStringEncodingUTF16;
#else
  return CFStringGetSystemEncoding ();
#endif
}

#if __BIG_ENDIAN__
#define UTF16_ENCODING kCFStringEncodingUTF16BE
#define UTF16_BOM_HI 0xFE
#define UTF16_BOM_LO 0xFF
#else
#define UTF16_ENCODING kCFStringEncodingUTF16LE
#define UTF16_BOM_HI 0xFF
#define UTF16_BOM_LO 0xFE
#endif
#define UTF16_BOM 0xFEFF

/* This function converts a Unicode string to a specified encoding.
 * It returns the number of bytes consumed.
 * If you need to know how many characters were consumed, you must compare
 * the value of *src before the function call to the one after the function
 * has returned.
 * WARNING: Never tell this function to convert to kCFStringEncodingUTF16
 * because it will add a BOM even if one already exists, regardless of
 * isExternalRepresentation.
 */
CFIndex
GSStringEncodingFromUnicode (CFStringEncoding encoding, char *dst,
  CFIndex dstLength, const UniChar **src, CFIndex srcLength, char lossByte,
  Boolean isExternalRepresentation, CFIndex *bytesNeeded);

/* This function converts a Unicode string to a specified encoding.
 * It return the number of characters converted.
 * If you need to know how many bytes were consumed, you must compare
 * the value of *src before the function call to the one after the function
 * has returned.
 * WARNING: Never tell this function to convert from kCFStringEncodingUTF16
 * because it will add a BOM.
 */
CFIndex
GSStringEncodingToUnicode (CFStringEncoding encoding, UniChar *dst,
  CFIndex dstLength, const char **src, CFIndex srcLength,
  Boolean isExternalRepresentation, CFIndex *bytesNeeded);

void
_CFStringAppendFormatAndArgumentsAux (CFMutableStringRef outputString,
  CFStringRef (*copyDescFunc)(void *, const void *loc),
  CFDictionaryRef formatOptions, CFStringRef formatString, va_list args);

CFStringRef
_CFStringCreateWithFormatAndArgumentsAux (CFAllocatorRef alloc,
  CFStringRef (*copyDescFunc)(void *, const void *loc),
  CFDictionaryRef formatOptions, CFStringRef formatString, va_list args);

const void *
CFTypeRetainCallBack (CFAllocatorRef allocator, const void *value);

void
CFTypeReleaseCallBack (CFAllocatorRef alloc, const void *value);

const char *
CFLocaleGetCStringIdentifier (CFLocaleRef locale, char *buf, CFIndex maxlen);

void
GSRuntimeConstantInit (CFTypeRef cf, CFTypeID typeID);

void
GSRuntimeDeallocateInstance (CFTypeRef cf);

#define GS_MAX(a,b) (a > b ? a : b)
#define GS_MIN(a,b) (a < b ? a : b)



#if defined(_MSC_VER)

#define CF_OBJC_FUNCDISPATCH0(typeID, rettype, obj, sel)
#define CF_OBJC_FUNCDISPATCH1(typeID, rettype, obj, sel, a1)
#define CF_OBJC_FUNCDISPATCH2(typeID, rettype, obj, sel, a1, a2)
#define CF_OBJC_FUNCDISPATCH3(typeID, rettype, obj, sel, a1, a2, a3)
#define CF_OBJC_FUNCDISPATCH4(typeID, rettype, obj, sel, a1, a2, a3, a4)
#define CF_OBJC_FUNCDISPATCH5(typeID, rettype, obj, sel, a1, a2, a3, a4, a5)
#else
#define BOOL OBJC_BOOL
#include <objc/runtime.h>
#undef BOOL

extern void **__CFRuntimeObjCClassTable;
extern UInt32 __CFRuntimeClassTableCount;

CF_INLINE void *
__CFISAForTypeID (CFTypeID typeID)
{
  return (__CFRuntimeObjCClassTable && typeID < __CFRuntimeClassTableCount ?
    __CFRuntimeObjCClassTable[typeID] : NULL);
}

CF_INLINE Boolean
CF_IS_OBJC (CFTypeID typeID, const void *obj)
{
  return (obj && (typeID >= __CFRuntimeClassTableCount
          || object_getClass((id)obj) != __CFISAForTypeID (typeID)));
}

#define CF_OBJC_FUNCDISPATCH0(typeID, rettype, obj, sel) do { \
  if (CF_IS_OBJC(typeID, obj)) \
    { \
      rettype (*imp)(id, SEL); \
      static SEL s = NULL; \
      if (!s) \
        s = sel_registerName(sel); \
      imp = (rettype (*)(id, SEL)) \
        class_getMethodImplementation (object_getClass((id)obj), s); \
      return imp((id)obj, s); \
    } \
  } while(0)

#define CF_OBJC_FUNCDISPATCH1(typeID, rettype, obj, sel, a1) do { \
  if (CF_IS_OBJC(typeID, obj)) \
    { \
      rettype (*imp)(id, SEL, ...); \
      static SEL s = NULL; \
      if (!s) \
        s = sel_registerName(sel); \
      imp = (rettype (*)(id, SEL, ...)) \
        class_getMethodImplementation (object_getClass((id)obj), s); \
      return imp((id)obj, s, a1); \
    } \
  } while(0)

#define CF_OBJC_FUNCDISPATCH2(typeID, rettype, obj, sel, a1, a2) do { \
  if (CF_IS_OBJC(typeID, obj)) \
    { \
      rettype (*imp)(id, SEL, ...); \
      static SEL s = NULL; \
      if (!s) \
        s = sel_registerName(sel); \
      imp = (rettype (*)(id, SEL, ...)) \
        class_getMethodImplementation (object_getClass((id)obj), s); \
      return (rettype)imp((id)obj, s, a1, a2); \
    } \
  } while(0)

#define CF_OBJC_FUNCDISPATCH3(typeID, rettype, obj, sel, a1, a2, a3) do { \
  if (CF_IS_OBJC(typeID, obj)) \
    { \
      rettype (*imp)(id, SEL, ...); \
      static SEL s = NULL; \
      if (!s) \
        s = sel_registerName(sel); \
      imp = (rettype (*)(id, SEL, ...)) \
        class_getMethodImplementation (object_getClass((id)obj), s); \
      return (rettype)imp((id)obj, s, a1, a2, a3); \
    } \
  } while(0)

#define CF_OBJC_FUNCDISPATCH4(typeID, rettype, obj, sel, a1, a2, a3, a4) do { \
  if (CF_IS_OBJC(typeID, obj)) \
    { \
      rettype (*imp)(id, SEL, ...); \
      static SEL s = NULL; \
      if (!s) \
        s = sel_registerName(sel); \
      imp = (rettype (*)(id, SEL, ...)) \
        class_getMethodImplementation (object_getClass((id)obj), s); \
      return (rettype)imp((id)obj, s, a1, a2, a3, a4); \
    } \
  } while(0)

#define CF_OBJC_FUNCDISPATCH5(typeID, rettype, obj, sel, a1, a2, a3, a4, a5) \
do { \
  if (CF_IS_OBJC(typeID, obj)) \
    { \
      rettype (*imp)(id, SEL, ...); \
      static SEL s = NULL; \
      if (!s) \
        s = sel_registerName(sel); \
      imp = (rettype (*)(id, SEL, ...)) \
        class_getMethodImplementation (object_getClass((id)obj), s); \
      return (rettype)imp((id)obj, s, a1, a2, a3, a4, a5); \
    } \
  } while(0)
#endif /* defined(_MSC_VER) */

#endif /* __GSPRIVATE_H__ */