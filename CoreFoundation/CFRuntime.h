/* CFRuntime.h
   
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

   Edited by: Ahmed Elmorsy, Mohamed Abd Elsalam
   Date: September 2012

*/

#ifndef __CFRuntime_h_GNUSTEP_COREBASE_INCLUDE
#define __CFRuntime_h_GNUSTEP_COREBASE_INCLUDE

#include <CoreFoundation/CFBase.h>
#include <CoreFoundation/CFDictionary.h>

CF_EXTERN_C_BEGIN

CF_EXPORT Boolean kCFUseCollectableAllocator;
CF_EXPORT Boolean (*__CFObjCIsCollectable)(void *);

// is Garbage Collector on?
#define CF_USING_COLLECTABLE_MEMORY (kCFUseCollectableAllocator)
// is Garbage Collector on and is this the GC allocator?
#define CF_IS_COLLECTABLE_ALLOCATOR(allocator) \
  (kCFUseCollectableAllocator \
  && (NULL == (allocator) \
      || kCFAllocatorSystemDefault == (allocator) \
      || _CFAllocatorIsGCRefZero(allocator)))
// is this allocated by the collector?
#define CF_IS_COLLECTABLE(obj) \
  (__CFObjCIsCollectable ? __CFObjCIsCollectable((void*)obj) : false)

enum
{
  _kCFRuntimeNotATypeID = 0
};

// Version field constants
enum
{
  _kCFRuntimeScannedObject =     (1UL<<0),
  _kCFRuntimeResourcefulObject = (1UL<<2),
  _kCFRuntimeCustomRefCount =    (1UL<<3)
};

typedef struct __CFRuntimeClass CFRuntimeClass;
struct __CFRuntimeClass
{
  CFIndex version;
  // must be a pure ASCII string, nul-terminated
  const char *className;
  void (*init)(CFTypeRef cf);
  CFTypeRef (*copy)(CFAllocatorRef allocator, CFTypeRef cf);
#if MAC_OS_X_VERSION_10_2 <= MAC_OS_X_VERSION_MAX_ALLOWED
  void (*finalize)(CFTypeRef cf);
#else
  void (*dealloc)(CFTypeRef cf);
#endif
  Boolean (*equal)(CFTypeRef cf1, CFTypeRef cf2);
  CFHashCode (*hash)(CFTypeRef cf);
  // return str with retain
  CFStringRef (*copyFormattingDesc)(CFTypeRef cf, CFDictionaryRef formatOptions);
  // return str with retain
  CFStringRef (*copyDebugDesc)(CFTypeRef cf);
#if MAC_OS_X_VERSION_10_5 <= MAC_OS_X_VERSION_MAX_ALLOWED
#define CF_RECLAIM_AVAILABLE 1
  // Set _kCFRuntimeResourcefulObject in the .version 
  //to indicate this field should be used
  void (*reclaim)(CFTypeRef cf); // _kCFRuntimeResourcefulObject
#endif
#if MAC_OS_X_VERSION_10_7 <= MAC_OS_X_VERSION_MAX_ALLOWED
#define CF_REFCOUNT_AVAILABLE 1
  // Set _kCFRuntimeCustomRefCount in the .version 
  // to indicate this field should be used
  UInt32 (*refcount)(intptr_t op, CFTypeRef cf); // _kCFRuntimeCustomRefCount
#endif
};

/** Registers a new class with the CF runtime.  Pass in a
   pointer to a CFRuntimeClass structure.  The pointer is
   remembered by the CF runtime -- the structure is NOT
   copied.  This function locks the class table and so is thread-safe.
    
    @param cls A constant CFRuntimeClass.
    @see _CFRuntimeUnregisterClassWithTypeID()
 */
