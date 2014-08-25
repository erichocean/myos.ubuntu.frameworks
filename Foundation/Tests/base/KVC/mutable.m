#import "ObjectTesting.h"
#import <Foundation/Foundation.h>

@interface Observer : NSObject
- (void) observeValueForKeyPath: (NSString *)keyPath
                       ofObject: (id)object
                         change: (NSDictionary *)change
                        context: (void *)context;
@end

@implementation Observer
- (void) observeValueForKeyPath: (NSString *)keyPath
                       ofObject: (id)object
                         change: (NSDictionary *)change
                        context: (void *)context
{
  NSLog(@"observeValueForKeyPath: %@\nofObject:%@\nchange:%@\ncontext:%p",
    keyPath, object, change, context);
}
@end

@interface Lists : NSObject
{
  NSMutableArray * cities;
  NSMutableArray * numbers;
  NSMutableArray * third;
  NSString *string;
}

@end


@implementation Lists

- (id)init
{
  cities = [[NSMutableArray alloc] initWithObjects:
    @"Grand Rapids",
    @"Chicago",
    nil];
  numbers = [[NSMutableArray alloc] initWithObjects:
    @"One",
    @"Ten",
    @"Three",
    @"Ninety",
    nil];
  third = [[NSMutableArray alloc] initWithObjects:
    @"a",
    @"b",
    @"c",
    nil];

  return self;
}

- (void)insertObject:(id)obj inNumbersAtIndex:(unsigned int)index
{
  if (![obj isEqualToString:@"NaN"])
    {
      [numbers addObject:obj];
    }
}

- (void)removeObjectFromNumbersAtIndex:(unsigned int)index
{
  if (![[numbers objectAtIndex:index] isEqualToString:@"One"])
    [numbers removeObjectAtIndex:index];
}

- (void)replaceObjectInNumbersAtIndex:(unsigned int)index withObject:(id)obj
{
  if (index == 1)
    obj = @"Two";
  [numbers replaceObjectAtIndex:index withObject:obj];
}

- (void)setCities:(NSArray *)other
{
  [cities setArray:other];
}

- (void) didChangeValueForKey: (NSString*)k
{
  NSLog(@"%@ %@", NSStringFromSelector(_cmd), k);
  [super didChangeValueForKey: k];
}

- (void) willChangeValueForKey: (NSString*)k
{
  [super willChangeValueForKey: k];
  NSLog(@"%@ %@", NSStringFromSelector(_cmd), k);
}
@end

@interface Sets : NSObject
{
  NSMutableSet * one;
  NSMutableSet * two;
  NSMutableSet * three;
}
@end

@implementation Sets

- (id)init
{
  [super init];

  one = [[NSMutableSet alloc] initWithObjects:
    @"one",
    @"two",
    @"eight",
    nil];
  two = [[NSMutableSet alloc] initWithSet:one];
  three = [[NSMutableSet alloc] initWithSet:one];

  return self;
}

- (void)addOneObject:(id)anObject
{
  if (![anObject isEqualToString:@"ten"])
    [one addObject:anObject];
}

- (void)removeOneObject:(id)anObject
{
  if (![anObject isEqualToString:@"one"])
    {
      [one removeObject:anObject];
    }
}

- (void)setTwo:(NSMutableSet *)set
{
  [two setSet:set];
}

@end

