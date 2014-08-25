/** NSCoder - coder object for serialization and persistance.
   Copyright (C) 1995, 1996 Free Software Foundation, Inc.

   Written by:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   From skeleton by:  Adam Fedor <fedor@boulder.colorado.edu>
   Date: Mar 1995

   This file is part of the GNUstep Base Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02111 USA.

   <title>NSCoder class reference</title>
   $Date: 2011-05-19 01:19:24 -0700 (Thu, 19 May 2011) $ $Revision: 33069 $
   */

#import "common.h"

#if !defined (__GNU_LIBOBJC__)
#  include <objc/encoding.h>
#endif

#define	EXPOSE_NSCoder_IVARS	1
#import "Foundation/NSData.h"
#import "Foundation/NSCoder.h"
#import "Foundation/NSSerialization.h"
#import "GNUstepBase/NSObject+GNUstepBase.h"

@implementation NSCoder

+ (void) initialize
{
  if (self == [NSCoder class])
    {
    }
}

- (void) encodeValueOfObjCType: (const char*)type
			    at: (const void*)address
{
  [self subclassResponsibility: _cmd];
}

- (void) decodeValueOfObjCType: (const char*)type
			    at: (void*)address
{
  [self subclassResponsibility: _cmd];
}

- (void) encodeDataObject: (NSData*)data
{
  [self subclassResponsibility: _cmd];
}

- (NSData*) decodeDataObject
{
  [self subclassResponsibility: _cmd];
  return nil;
}

- (NSInteger) versionForClassName: (NSString*)className
{
  [self subclassResponsibility: _cmd];
  return (NSInteger)NSNotFound;
}

// Encoding Data

- (void) encodeArrayOfObjCType: (const char*)type
			 count: (NSUInteger)count
			    at: (const void*)array
{
  unsigned	i;
  unsigned	size = objc_sizeof_type(type);
  const char	*where = array;
  IMP		imp;

  imp = [self methodForSelector: @selector(encodeValueOfObjCType:at:)];
  for (i = 0; i < count; i++, where += size)
    {
      (*imp)(self, @selector(encodeValueOfObjCType:at:), type, where);
    }
}

- (void) encodeBycopyObject: (id)anObject
{
  [self encodeObject: anObject];
}

- (void) encodeByrefObject: (id)anObject
{
  [self encodeObject: anObject];
}

- (void) encodeBytes: (void*)d length: (NSUInteger)l
{
  const char		*type = @encode(unsigned char);
  const unsigned char	*where = (const unsigned char*)d;
  IMP			imp;

  imp = [self methodForSelector: @selector(encodeValueOfObjCType:at:)];
  (*imp)(self, @selector(encodeValueOfObjCType:at:),
    @encode(unsigned), &l);
  while (l-- > 0)
    (*imp)(self, @selector(encodeValueOfObjCType:at:), type, where++);
}

- (void) encodeConditionalObject: (id)anObject
{
  [self encodeObject: anObject];
}

- (void) encodeObject: (id)anObject
{
  [self encodeValueOfObjCType: @encode(id) at: &anObject];
}

- (void) encodePropertyList: (id)plist
{
  id    anObject;

  anObject = plist ? (id)[NSSerializer serializePropertyList: plist] : nil;
  [self encodeValueOfObjCType: @encode(id) at: &anObject];
}

- (void) encodePoint: (NSPoint)point
{
  [self encodeValueOfObjCType: @encode(NSPoint) at: &point];
}

- (void) encodeRect: (NSRect)rect
{
  [self encodeValueOfObjCType: @encode(NSRect) at: &rect];
}

- (void) encodeRootObject: (id)rootObject
{
  [self encodeObject: rootObject];
}

- (void) encodeSize: (NSSize)size
{
  [self encodeValueOfObjCType: @encode(NSSize) at: &size];
}

- (void) encodeValuesOfObjCTypes: (const char*)types,...
{
  va_list	ap;
  IMP		imp;

  imp = [self methodForSelector: @selector(encodeValueOfObjCType:at:)];
  va_start(ap, types);
  while (*types)
    {
      (*imp)(self, @selector(encodeValueOfObjCType:at:), types,
	va_arg(ap, void*));
      types = objc_skip_typespec(types);
    }
  va_end(ap);
}