/* 
 * RuntimeClass properties
 *
 * - version field must be zero currently.
 * - className field points to a null-terminated C string
 *   containing only ASCII (0 - 127) characters; this field
 *   may NOT be NULL.
 * - init field points to a function which classes can use to
 *   apply some generic initialization to instances as they
 *   are created; this function is called by both
 *   _CFRuntimeCreateInstance and _CFRuntimeInitInstance; if
 *   this field is NULL, no function is called; the instance
 *   has been initialized enough that the polymorphic funcs
 *   CFGetTypeID(), CFRetain(), CFRelease(), CFGetRetainCount(),
 *   and CFGetAllocator() are valid on it when the init
 *   function if any is called.
 * - finalize field points to a function which destroys an
 *   instance when the retain count has fallen to zero; if
 *   this is NULL, finalization does nothing. Note that if
 *   the class-specific functions which create or initialize
 *   instances more fully decide that a half-initialized
 *   instance must be destroyed, the finalize function for
 *   that class has to be able to deal with half-initialized
 *   instances.  The finalize function should NOT destroy the
 *   memory for the instance itself; that is done by the
 *   CF runtime after this finalize callout returns.
 * - equal field points to an equality-testing function; this
 *   field may be NULL, in which case only pointer/reference
 *   equality is performed on instances of this class. 
 *   Pointer equality is tested, and the type IDs are checked
 *   for equality, before this function is called (so, the
 *   two instances are not pointer-equal but are of the same
 *   class before this function is called).
 * NOTE: the equal function must implement an immutable
 *   equality relation, satisfying the reflexive, symmetric,
 *    and transitive properties, and remains the same across
 *   time and immutable operations (that is, if equal(A,B) at
 *   some point, then later equal(A,B) provided neither
 *   A or B has been mutated).
 * - hash field points to a hash-code-computing function for
 *   instances of this class; this field may be NULL in which
 *   case the pointer value of an instance is converted into
 *   a hash.
 * NOTE: the hash function and equal function must satisfy
 *   the relationship "equal(A,B) implies hash(A) == hash(B)";
 *   that is, if two instances are equal, their hash codes must
 *   be equal too. (However, the converse is not true!)
 * - copyFormattingDesc field points to a function returning a
 *   CFStringRef with a human-readable description of the
 *   instance; if this is NULL, the type does not have special
 *   human-readable string-formats.
 * - copyDebugDesc field points to a function returning a
 *   CFStringRef with a debugging description of the instance;
 *   if this is NULL, a simple description is generated.
 *
 * This function returns _kCFRuntimeNotATypeID on failure, or
 * on success, returns the CFTypeID for the new class.  This
 * CFTypeID is what the class uses to allocate or initialize
 * instances of the class. It is also returned from the
 * conventional *GetTypeID() function, which returns the
 * class's CFTypeID so that clients can compare the
 * CFTypeID of instances with that of a class.
 *
 * The function to compute a human-readable string is very
 * optional, and is really only interesting for classes,
 * like strings or numbers, where it makes sense to format
 * the instance using just its contents.
 */
 
 /*
- Register any CFRuntimeClass.This method put CFRunTime in last index of array, and return that index.  
- @params : pointer of CFRuntimeClass 
- @return : CFTypeID
*/
CFTypeID
_CFRuntimeRegisterClass (const CFRuntimeClass * const cls);

/** Gets the class structure associated with the @a typeID.
    
    @param typeID A CFTypeID to look up.
    @return The CFRuntimeClass for the @typeID
 */
const CFRuntimeClass *
_CFRuntimeGetClassWithTypeID (CFTypeID typeID);

/** Unregisters a class.
    @warning This function is not thread-safe.
    
    @param typeID The CFTypeID to unregister.
    @see _CFRuntimeRegisterClass()
 */
void
_CFRuntimeUnregisterClassWithTypeID (CFTypeID typeID);


/* All CF "instances" start with this structure.  Never refer to
 * these fields directly -- they are for CF's use and may be added
 * to or removed or change format without warning.  Binary
 * compatibility for uses of this struct is not guaranteed from
 * release to release.
 */

 //NOTE: this is different from what is in apple open source
 //CFRuntime.
typedef struct __CFRuntimeBase CFRuntimeBase;
/*
- CFRunTimeBase is parent to all CF  CLasses , so every CF instance has CFRunTimeClass
- every instance point to its Class which it instance of it 
- Example if i have CFArray instance , so isa is pointer to CFArrayRef
*/
struct __CFRuntimeBase
{
  void *_isa; // pointer to CFRunTimeClass
  SInt16 _typeID;
  struct
    {
      SInt16 ro:       1; // 0 = read-only object
      SInt16 reserved: 7; // For internal CFRuntime use
      SInt16 info:     8; // Can be used by CF type
    } _flags;
};


