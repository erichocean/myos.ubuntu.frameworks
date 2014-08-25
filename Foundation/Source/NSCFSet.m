/* NSCFSet.m
   
   Copyright (C) 2012 MyUIKit.
   
   Written by: Ahmed Elmorsy
   Date: August, 2012
   
   This file is part of MyUIKit Library.
*/

#import <Foundation/NSSet.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSCFType.h>
#import <Foundation/NSEnumerator.h>
#import <CoreFoundation/CFSet.h>
#import <CoreFoundation/CFArray.h>

@interface NSCFSet : NSMutableSet
@end

@interface NSCFSetEnumerator : NSEnumerator
{
  CFArrayRef set;
  unsigned  pos;
}
- (id) initWithSet: (NSCFSet*)aSet;
@end

@implementation NSCFSet
+ (void) load
{
  NSCFInitialize ();
}

- (NSUInteger) count
{
  return CFSetGetCount(self);
}

- (NSArray*) allObjects
{
  NSUInteger count = CFSetGetCount(self);
  const void** values = malloc(count * sizeof(void*));
  CFSetGetValues(self, values);
  return CFArrayCreate(NULL, values, count, NULL);
}

/**
 *  Return an arbitrary object from set, or nil if this is empty set.
 */
- (id) anyObject
{
  if ([self count] == 0)
    return nil;
  else
    {
      id e = [self objectEnumerator];
      return [e nextObject];
    }
}

- (BOOL) containsObject: (id)anObject
{
  return CFSetContainsValue(self, (const void*)anObject);
}

- (id)member:(id)object
{
  return (id) CFSetGetValue(self, (const void*)object);
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
  e = [NSCFSetEnumerator allocWithZone: NSDefaultMallocZone()];
  e = [e initWithSet: self];
  return AUTORELEASE(e);
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
      const void** values = malloc(size * sizeof(void*));
      CFSetGetValues(self, values);
      for (i = 0; i < count; i++, p++)
      {
        stackbuf[i] = (id)values[i];
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

- (void) dealloc
{
  CFRelease(self);
}

//mutable functions
- (void) addObject: (id)anObject
{
  CFSetAddValue(self, anObject);
}

- (void) removeObject: (id)anObject
{
  CFSetRemoveValue(self, anObject);
}

- (void) removeAllObjects
{
  CFSetRemoveAllValues(self);
}

- (void) addObjectsFromArray: (NSArray*)array
{
  unsigned  i, c = [array count];

  for (i = 0; i < c; i++) {
    [self addObject: [array objectAtIndex: i]];
  }
}

@end

@implementation NSCFSetEnumerator

- (id) initWithSet: (NSCFSet*)aSet
{
  self = [super init];
  if (self != nil) {
    const void** values;
    int length = CFSetGetCount(aSet);
    values = malloc(length * sizeof(const void*));
    CFSetGetValues(aSet, values);
    set = CFArrayCreate(NULL, values, length, NULL);
    IF_NO_GC(RETAIN(set));
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
  if (pos >= CFArrayGetCount(set))
    return nil;
  return CFArrayGetValueAtIndex(set, pos++);
}

- (void) dealloc
{
  RELEASE(set);
  [super dealloc];
}

@end