/* CFDictionary.h
   
   Copyright (C) 2010 Free Software Foundation, Inc.
   
   Written by: Stefan Bidigaray
   Date: January, 2010
   
   This file is part of CoreBase.
   
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

   Edited by: Ahmed Elmorsy
   Date: Septmber 2012
*/ 

#ifndef __COREFOUNDATION_CFDICTIONARY_H__
#define __COREFOUNDATION_CFDICTIONARY_H__

#include <CoreFoundation/CFBase.h>

CF_EXTERN_C_BEGIN

//should we remove this ifdef? and make it
//with else case?
#ifdef __OBJC__
@class NSDictionary;
@class NSMutableDictionary;
typedef NSDictionary* CFDictionaryRef;
typedef NSMutableDictionary* CFMutableDictionaryRef;
#else
/*
  immutable CFDictionary.
*/
typedef const struct __CFDictionary * CFDictionaryRef;

/*
  mutable CFDictionary.
*/
typedef struct __CFDictionary * CFMutableDictionaryRef;
#endif

/*
  Type of the callback function used to apply functions on
  CFDictionary elements
  @param key The key for the value.
  @param value value of of the element
  @param context The user-defined context parameter given to the apply
    function.
*/
typedef void (*CFDictionaryApplierFunction) (const void *key,
  const void *value, void *context);



/*
  The callback used to create a description for each key 
  in the dictionary. This is used by the CFCopyDescription() function.
*/
typedef CFStringRef (*CFDictionaryCopyDescriptionCallBack)(const void *value);

/* 
  The callback used to compare keys in the dictionary for
  equality.
*/
typedef Boolean  (*CFDictionaryEqualCallBack) (const void *value1,
  const void *value2);

/*
  The callback used to compute hash code for keys.
*/
typedef CFHashCode    (*CFDictionaryHashCallBack) (const void *value);

/*
  The callback used to remove a retain previously added
  for the dictionary from keys as their values are removed from
  the dictionary. The dictionary's allocator is passed as the
  first argument.
*/
typedef void (*CFDictionaryReleaseCallBack) (CFAllocatorRef allocator,
  const void *value);

/*
  The callback used to add a retain for the dictionary
  on keys as they are used to put values into the dictionary.
  This callback returns the value to use as the key in the
  dictionary, which is usually the value parameter passed to
  this callback, but may be a different value if a different
  value should be used as the key. The dictionary's allocator
  is passed as the first argument.
*/
typedef const void *(*CFDictionaryRetainCallBack) (CFAllocatorRef allocator,
  const void *value);

/*
  Structure containing the callbacks for keys of a CFDictionary.
  @field version The version number of the structure type being passed
    in as a parameter to the CFDictionary creation functions.
    This structure is version 0.
  @field retain RetainCallback described above.
  @field release ReleaseCallback described above.
  @field copyDescription copyDescriptionCallback described above.
  @field equal equalCallback described above.
  @field hash hashCallback described above.
*/
typedef struct _CFDictionaryKeyCallBacks CFDictionaryKeyCallBacks;
struct _CFDictionaryKeyCallBacks
{
  CFIndex version;
  CFDictionaryRetainCallBack retain;
  CFDictionaryReleaseCallBack release;
  CFDictionaryCopyDescriptionCallBack copyDescription;
  CFDictionaryEqualCallBack equal;
  CFDictionaryHashCallBack hash;
};


/*
  Structure containing the callbacks for values of a CFDictionary.
*/
typedef struct _CFDictionaryValueCallBacks CFDictionaryValueCallBacks;
struct _CFDictionaryValueCallBacks
{
   CFIndex version;
   CFDictionaryRetainCallBack retain;
   CFDictionaryReleaseCallBack release;
   CFDictionaryCopyDescriptionCallBack copyDescription;
   CFDictionaryEqualCallBack equal;
};

/*
  Predefined CFDictionaryKeyCallBacks structure containing a
  set of callbacks appropriate for use when the keys of a
  CFDictionary are all CFStrings, which may be mutable and
  need to be copied in order to serve as constant keys for
  the values in the dictionary.
*/
CF_EXPORT const CFDictionaryKeyCallBacks kCFCopyStringDictionaryKeyCallBacks;

/*
  Predefined CFDictionaryKeyCallBacks structure containing a
  set of callbacks appropriate for use when the keys of a
  CFDictionary are all CFTypes.
*/
CF_EXPORT const CFDictionaryKeyCallBacks kCFTypeDictionaryKeyCallBacks;

/*
  Predefined CFDictionaryValueCallBacks structure containing a set
  of callbacks appropriate for use when the values in a CFDictionary
  are all CFTypes.
*/
CF_EXPORT const CFDictionaryValueCallBacks kCFTypeDictionaryValueCallBacks;

