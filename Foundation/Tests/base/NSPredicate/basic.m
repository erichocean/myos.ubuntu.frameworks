#import "ObjectTesting.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

void
testKVC(NSDictionary *dict)
{
	PASS([@"A Title" isEqual: [dict valueForKey: @"title"]], "valueForKeyPath: with string");
	PASS([@"A Title" isEqual: [dict valueForKeyPath: @"title"]], "valueForKeyPath: with string");
  PASS([@"John" isEqual: [dict valueForKeyPath: @"Record1.Name"]], "valueForKeyPath: with string");
	PASS(30 == [[dict valueForKeyPath: @"Record2.Age"] intValue], "valueForKeyPath: with int");
}

void
testContains(NSDictionary *dict)
{
  NSPredicate *p;

	p = [NSPredicate predicateWithFormat: @"%@ CONTAINS %@", @"AABBBAA", @"BBB"];
	PASS([p evaluateWithObject: dict], "%%@ CONTAINS %%@");
	p = [NSPredicate predicateWithFormat: @"%@ IN %@", @"BBB", @"AABBBAA"];
	PASS([p evaluateWithObject: dict], "%%@ IN %%@");
}

void
testString(NSDictionary *dict)
{
  NSPredicate *p;

	p = [NSPredicate predicateWithFormat: @"%K == %@", @"Record1.Name", @"John"];
	PASS([p evaluateWithObject: dict], "%%K == %%@");
	p = [NSPredicate predicateWithFormat: @"%K MATCHES[c] %@", @"Record1.Name", @"john"];
	PASS([p evaluateWithObject: dict], "%%K MATCHES[c] %%@");
	p = [NSPredicate predicateWithFormat: @"%K BEGINSWITH %@", @"Record1.Name", @"Jo"];
	PASS([p evaluateWithObject: dict], "%%K BEGINSWITH %%@");
	p = [NSPredicate predicateWithFormat: @"(%K == %@) AND (%K == %@)", @"Record1.Name", @"John", @"Record2.Name", @"Mary"];
	PASS([p evaluateWithObject: dict], "(%%K == %%@) AND (%%K == %%@)");
}

void
testInteger(NSDictionary *dict)
{
  NSPredicate *p;

	p = [NSPredicate predicateWithFormat: @"%K == %d", @"Record1.Age", 34];
	PASS([p evaluateWithObject: dict], "%%K == %%d");
	p = [NSPredicate predicateWithFormat: @"%K = %@", @"Record1.Age", [NSNumber numberWithInt: 34]];
	PASS([p evaluateWithObject: dict], "%%K = %%@");
	p = [NSPredicate predicateWithFormat: @"%K == %@", @"Record1.Age", [NSNumber numberWithInt: 34]];
	PASS([p evaluateWithObject: dict], "%%K == %%@");
	p = [NSPredicate predicateWithFormat: @"%K < %d", @"Record1.Age", 40];
	PASS([p evaluateWithObject: dict], "%%K < %%d");
	p = [NSPredicate predicateWithFormat: @"%K < %@", @"Record1.Age", [NSNumber numberWithInt: 40]];
	PASS([p evaluateWithObject: dict], "%%K < %%@");
	p = [NSPredicate predicateWithFormat: @"%K <= %@", @"Record1.Age", [NSNumber numberWithInt: 40]];
	PASS([p evaluateWithObject: dict], "%%K <= %%@");
	p = [NSPredicate predicateWithFormat: @"%K <= %@", @"Record1.Age", [NSNumber numberWithInt: 34]];
	PASS([p evaluateWithObject: dict], "%%K <= %%@");
	p = [NSPredicate predicateWithFormat: @"%K > %@", @"Record1.Age", [NSNumber numberWithInt: 20]];
	PASS([p evaluateWithObject: dict], "%%K > %%@");
	p = [NSPredicate predicateWithFormat: @"%K >= %@", @"Record1.Age", [NSNumber numberWithInt: 34]];
	PASS([p evaluateWithObject: dict], "%%K >= %%@");
	p = [NSPredicate predicateWithFormat: @"%K >= %@", @"Record1.Age", [NSNumber numberWithInt: 20]];
	PASS([p evaluateWithObject: dict], "%%K >= %%@");
	p = [NSPredicate predicateWithFormat: @"%K != %@", @"Record1.Age", [NSNumber numberWithInt: 20]];
	PASS([p evaluateWithObject: dict], "%%K != %%@");
	p = [NSPredicate predicateWithFormat: @"%K <> %@", @"Record1.Age", [NSNumber numberWithInt: 20]];
	PASS([p evaluateWithObject: dict], "%%K <> %%@");
	p = [NSPredicate predicateWithFormat: @"%K BETWEEN %@", @"Record1.Age", [NSArray arrayWithObjects: [NSNumber numberWithInt: 20], [NSNumber numberWithInt: 40], nil]];
	PASS([p evaluateWithObject: dict], "%%K BETWEEN %%@");
	p = [NSPredicate predicateWithFormat: @"(%K == %d) OR (%K == %d)", @"Record1.Age", 34, @"Record2.Age", 34];
	PASS([p evaluateWithObject: dict], "(%%K == %%d) OR (%%K == %%d)");


}

