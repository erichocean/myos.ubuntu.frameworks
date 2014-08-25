/* CFSet.c
   
   Copyright (C) 2011 Free Software Foundation, Inc.
   
   Written by: Stefan Bidigaray
   Date: November, 2011
   
   This file is part of GNUstep CoreBase Library.
   
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
   Date: October, 2012
*/

#include <stdlib.h>
#include <CoreFoundation/CFRuntime.h>
#include <CoreFoundation/CFBase.h>
#include <CoreFoundation/CFSet.h>
#include <CoreFoundation/CFString.h>
#include <CoreFoundation/GSHashTable.h>
#include <CoreFoundation/GSPrivate.h>

static CFTypeID _kCFSetTypeID = 0;

static void
CFSetFinalize (CFTypeRef cf)
{
  GSHashTableFinalize ((GSHashTableRef)cf);
}

static Boolean
CFSetEqual (CFTypeRef cf1, CFTypeRef cf2)
{
  return GSHashTableEqual ((GSHashTableRef)cf1, (GSHashTableRef)cf2);
}

static CFHashCode
CFSetHash (CFTypeRef cf)
{
  return GSHashTableHash ((GSHashTableRef)cf);
}

static CFStringRef
CFSetCopyFormattingDesc (CFTypeRef cf, CFDictionaryRef formatOptions)
{
  return CFSTR("");
}

static CFRuntimeClass CFSetClass =
{
  0,
  "CFSet",
  NULL,
  (CFTypeRef(*)(CFAllocatorRef, CFTypeRef))CFSetCreateCopy,
  CFSetFinalize,
  CFSetEqual,
  CFSetHash,
  CFSetCopyFormattingDesc,
  NULL
};

void CFSetInitialize (void)
{
  _kCFSetTypeID = _CFRuntimeRegisterClass (&CFSetClass);
}



const CFSetCallBacks kCFCopyStringSetCallBacks =
{
  0,
  (CFTypeRef (*)(CFAllocatorRef, CFTypeRef))CFStringCreateCopy,
  CFTypeReleaseCallBack,
  CFCopyDescription,
  CFEqual,
  CFHash
};

const CFSetCallBacks kCFTypeSetCallBacks =
{
  0,
  CFTypeRetainCallBack,
  CFTypeReleaseCallBack,
  CFCopyDescription,
  CFEqual,
  CFHash
};



CFSetRef
CFSetCreate (CFAllocatorRef allocator, const void **values, CFIndex numValues,
  const CFSetCallBacks *callBacks)
{
  return (CFSetRef)GSHashTableCreate (allocator, _kCFSetTypeID,
    values, values, numValues,
    (const GSHashTableKeyCallBacks*)callBacks, NULL);
}

CFSetRef
CFSetCreateCopy (CFAllocatorRef allocator, CFSetRef set)
{
  CF_OBJC_FUNCDISPATCH0(_kCFSetTypeID, CFSetRef, set, "copy");
  return (CFSetRef)GSHashTableCreateCopy (allocator, (GSHashTableRef)set);
}

void
CFSetApplyFunction (CFSetRef set,
  CFSetApplierFunction applier, void *context)
{
  CFIndex i;
  int count = CFSetGetCount(set);
  const void **values = malloc(count * sizeof(void*));
  CFSetGetValues(set, values);
  for (i = 0; i < count; i++)
    applier(values[i], context);

}

Boolean
CFSetContainsValue (CFSetRef set, const void *value)
{
  CF_OBJC_FUNCDISPATCH1(_kCFSetTypeID, Boolean, set, "containsObject:", value);
  return GSHashTableContainsKey ((GSHashTableRef)set, value);
}

CFIndex
CFSetGetCount (CFSetRef set)
{
  CF_OBJC_FUNCDISPATCH0(_kCFSetTypeID, CFIndex, set, "count");
  return GSHashTableGetCount ((GSHashTableRef)set);
}

CFIndex
CFSetGetCountOfValue (CFSetRef set, const void *value)
{
  if (CF_IS_OBJC(_kCFSetTypeID, set))
  {
    Boolean (*imp)(id, SEL, ...);
    static SEL s = NULL;
    if (!s)
      s = sel_registerName("containsObject:");
    imp = (Boolean (*)(id, SEL, ...))
      class_getMethodImplementation (object_getClass((id)set), s);
    return imp((id)set, s, value)? 1: 0;
  }
  return GSHashTableGetCountOfKey ((GSHashTableRef)set, value) > 0 ? 1 : 0;
}