int main(void)
{
  NSAutoreleasePool   *arp = [NSAutoreleasePool new];

  Lists *list = [[[Lists alloc] init] autorelease];
  Observer *observer = [Observer new];
  id o;
  NSMutableArray * proxy;
  NSDictionary * temp;

  [list addObserver: observer forKeyPath: @"numbers" options: 15 context: 0];
  [list addObserver: observer forKeyPath: @"string" options: 15 context: 0];

  [list setValue: @"x" forKey: @"string"];

  proxy = [list mutableArrayValueForKey:@"numbers"];
  PASS([proxy isKindOfClass:[NSMutableArray class]],
      "proxy is a kind of NSMutableArray")
  [proxy removeLastObject];
  PASS_EXCEPTION([proxy addObject:@"NaN"];,
    NSRangeException,"bad removal causes range exception when observing")
  [proxy replaceObjectAtIndex:1 withObject:@"Seven"];
  [proxy addObject:@"Four"];
  [proxy removeObject:@"One"];
  
  o = [NSArray arrayWithObjects:
      @"One",
      @"Two",
      @"Three",
      @"Four",
      nil];
  PASS([[list valueForKey:@"numbers"] isEqualToArray: o],
    "KVC mutableArrayValueForKey: proxy works with array proxy methods")

  proxy = [list mutableArrayValueForKey:@"cities"];
  PASS([proxy isKindOfClass:[NSMutableArray class]],
      "proxy is a kind of NSMutableArray")
  [proxy addObject:@"Lima"];
  o = [NSArray arrayWithObjects:
      @"Grand Rapids",
      @"Chicago",
      @"Lima",
      nil];
  PASS([[list valueForKey:@"cities"] isEqualToArray: o],
    "KVC mutableArrayValueForKey: proxy works with set<Key>:")

  proxy = [list mutableArrayValueForKey:@"third"];
  PASS([proxy isKindOfClass:[NSMutableArray class]],
      "proxy is a kind of NSMutableArray")

  PASS(proxy != [list valueForKey:@"third"],
     "KVC mutableArrayValueForKey: returns a proxy array for the ivar")
  PASS([[proxy objectAtIndex:1] isEqualToString:@"b"],
      "This proxy works")
  
  temp = [NSDictionary dictionaryWithObject:list forKey:@"list"];
  proxy = [temp mutableArrayValueForKeyPath:@"list.numbers"];
  PASS([proxy isKindOfClass:NSClassFromString(@"NSKeyValueMutableArray")],
       "mutableArrayValueForKey: works")
  

  Sets * set = [[[Sets alloc] init] autorelease];
  NSMutableSet * setProxy;

  setProxy = [set mutableSetValueForKey:@"one"];
  PASS([setProxy isKindOfClass:[NSMutableSet class]],
      "proxy is a kind of NSMutableSet")

  [setProxy removeObject:@"one"];
  [setProxy addObject:@"ten"];
  [setProxy removeObject:@"eight"];
  [setProxy addObject:@"three"];

  o = [NSSet setWithObjects:@"one", @"two", @"three", nil];
  PASS([setProxy isEqualToSet: o],
      "KVC mutableSetValueForKey: proxy uses methods")

  setProxy = [set mutableSetValueForKey:@"two"];
  PASS([setProxy isKindOfClass:[NSMutableSet class]],
      "proxy is a kind of NSMutableSet")
  [setProxy addObject:@"seven"];
  [setProxy minusSet:[NSSet setWithObject:@"eight"]];
  o = [NSSet setWithObjects:@"one", @"two", @"seven", nil];
  PASS([setProxy isEqualToSet: o],
      "KVC mutableSetValueForKey: proxy works with set<Key>:")

  setProxy = [set mutableSetValueForKey:@"three"];
  PASS([setProxy isKindOfClass:[NSMutableSet class]],
      "proxy is kind of NSMutableSet")
  PASS(setProxy != [set valueForKey:@"three"],
         "KVC mutableSetValueForKey: returns a proxy set for the ivar")
  [setProxy addObject:@"seven"];
  [setProxy removeObject:@"eight"];
  o = [NSSet setWithObjects:@"one", @"two", @"seven", nil];
  PASS([setProxy isEqualToSet: o], "this proxy works")

  temp = [NSDictionary dictionaryWithObject:set forKey:@"set"];
  setProxy = [temp mutableSetValueForKeyPath:@"set.three"];
  PASS([setProxy isKindOfClass:NSClassFromString(@"NSKeyValueMutableSet")],
       "mutableSetValueForKey: works")

  [list removeObserver: observer forKeyPath: @"numbers"];
  [list removeObserver: observer forKeyPath: @"string"];

  [arp release]; arp = nil;
  return 0;
}