void
testFloat(NSDictionary *dict)
{
  NSPredicate *p;

	p = [NSPredicate predicateWithFormat: @"%K < %f", @"Record1.Age", 40.5];
	PASS([p evaluateWithObject: dict], "%%K < %%f");
  p = [NSPredicate predicateWithFormat: @"%f > %K", 40.5, @"Record1.Age"];
	PASS([p evaluateWithObject: dict], "%%f > %%K");
}

void
testAttregate(NSDictionary *dict)
{
  NSPredicate *p;

  p = [NSPredicate predicateWithFormat: @"%@ IN %K", @"Kid1", @"Record1.Children"];
  PASS([p evaluateWithObject: dict], "%%@ IN %%K");
  p = [NSPredicate predicateWithFormat: @"Any %K == %@", @"Record2.Children", @"Girl1"];
  PASS([p evaluateWithObject: dict], "Any %%K == %%@");
}

int main()
{
  NSArray *filtered;
  NSArray *pitches;
  NSArray *expect;
  NSMutableDictionary *dict;
  NSPredicate *p;
  NSDictionary *d;
  NSAutoreleasePool   *arp = [NSAutoreleasePool new];

  dict = [[NSMutableDictionary alloc] init];
  [dict setObject: @"A Title" forKey: @"title"];

  d = [NSDictionary dictionaryWithObjectsAndKeys:
    @"John", @"Name",
    [NSNumber numberWithInt: 34], @"Age",
    [NSArray arrayWithObjects: @"Kid1", @"Kid2", nil], @"Children",
    nil];
  [dict setObject: d forKey: @"Record1"];

  d = [NSDictionary dictionaryWithObjectsAndKeys:
    @"Mary", @"Name",
    [NSNumber numberWithInt: 30], @"Age",
    [NSArray arrayWithObjects: @"Kid1", @"Girl1", nil], @"Children",
    nil];
  [dict setObject: d forKey: @"Record2"];

  testKVC(dict);
  testContains(dict);
  testString(dict);
  testInteger(dict);
  testFloat(dict);
  testAttregate(dict);
  [dict release];

  pitches = [NSArray arrayWithObjects:
    @"Do", @"Re", @"Mi", @"Fa", @"So", @"La", nil];
  expect = [NSArray arrayWithObjects: @"Do", nil];

  filtered = [pitches filteredArrayUsingPredicate:
    [NSPredicate predicateWithFormat: @"SELF == 'Do'"]];  
  PASS([filtered isEqual: expect], "filter with SELF");

  filtered = [pitches filteredArrayUsingPredicate:
    [NSPredicate predicateWithFormat: @"description == 'Do'"]];
  PASS([filtered isEqual: expect], "filter with description");

  filtered = [pitches filteredArrayUsingPredicate:
    [NSPredicate predicateWithFormat: @"SELF == '%@'", @"Do"]];
  PASS([filtered isEqual: [NSArray array]], "filter with format");

  PASS([NSExpression expressionForEvaluatedObject]
    == [NSExpression expressionForEvaluatedObject],
    "expressionForEvaluatedObject is unique");

  p = [NSPredicate predicateWithFormat: @"SELF == 'aaa'"];
  PASS([p evaluateWithObject: @"aaa"], "SELF equality works");

  [arp release]; arp = nil;
  return 0;
}
