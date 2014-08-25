#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

int main (int argc, const char * argv[])
{
	
  NSAutoreleasePool *pool;
	pool = [NSAutoreleasePool new];

  NSSet *mySet;
  NSValue *aValue1 = [NSNumber numberWithInteger:5];
  NSValue *aValue2 = [NSNumber numberWithInteger:10];
  NSValue *aValue3 = [NSNumber numberWithInteger:5];
 
  mySet = [NSSet setWithObjects:aValue1, aValue2, aValue3, nil];

  for (id elem in mySet) {
    NSLog(@"%@", elem);
  }

  CFSetRef cfset = (CFSetRef) mySet;
  NSValue *x = [NSNumber numberWithInteger:5];
  if (CFSetContainsValue(cfset, x)) {
    NSLog(@"True");
  } else {
    NSLog(@"False");
  }

  CFSetRef cfset2 = CFSetCreateCopy(NULL, cfset);
  for (id elem in cfset2) {
    NSLog(@"%@", elem);
  }
  NSLog(@"%d", CFSetGetCountOfValue(cfset2, x));

  int count = CFSetGetCount(cfset2);
  const void** values = malloc(count * sizeof(void *));
  CFSetGetValues(cfset2, values);
  int i;
  for (i = 0; i < count; i++) {
    NSLog([NSString stringWithFormat:@"%@", values[i]]);
  }

  const void* val = CFSetGetValue(cfset2, x);
  NSLog(@"%@", val);

  const void *value = malloc(sizeof(const void*));
  Boolean found = CFSetGetValueIfPresent(cfset2, x, &value);
  NSLog(@"%s", found? "true": "false");  
  NSLog(@"%@", value);  

  NSMutableSet *myMutableSet;
 
  myMutableSet = [NSMutableSet setWithObjects:aValue1, aValue2, aValue3, nil];

  CFMutableSetRef cfmutset = (CFMutableSetRef) myMutableSet;
  CFSetRemoveAllValues(cfmutset);
  NSLog(@"%d", CFSetGetCount(cfmutset));

  NSValue *aValue4 = [NSNumber numberWithInteger:7];
  NSValue *aValue5 = [NSNumber numberWithInteger:2];
  CFSetAddValue(cfmutset, (const void *)aValue4);
  CFSetAddValue(cfmutset, (const void *)aValue5);
  for (id elem in cfmutset) {
    NSLog(@"%@", elem);
  }

  CFSetRemoveValue(cfmutset, (const void *)aValue5);
  for (id elem in cfmutset) {
    NSLog(@"%@", elem);
  }  
  
  CFSetReplaceValue(cfmutset, (const void *)aValue5);
  for (id elem in cfmutset) {
    NSLog(@"%@", elem);
  }

  ////////////////////////////////////////////////////////////////
  NSLog(@"----------------------");
  CFStringRef colors[] = {@"Red", @"Green", @"Blue", @"Yellow"};
  CFSetRef myCFSet = CFSetCreate(NULL, (const void**)colors, 4, NULL);

  NSSet* nsset = (NSSet*) myCFSet;

  //Testing count:
  if ([nsset count] == 4) {
    NSLog(@"testing count ... SUCCESS");
  } else {
    NSLog(@"testing count ... FAILED");
  }

  //Testing allObjects:
  NSArray* all = [nsset allObjects];
  if ([all containsObject: @"Red"] && [all containsObject: @"Yellow"]) {
    NSLog(@"testing allObjects ... SUCCESS");
  } else {
    NSLog(@"testing allObjects ... FAILED");
  }

  //Testing containsObject:
  if ([nsset containsObject: @"Red"] && ! [nsset containsObject: @"Maginta"]) {
    NSLog(@"testing containsObject ... SUCCESS");
  } else {
    NSLog(@"testing containsObject ... FAILED");
  }

  //Testing member:
  if ([nsset member: @"Red"] && ! [nsset member: @"Maginta"]) {
    NSLog(@"testing member ... SUCCESS");
  } else {
    NSLog(@"testing member ... FAILED");
  }  

  //Testing objectEnumerator:
  NSLog(@"testing objectEnumerator ...");
  NSEnumerator* it = [nsset objectEnumerator];
  id aKey;
  while ((aKey = [it nextObject]) != nil) {
    NSLog(@"%@", aKey);
  }



  //Testing Fast Enumeration
  NSLog(@"testing Fast Enumeration ...");
  for(id elem in nsset) {
    NSLog(@"%@", elem);
  }

  //Testing anyObject
  id any = [nsset anyObject];
  if ([nsset member: any]) {
    NSLog(@"testing anyObject ... SUCCESS");
  } else {
    NSLog(@"testing anyObject ... FAILED");
  }

  NSLog(@"----------------------");
  NSLog(@"-Testing NSMutableSet-");
  NSLog(@"----------------------");
  // Testing Mutable Set
  CFMutableSetRef myCFMutableSet = CFSetCreateMutable(NULL, 0, NULL);
  CFSetAddValue(myCFMutableSet, @"Red");

  NSMutableSet* nsMutableSet = (NSMutableSet*) myCFMutableSet;
  
  //Testing addObject:
  [nsMutableSet addObject: @"Green"];
  if ([nsMutableSet containsObject: @"Green"]) {
    NSLog(@"testing addObject: ... SUCCESS");
  } else {
    NSLog(@"testing addObject: ... FAILED");
  }  

  //Testing removeObject:
  [nsMutableSet removeObject: @"Green"];
  if (! [nsMutableSet containsObject: @"Green"]) {
    NSLog(@"testing removeObject: ... SUCCESS");
  } else {
    NSLog(@"testing removeObject: ... FAILED");
  }

  //Testing removeAllObjects
  NSUInteger prevCount = [nsMutableSet count];
  [nsMutableSet removeAllObjects];
  if ([nsMutableSet count] == 0 && prevCount == 1) {
    NSLog(@"testing removeAllObjects ... SUCCESS");
  } else {
    NSLog(@"testing removeAllObjects ... FAILED");
  }

  //Testing addObjectsFromArray:
  [nsMutableSet addObjectsFromArray: all];  
  if ([nsMutableSet count] == 4 && [nsMutableSet containsObject: @"Yellow"]) {
    NSLog(@"testing addObjectsFromArray: ... SUCCESS");
  } else {
    NSLog(@"testing addObjectsFromArray: ... FAILED");
  }

  NSLog(@"here");
	return 0;
}
