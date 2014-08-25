/* NSCFArray.m
   
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
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

#import <Foundation/NSArray.h>

#import <Foundation/NSCFType.h>
#import <Foundation/NSEnumerator.h>
#import <CoreFoundation/CFArray.h>

@interface NSCFArray : NSMutableArray
@end

@interface NSCFArrayEnumerator : NSEnumerator
{
  NSCFArray *array;
  unsigned  pos;
}
- (id) initWithArray: (NSCFArray*)anArray;
@end

@interface NSCFArrayEnumeratorReverse : NSCFArrayEnumerator
@end

@implementation NSCFArray
+ (void) load
{
  NSCFInitialize ();
}

- (NSUInteger) count
{
  return (NSUInteger)CFArrayGetCount (self);
}

- (id) objectAtIndex: (NSUInteger) index
{
  return (id)CFArrayGetValueAtIndex (self, (CFIndex)index);
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
  return (id)CFArrayGetValueAtIndex (self, (CFIndex)idx);
}

-(void) addObject: (id) anObject
{
  CFArrayAppendValue (self, (const void*)anObject);
}

- (void) replaceObjectAtIndex: (NSUInteger) index withObject: (id) anObject
{
  CFArraySetValueAtIndex (self, (CFIndex)index, (const void*)anObject);
}

- (void) insertObject: (id) anObject atIndex: (NSUInteger) index
{
  CFArrayInsertValueAtIndex (self, (CFIndex)index, (const void*)anObject);
}

- (void) removeLastObject
{
  CFArrayRemoveValueAtIndex(self, CFArrayGetCount(self)-1);
}

- (void)removeObject:(id)anObject
{
    if (anObject == nil) {
        NSLog(@"attempt to remove nil object");
        return;
    }
    CFIndex i;
    for (i = 0; i < CFArrayGetCount(self);) {
        if (CFEqual(CFArrayGetValueAtIndex(self, i), anObject)) {
            CFArrayRemoveValueAtIndex(self, i);
        } else {
            i++;
        }
    }
}

- (void) removeObjectAtIndex: (NSUInteger) index
{
  CFArrayRemoveValueAtIndex (self, (CFIndex)index);
}

- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState*)state  
           objects: (__unsafe_unretained id[])stackbuf
             count: (NSUInteger)len
{
  NSUInteger size = [self count];
  NSInteger count;

  /* This is cached in the caller at the start and compared at each
   * iteration.   If it changes during the iteration then
   * objc_enumerationMutation() will be called, throwing an exception.
   */
  state->mutationsPtr = (unsigned long *)self;
  count = MIN(len, size - state->state);
  /* If a mutation has occurred then it's possible that we are being asked to
   * get objects from after the end of the array.  Don't pass negative values
   * to memcpy.
   */
  if (count > 0)
  {
      int p = state->state;
      int i;
      for (i = 0; i < count; i++, p++)
      {
        stackbuf[i] = [self objectAtIndex: p];
      }
      state->state += count;
  }
  else
  {
    count = 0;
  }
  state->itemsPtr = stackbuf;
  return count;
}

/**
 * Returns an enumerator describing the array sequentially
 * from the first to the last element.<br/>
 * If you use a mutable subclass of NSArray,
 * you should not modify the array during enumeration.
 */
- (NSEnumerator*) objectEnumerator
{
  id  e;

  e = [NSCFArrayEnumerator allocWithZone: NSDefaultMallocZone()];
  e = [e initWithArray: self];
  return AUTORELEASE(e);
}

/**
 * Returns an enumerator describing the array sequentially
 * from the last to the first element.<br/>
 * If you use a mutable subclass of NSArray,
 * you should not modify the array during enumeration.
 */
- (NSEnumerator*) reverseObjectEnumerator
{
  id  e;

  e = [NSCFArrayEnumeratorReverse allocWithZone: NSDefaultMallocZone()];
  e = [e initWithArray: self];
  return AUTORELEASE(e);
}

- (void) dealloc
{
  CFRelease(self);
}

@end

@implementation NSCFArrayEnumerator

- (id) initWithArray: (NSCFArray*)anArray
{
  self = [super init];
  if (self != nil)
    {
      array = anArray;
      IF_NO_GC(RETAIN(array));
      pos = 0;
    }
  return self;
}

/**
 * Returns the next object in the enumeration or nil if there are no more
 * objects.<br />
 * NB. modifying a mutable array during an enumeration can break things ...
 * don't do it.
 */
- (id) nextObject
{
  if (pos >= CFArrayGetCount(array))
    return nil;
  return CFArrayGetValueAtIndex(array, pos++);
}

- (void) dealloc
{
  RELEASE(array);
  [super dealloc];
}

@end

@implementation NSCFArrayEnumeratorReverse

- (id) initWithArray: (NSCFArray*)anArray
{
  self = [super initWithArray: anArray];
  if (self != nil)
    {
      pos = CFArrayGetCount(array);
    }
  return self;
}

/**
 * Returns the next object in the enumeration or nil if there are no more
 * objects.<br />
 * NB. modifying a mutable array during an enumeration can break things ...
 * don't do it.
 */
- (id) nextObject
{
  if (pos == 0)
    return nil;
  return CFArrayGetValueAtIndex(array, --pos);
}

- (void) dealloc
{
  RELEASE(array);
  [super dealloc];
}

@end