#define INIT_CFRUNTIME_BASE(...) { 0, 0, { 1, 0, 0 } }

/** Creates a new CF instance.
    
    @param allocator The CFAllocatorRef to use or NULL for the default
    allocator.
    @param typeID The CFTypeID of the class.
    @param extraBytes The amount of extra bytes over a CFRuntimeBase type
    needed by this instance.
    @param category Currently unused, use NULL.
    @return A newly allocator object.
    @see CFRetain()
    @see CFRelease()
 */
/* Creates a new CF instance of the class specified by the
   * given CFTypeID, using the given allocator, and returns it. 
   * If the allocator returns NULL, this function returns NULL.
   * A CFRuntimeBase structure is initialized at the beginning
   * of the returned instance.  extraBytes is the additional
   * number of bytes to allocate for the instance (BEYOND that
   * needed for the CFRuntimeBase).  If the specified CFTypeID
   * is unknown to the CF runtime, this function returns NULL.
   * No part of the new memory other than base header is
   * initialized (the extra bytes are not zeroed, for example).
   * All instances created with this function must be destroyed
   * only through use of the CFRelease() function -- instances
   * must not be destroyed by using CFAllocatorDeallocate()
   * directly, even in the initialization or creation functions
   * of a class.  Pass NULL for the category parameter.
   */
CFTypeRef
_CFRuntimeCreateInstance (CFAllocatorRef allocator, CFTypeID typeID,
                          CFIndex extraBytes, unsigned char *category);

/** Sets the CFTypeID for an instance.
    
    @param cf The object instance to set the type ID.
    @param typeID The new CFTypeID.
 */
/* This function changes the typeID of the given instance.
   * If the specified CFTypeID is unknown to the CF runtime,
   * this function does nothing.  This function CANNOT be used
   * to initialize an instance.  It is for advanced usages such
   * as faulting. You cannot change the CFTypeID of an object
   * of a _kCFRuntimeCustomRefCount class, or to a 
         * _kCFRuntimeCustomRefCount class.
   */
void
_CFRuntimeSetInstanceTypeID (CFTypeRef cf, CFTypeID typeID);

/** Initializes a static CF object instance.
    
    @param memory A pointer to a static CF object instance.
    @param typeID The CFTypeID of the instance.
 */
/* This function initializes a memory block to be a constant
 * (unreleaseable) CF object of the given typeID.
 * If the specified CFTypeID is unknown to the CF runtime,
 * this function does nothing.  The memory block should
 * be a chunk of in-binary writeable static memory, and at
 * least as large as sizeof(CFRuntimeBase) on the platform
 * the code is being compiled for.  The init function of the
 * CFRuntimeClass is invoked on the memory as well, if the
 * class has one. Static instances cannot be initialized to
 * _kCFRuntimeCustomRefCount classes.
 */
void
_CFRuntimeInitStaticInstance (void *memory, CFTypeID typeID);

#define CF_HAS_INIT_STATIC_INSTANCE 1

void CFAllocatorInitialize (void);
void CFArrayInitialize (void);
void CFAttributedStringInitialize (void);
void CFBagInitialize (void);
void CFBinaryHeapInitialize (void);
void CFBitVectorInitialize (void);
void CFBooleanInitialize (void);
void CFCalendarInitialize (void);
void CFCharacterSetInitialize (void);
void CFDataInitialize (void);
void CFDateInitialize (void);
void CFDateFormatterInitialize (void);
void CFDictionaryInitialize (void);
void CFErrorInitialize (void);
void CFLocaleInitialize (void);
void CFNullInitialize (void);
void CFNumberInitialize (void);
void CFNumberFormatterInitialize (void);
void CFRunLoopInitialize (void);
void CFSetInitialize (void);
void CFStringInitialize (void);
void CFStringEncodingInitialize (void);
void CFTimeZoneInitialize (void);
void CFTreeInitialize (void);
void CFURLInitialize (void);
void CFUUIDInitialize (void);
void CFXMLNodeInitialize (void);

CF_EXTERN_C_END

#endif /* __CFRuntime_h_GNUSTEP_COREBASE_INCLUDE */