// Decoding Data

- (void) decodeArrayOfObjCType: (const char*)type
			 count: (NSUInteger)count
			    at: (void*)address
{
  unsigned	i;
  unsigned	size = objc_sizeof_type(type);
  char		*where = address;
  IMP		imp;

  imp = [self methodForSelector: @selector(decodeValueOfObjCType:at:)];

  for (i = 0; i < count; i++, where += size)
    {
      (*imp)(self, @selector(decodeValueOfObjCType:at:), type, where);
    }
}

- (void*) decodeBytesWithReturnedLength: (NSUInteger*)l
{
  unsigned int	count;
  const char	*type = @encode(unsigned char);
  unsigned char	*where;
  unsigned char	*array;
  IMP		imp;

  imp = [self methodForSelector: @selector(decodeValueOfObjCType:at:)];

  (*imp)(self, @selector(decodeValueOfObjCType:at:),
    @encode(unsigned int), &count);
  *l = (NSUInteger)count;
  array = NSZoneMalloc(NSDefaultMallocZone(), count);
  where = array;
  while (count-- > 0)
    {
      (*imp)(self, @selector(decodeValueOfObjCType:at:), type, where++);
    }

  [NSData dataWithBytesNoCopy: array length: count];
  return array;
}

- (id) decodeObject
{
  id	o;

  [self decodeValueOfObjCType: @encode(id) at: &o];
  return AUTORELEASE(o);
}

- (id) decodePropertyList
{
  id	o;
  id	d;

  [self decodeValueOfObjCType: @encode(id) at: &d];
  if (d != nil)
    {
      o = [NSDeserializer deserializePropertyListFromData: d
                                        mutableContainers: NO];
      RELEASE(d);
    }
  else
    {
      o = nil;
    }
  return o;
}

- (NSPoint) decodePoint
{
  NSPoint	point;

  [self decodeValueOfObjCType: @encode(NSPoint) at: &point];
  return point;
}

- (NSRect) decodeRect
{
  NSRect	rect;

  [self decodeValueOfObjCType: @encode(NSRect) at: &rect];
  return rect;
}

- (NSSize) decodeSize
{
  NSSize	size;

  [self decodeValueOfObjCType: @encode(NSSize) at: &size];
  return size;
}

- (void) decodeValuesOfObjCTypes: (const char*)types,...
{
  va_list	ap;
  IMP		imp;

  imp = [self methodForSelector: @selector(decodeValueOfObjCType:at:)];
  va_start(ap, types);
  while (*types)
    {
      (*imp)(self, @selector(decodeValueOfObjCType:at:),
	types, va_arg(ap, void*));
      types = objc_skip_typespec(types);
    }
  va_end(ap);
}

// Managing Zones

- (NSZone*) objectZone
{
  return NSDefaultMallocZone();
}

- (void) setObjectZone: (NSZone*)zone
{
  ;
}


// Getting a Version

- (unsigned) systemVersion
{
  return (((GNUSTEP_BASE_MAJOR_VERSION * 100)
    + GNUSTEP_BASE_MINOR_VERSION) * 100) + GNUSTEP_BASE_SUBMINOR_VERSION;
}


// Keyed archiving extensions

- (BOOL) allowsKeyedCoding
{
  return NO;
}

- (BOOL) containsValueForKey: (NSString*)aKey
{
  [self subclassResponsibility: _cmd];
  return NO;
}

- (BOOL) decodeBoolForKey: (NSString*)aKey
{
  [self subclassResponsibility: _cmd];
  return NO;
}

- (const uint8_t*) decodeBytesForKey: (NSString*)aKey
		      returnedLength: (NSUInteger*)alength
{
  [self subclassResponsibility: _cmd];
  return 0;
}

- (double) decodeDoubleForKey: (NSString*)aKey
{
  [self subclassResponsibility: _cmd];
  return 0.0;
}