/*
  Creating a new immutable dictionary with the given values.
  @param allocator The CFAllocator which should be used to allocate
    memory for the dictionary and its storage for values. This
    parameter may be NULL in which case the current default
    CFAllocator (kCFDefaultAllocator) is used.
  @param keys A C array of the pointer-sized keys to be used for
    the parallel C array of values to be put into the dictionary.
    This parameter may be NULL if the numValues parameter is 0.
    This C array is not changed or freed by this function.
  @param values A C array of the pointer-sized values to be in the
    dictionary. This parameter may be NULL if the numValues
    parameter is 0. This C array is not changed or freed by
    this function.
  @param numValues The number of values to copy from the keys and
    values C arrays into the CFDictionary. This number will be
    the count of the dictionary.
  @param keyCallBacks A pointer to a CFDictionaryKeyCallBacks structure
    initialized with the callbacks for the dictionary to use on
    each key in the dictionary. The retain callback will be used
    within this function, for example, to retain all of the new
    keys from the keys C array. A copy of the contents of the
    callbacks structure is made, so that a pointer to a structure
    on the stack can be passed in, or can be reused for multiple
    dictionary creations. The retain field may
    be NULL, in which case the CFDictionary will do nothing to add
    a retain to the keys of the contained values. The release field
    may be NULL, in which case the CFDictionary will do nothing
    to remove the dictionary's retain (if any) on the keys when the
    dictionary is destroyed or a key-value pair is removed. If the
    copyDescription field is NULL, the dictionary will create a
    simple description for a key. If the equal field is NULL, the
    dictionary will use pointer equality to test for equality of
    keys. If the hash field is NULL, a key will be converted from
    a pointer to an integer to compute the hash code. This callbacks
    parameter itself may be NULL, which is treated as if a valid
    structure of version 0 with all fields NULL had been passed in.
  @param valueCallBacks A pointer to a CFDictionaryValueCallBacks structure
    initialized with the callbacks for the dictionary to use on
    each value in the dictionary.
  @return A reference to a new immutable CFDictionary.
*/
CFDictionaryRef
CFDictionaryCreate (CFAllocatorRef allocator, const void **keys,
  const void **values, CFIndex numValues,
  const CFDictionaryKeyCallBacks *keyCallBacks,
  const CFDictionaryValueCallBacks *valueCallBacks);

/*
  Creates a new immutable dictionary with the key-value pairs from
    the given dictionary.
  @param allocator The CFAllocator which should be used to allocate
    memory for the dictionary and its storage for values. This
    parameter may be NULL in which case the current default
    CFAllocator is used.
  @param theDict The dictionary which is to be copied. The keys and values
    from the dictionary are copied as pointers into the new
    dictionary (that is, the values themselves are copied, not
    that which the values point to, if anything). However, the
    keys and values are also retained by the new dictionary using
    the retain function of the original dictionary.
    The count of the new dictionary will be the same as the
    given dictionary. The new dictionary uses the same callbacks
    as the dictionary to be copied.
  @return A reference to a new immutable CFDictionary.
*/
CFDictionaryRef
CFDictionaryCreateCopy (CFAllocatorRef allocator, CFDictionaryRef theDict);

/*
  Reports whether or not the key is in the dictionary.
*/
Boolean
CFDictionaryContainsKey (CFDictionaryRef theDict, const void *key);

/*
  Reports whether or not the value is in the dictionary.
*/
Boolean
CFDictionaryContainsValue (CFDictionaryRef theDict, const void *value);

/*
  Returns the number of values currently in the dictionary.
*/
CFIndex
CFDictionaryGetCount (CFDictionaryRef theDict);

/*
  Counts the number of times the given key occurs in the dictionary.
  @return 1 if a matching key is used by the dictionary, 0 otherwise.
*/
CFIndex
CFDictionaryGetCountOfKey (CFDictionaryRef theDict, const void *key);

/*
  Counts the number of times the given value occurs in the dictionary.
  @return The number of times the given value occurs in the dictionary.
*/
CFIndex
CFDictionaryGetCountOfValue (CFDictionaryRef theDict, const void *value);

/*
  Fills the two buffers with the keys and values from the dictionary.
*/
void
CFDictionaryGetKeysAndValues (CFDictionaryRef theDict, const void **keys,
  const void **values);

/*
  Retrieves the value associated with the given key.
  @result The value with the given key in the dictionary, or NULL if
    no key-value pair with a matching key exists. Since NULL
    can be a valid value in some dictionaries, the function
    CFDictionaryGetValueIfPresent() must be used to distinguish
    NULL-no-found from NULL-is-the-value.
*/
const void *
CFDictionaryGetValue (CFDictionaryRef theDict, const void *key);