void
CFSetGetValues (CFSetRef set, const void **values)
{
  if (CF_IS_OBJC(_kCFSetTypeID, set))
  {
    CFArrayRef (*imp)(id, SEL);
    static SEL s = NULL;
    if (!s)
      s = sel_registerName("allObjects");
    imp = (CFArrayRef (*)(id, SEL))
      class_getMethodImplementation (object_getClass((id)set), s);
    CFArrayRef result = imp((id)set, s);
    CFArrayGetValues(result, CFRangeMake(0, CFArrayGetCount(result)), values);
    return;
  }
  GSHashTableGetKeysAndValues ((GSHashTableRef)set, values, NULL);
}

const void *
CFSetGetValue (CFSetRef set, const void *value)
{
  CF_OBJC_FUNCDISPATCH1(_kCFSetTypeID, const void*, set, "member:", value);
  return GSHashTableGetValue ((GSHashTableRef)set, value);
}

Boolean
CFSetGetValueIfPresent (CFSetRef set,
  const void *candidate, const void **value)
{
  if (CF_IS_OBJC(_kCFSetTypeID, set))
  {
    const void* (*imp)(id, SEL, ...);
    static SEL s = NULL;
    if (!s)
      s = sel_registerName("member:");
    imp = (const void* (*)(id, SEL, ...))
    class_getMethodImplementation (object_getClass((id)set), s);
    *value = imp((id)set, s, candidate);
    return *value != NULL;
  }
  const void *v;
  
  v = CFSetGetValue (set, candidate);
  if (v) {
    if (value)
      *value = v;
    return true;
  }
  
  return false;
}

CFTypeID
CFSetGetTypeID (void)
{
  return _kCFSetTypeID;
}

//
// CFMutableSet
//
CFMutableSetRef
CFSetCreateMutable (CFAllocatorRef allocator, CFIndex capacity,
  const CFSetCallBacks *callBacks)
{
  return (CFMutableSetRef)GSHashTableCreateMutable (allocator, _kCFSetTypeID,
    capacity, (const GSHashTableKeyCallBacks*)callBacks, NULL);
}

CFMutableSetRef
CFSetCreateMutableCopy (CFAllocatorRef allocator, CFIndex capacity,
  CFSetRef set)
{
  return (CFMutableSetRef)GSHashTableCreateMutableCopy (allocator,
    (GSHashTableRef)set, capacity);
}

void
CFSetAddValue (CFMutableSetRef set, const void *value)
{
  CF_OBJC_FUNCDISPATCH1(_kCFSetTypeID, void, set, "addObject:", value);
  GSHashTableAddValue ((GSHashTableRef)set, value, value);
}

void
CFSetRemoveAllValues (CFMutableSetRef set)
{
  CF_OBJC_FUNCDISPATCH0(_kCFSetTypeID, void, set, "removeAllObjects");
  GSHashTableRemoveAll ((GSHashTableRef)set);
}

void
CFSetRemoveValue (CFMutableSetRef set, const void *value)
{
  CF_OBJC_FUNCDISPATCH1(_kCFSetTypeID, void, set, "removeObject:", value);
  GSHashTableRemoveValue ((GSHashTableRef)set, value);
}

void
CFSetReplaceValue (CFMutableSetRef set, const void *value)
{
  if (CFSetContainsValue(set, value)) {
    if (CF_IS_OBJC(_kCFSetTypeID, set))
    {
      void (*imp1)(id, SEL, ...);
      static SEL s = NULL;
      if (!s)
        s = sel_registerName("removeObject:");
      imp1 = (void (*)(id, SEL, ...))
      class_getMethodImplementation (object_getClass((id)set), s);
      imp1((id)set, s, value);
      void (*imp2)(id, SEL, ...);
      s = NULL;
      if (!s)
        s = sel_registerName("addObject:");
      imp2 = (void (*)(id, SEL, ...))
      class_getMethodImplementation (object_getClass((id)set), s);
      imp2((id)set, s, value);
      return;
    }
    GSHashTableReplaceValue ((GSHashTableRef)set, value, value);
  }
}

void
CFSetSetValue (CFMutableSetRef set, const void *value)
{
  if (CFSetContainsValue(set, value))
    CFSetReplaceValue(set, value);
  //GSHashTableSetValue ((GSHashTableRef)set, value, value);
}