- (float) decodeFloatForKey: (NSString*)aKey
{
  [self subclassResponsibility: _cmd];
  return 0.0;
}

- (int) decodeIntForKey: (NSString*)aKey
{
  [self subclassResponsibility: _cmd];
  return 0;
}

- (NSInteger) decodeIntegerForKey: (NSString*)key
{
  [self subclassResponsibility: _cmd];
  return 0;
}

- (int32_t) decodeInt32ForKey: (NSString*)aKey
{
  [self subclassResponsibility: _cmd];
  return 0;
}

- (int64_t) decodeInt64ForKey: (NSString*)aKey
{
  [self subclassResponsibility: _cmd];
  return 0;
}

- (id) decodeObjectForKey: (NSString*)aKey
{
  [self subclassResponsibility: _cmd];
  return nil;
}

- (void) encodeBool: (BOOL) aBool forKey: (NSString*)aKey
{
  [self subclassResponsibility: _cmd];
}

- (void) encodeBytes: (const uint8_t*)aPointer
	      length: (NSUInteger)length
	      forKey: (NSString*)aKey
{
  [self subclassResponsibility: _cmd];
}

- (void) encodeConditionalObject: (id)anObject forKey: (NSString*)aKey
{
  [self subclassResponsibility: _cmd];
}

- (void) encodeDouble: (double)aDouble forKey: (NSString*)aKey
{
  [self subclassResponsibility: _cmd];
}

- (void) encodeFloat: (float)aFloat forKey: (NSString*)aKey
{
  [self subclassResponsibility: _cmd];
}

- (void) encodeInt: (int)anInteger forKey: (NSString*)aKey
{
  [self subclassResponsibility: _cmd];
}

- (void) encodeInteger: (NSInteger)anInteger forKey: (NSString*)key
{
  [self subclassResponsibility: _cmd];
}

- (void) encodeInt32: (int32_t)anInteger forKey: (NSString*)aKey
{
  [self subclassResponsibility: _cmd];
}

- (void) encodeInt64: (int64_t)anInteger forKey: (NSString*)aKey
{
  [self subclassResponsibility: _cmd];
}

- (void) encodeObject: (id)anObject forKey: (NSString*)aKey
{
  [self subclassResponsibility: _cmd];
}

@end



#import	"GSPrivate.h"

@implementation	_NSKeyedCoderOldStyleArray
- (const void*) bytes
{
  return _a;
}
- (NSUInteger) count
{
  return _c;
}
- (void) dealloc
{
  DESTROY(_d);
  [super dealloc];
}
- (id) initWithCoder: (NSCoder*)aCoder
{
  id		o;
  void		*address;
  unsigned	i;

  _c = [aCoder decodeIntForKey: @"NS.count"];
  _t[0] = (char)[aCoder decodeIntForKey: @"NS.type"];
  _t[1] = '\0';

  /*
   * We decode the size from the remote end, but discard it as we
   * are probably safer to use the local size of the datatype involved.
   */
  _s = [aCoder decodeIntForKey: @"NS.size"];
  _s = objc_sizeof_type(_t);

  _d = o = [[NSMutableData alloc] initWithLength: _c * _s];
  _a = address = [o mutableBytes];
  for (i = 0; i < _c; i++)
    {
      [aCoder decodeValueOfObjCType: _t at: address];
      address += _s;
    }
  return self;
}

- (id) initWithObjCType: (const char*)t count: (NSInteger)c at: (const void*)a
{
  _t[0] = *t;
  _t[1] = '\0';
  _s = objc_sizeof_type(_t);
  _c = c;
  _a = a;
  return self;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  int	i;

  [aCoder encodeInt: _c forKey: @"NS.count"];
  [aCoder encodeInt: *_t forKey: @"NS.type"];
  [aCoder encodeInt: _s forKey: @"NS.size"];
  for (i = 0; i < _c; i++)
    {
      [aCoder encodeValueOfObjCType: _t at: _a];
      _a += _s;
    }
}

- (NSUInteger) size
{
  return _s;
}

- (const char*) type
{
  return _t;
}
@end