/*
  Retrieves the value associated with the given key.
  @param value A pointer to memory which should be filled with the
    pointer-sized value if a matching key is found. If no key
    match is found, the contents of the storage pointed to by
    this parameter are undefined. This parameter may be NULL,
    in which case the value from the dictionary is not returned
    (but the return value of this function still indicates
    whether or not the key-value pair was present).
  @return true, if a matching key was found, false otherwise.
*/
Boolean
CFDictionaryGetValueIfPresent (CFDictionaryRef theDict, const void *key,
  const void **value);

/*
  Calls a function once for each value in the dictionary.
  @param applier The callback function to call once for each value in
    the dictionary.
  @param context A pointer-sized user-defined value, which is passed
    as the third parameter to the applier function, but is
    otherwise unused by this function.
*/
void
CFDictionaryApplyFunction (CFDictionaryRef theDict,
  CFDictionaryApplierFunction applier, void *context);

//
// Getting the type identifier of the CFDictionary type.
//
CFTypeID
CFDictionaryGetTypeID (void);

/*
  Creates a mutable dictionary.
  @param allocator The CFAllocator which should be used to allocate
    memory for the dictionary and its storage for values. This
    parameter may be NULL in which case the current default
    CFAllocator is used. 
  @param capacity A hint about the number of values that will be held
    by the CFDictionary. Pass 0 for no hint. The implementation may
    ignore this hint, or may use it to optimize various
    operations. A dictionary's actual capacity is only limited by 
    address space and available memory constraints).
  @param keyCallBacks A pointer to a CFDictionaryKeyCallBacks structure
    initialized with the callbacks for the dictionary to use on
    each key in the dictionary.
  @param valueCallBacks A pointer to a CFDictionaryValueCallBacks structure
    initialized with the callbacks for the dictionary to use on
    each value in the dictionary.
  @return A reference to a new mutable CFDictionary.
*/
CFMutableDictionaryRef
CFDictionaryCreateMutable (CFAllocatorRef allocator, CFIndex capacity,
  const CFDictionaryKeyCallBacks *keyCallBacks,
  const CFDictionaryValueCallBacks *valueCallBacks);

/*
  Creates a new mutable dictionary with the key-value pairs from
    another given dictionary.
  @param allocator The CFAllocator which should be used to allocate
    memory for the dictionary and its storage for values. This
    parameter may be NULL in which case the current default
    CFAllocator is used.
  @param capacity A hint about the number of values that will be held
    by the CFDictionary. Pass 0 for no hint. The implementation may
    ignore this hint, or may use it to optimize various
    operations. A dictionary's actual capacity is only limited by
    address space and available memory constraints). 
    This parameter must be greater than or equal
    to the count of the dictionary which is to be copied.
  @param theDict The dictionary which is to be copied. The keys and values
    from the dictionary are copied as pointers into the new
    dictionary (that is, the values themselves are copied, not
    that which the values point to, if anything). However, the
    keys and values are also retained by the new dictionary using
    the retain function of the original dictionary.
    The count of the new dictionary will be the same as the
    given dictionary. The new dictionary uses the same callbacks
    as the dictionary to be copied.
  @return A reference to a new mutable CFDictionary.
*/
CFMutableDictionaryRef
CFDictionaryCreateMutableCopy (CFAllocatorRef allocator, CFIndex capacity,
  CFDictionaryRef theDict);

//
// Modifying a Dictionary
//

/*  
  Adds the key-value pair to the dictionary if no such key already exists.
*/
void
CFDictionaryAddValue (CFMutableDictionaryRef theDict, const void *key,
  const void *value);

/*
  Removes all the values from the dictionary, making it empty.
*/
void
CFDictionaryRemoveAllValues (CFMutableDictionaryRef theDict);

/*
  Removes the value of the key from the dictionary.
  If a key which matches this key is present in the dictionary, 
  the key-value pair is removed from the dictionary, otherwise 
  this function does nothing ("remove if present").
*/
void
CFDictionaryRemoveValue (CFMutableDictionaryRef theDict, const void *key);

/*
  @function CFDictionaryReplaceValue
  Replaces the value of the key in the dictionary.
  If a key which matches this key is present in the dictionary, 
  the value is changed to the given value, otherwise this function does
  nothing ("replace if present").
*/
void
CFDictionaryReplaceValue (CFMutableDictionaryRef theDict, const void *key,
  const void *value);

/*
  Sets the value of the key in the dictionary.
  If a key which matches this key is already present in the dictionary, 
  only the value is changed ("add if absent, replace if present"). If
  no key matches the given key, the key-value pair is added to the
  dictionary.
*/
void
CFDictionarySetValue (CFMutableDictionaryRef theDict, const void *key,
  const void *value);

CF_EXTERN_C_END

#endif /* __COREFOUNDATION_CFDICTIONARY_H__ */
