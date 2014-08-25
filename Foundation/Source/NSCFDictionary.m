/* NSCFDictionary.m
   
   Copyright (C) 2012 MyUIKit.
   
   Written by: Ahmed Elmorsy
   Date: August, 2012
   
   This file is part of MyUIKit Library.
*/

#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSCFType.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSException.h>
#import <CoreFoundation/CFDictionary.h>
#import <CoreFoundation/CFArray.h>

@interface NSCFDictionary : NSMutableDictionary
@end

@interface NSCFDictionaryKeyEnumerator : NSEnumerator
{
  NSCFDictionary    *dictionary;
  CFArrayRef collection;
  unsigned pos;
}
- (id) initWithDictionary: (NSCFDictionary*)d;
@end

@interface NSCFDictionaryObjectEnumerator : NSCFDictionaryKeyEnumerator
@end


@implementation NSCFDictionary
+ (void) load
{
  NSCFInitialize ();
}

- (NSUInteger) count
{
  return (NSUInteger)CFDictionaryGetCount (self);
}

- (NSArray *)allKeys
{
  CFIndex keysCount = CFDictionaryGetCount(self);
  const void* keys[keysCount];
  CFDictionaryGetKeysAndValues(self, keys, NULL);
  return CFArrayCreate(NULL, keys, keysCount, NULL);
}

- (NSArray *)allKeysForObject:(id)anObject
{
  CFArrayRef keys = [self allKeys];
  CFMutableArrayRef result = CFArrayCreateMutable(NULL, 0, NULL);
  for (id key in keys) {
    if ([self valueForKey: key] == anObject) {
      CFArrayAppendValue(result, key);
    }
  }
  CFRelease(keys);
  return result;
}

- (NSArray *)allValues
{
  CFIndex valuesCount = CFDictionaryGetCount(self);
  const void* values[valuesCount];
  CFDictionaryGetKeysAndValues(self, NULL, values);
  return CFArrayCreate(NULL, values, valuesCount, NULL);
}

- (void)getObjects:(id __unsafe_unretained [])objects 
        andKeys:(id __unsafe_unretained [])keys
{
  CFDictionaryGetKeysAndValues(self, (const void **)keys, (const void **)objects);
}

- (id)objectForKey:(id)aKey
{
  return (id) CFDictionaryGetValue(self, (const void*) aKey);
}

- (id)objectForKeyedSubscript:(id)key
{
  return (id) CFDictionaryGetValue(self, (const void*) key);
}

- (NSArray *)objectsForKeys:(NSArray *)keys notFoundMarker:(id)anObject
{
  NSMutableArray* result = [[NSMutableArray alloc] initWithArray: keys];
  int i = 0;
  for (id key in keys) {
    if (! CFDictionaryGetValueIfPresent(self, (const void*) key
      , (const void**)[result objectAtIndex: i]))
    {
      [[result objectAtIndex:i] replaceObjectAtIndex:i withObject:anObject];
    }
    i++;
  }
  return result;
}

- (id)valueForKey:(NSString *)key
{
  return (id) CFDictionaryGetValue(self, (const void*) key);
}

- (NSEnumerator*) keyEnumerator
{
  return AUTORELEASE([[NSCFDictionaryKeyEnumerator allocWithZone:
    NSDefaultMallocZone()] initWithDictionary: self]);
}

- (NSEnumerator*) objectEnumerator
{
  return AUTORELEASE([[NSCFDictionaryObjectEnumerator allocWithZone:
    NSDefaultMallocZone()] initWithDictionary: self]);
}

- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState*)state  
           objects: (__unsafe_unretained id[])stackbuf
             count: (NSUInteger)len
{
  if (state->state >= [self count]) {
    return 0;
  }
  state->mutationsPtr = (unsigned long *)self;
  NSEnumerator* enumerator = [self keyEnumerator];
  id setObject;
  int i = 0;
  while ((setObject = [enumerator nextObject]) != nil)
  {
      stackbuf[i++] = setObject;
  }
  state->state = i;
  state->itemsPtr = stackbuf;
  return i;
}


- (void) setObject: (id)anObject forKey: (id)aKey
{
  if (aKey == nil)
  {
    NSException *e;

    e = [NSException exceptionWithName: NSInvalidArgumentException
        reason: @"Tried to add nil key to dictionary"
      userInfo: self];
    [e raise];
  }
  if (anObject == nil)
  {
    NSException *e;
    NSString    *s;

    s = [NSString stringWithFormat:
      @"Tried to add nil value for key '%@' to dictionary", aKey];
    e = [NSException exceptionWithName: NSInvalidArgumentException
        reason: s
      userInfo: self];
    [e raise];
  }
  CFDictionarySetValue (self, (const void *) aKey, (const void *)anObject);
}

- (void) removeAllObjects
{
  CFDictionaryRemoveAllValues (self);
}

- (void) removeObjectForKey: (id)aKey
{
  if (aKey == nil)
    {
      NSLog(@"attempt to remove nil key from dictionary %@", self);
      return;
    }
  CFDictionaryRemoveValue(self, (const void *)aKey);
}

- (void) dealloc
{
  CFRelease(self);
}

@end

@implementation NSCFDictionaryKeyEnumerator

- (id) initWithDictionary: (NSCFDictionary*)d
{
  self = [super init];
  if (self)
  {
    dictionary = (NSCFDictionary*)RETAIN(d);
    collection = [dictionary allKeys];
    pos = 0;
  }
  return self;
}

- (id) nextObject
{
  if (pos == [dictionary count])
  {
    return nil;
  }
  return CFArrayGetValueAtIndex(collection, pos++);
}

- (void) dealloc
{
  RELEASE(dictionary);
  CFRelease(collection);
  [super dealloc];
}

@end

@implementation NSCFDictionaryObjectEnumerator

- (id) initWithDictionary: (NSCFDictionary*)d
{
  self = [super init];
  if (self) {
    dictionary = (NSCFDictionary*)RETAIN(d);
    collection = [d allValues];
    pos = 0;
  }
  return self;
}

- (void) dealloc
{
  RELEASE(dictionary);
  CFRelease(collection);
  [super dealloc];
}

@end
