#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreFoundation/CFArray-private.h>

int main (int argc, const char * argv[])
{
	NSAutoreleasePool *pool;
	pool = [NSAutoreleasePool new];
	Boolean result;

	NSLog(@"Testing NSArray to point to CFArrayRef");
	NSLog(@"---------------");
	result = true;

	CFStringRef colors[] = {@"Red", @"Green", @"Blue", @"Red", @"Yellow"};
	NSArray* arr = CFArrayCreate(NULL, 
		(const void**)colors,
		5, NULL);
	
	///////////////////Testing count/////////////////////////////
	if ([arr count] == 5) {
		NSLog(@"Testing count ... sucess");
		result = result && true;
	} else {
		NSLog(@"Testing count ... failed");
		result = result && false;
	}
		
	///////////////////Testing containsObject////////////////////
	if ([arr containsObject: @"Red"] == YES && [arr containsObject: @"Maginta"] == NO) {
		NSLog(@"Testing containsObject ... sucess");
		result = result && true;
	} else {
		NSLog(@"Testing containsObject ... failed");
		result = result && false;
	}
		

	////////////////////Testing lastObject////////////////////////
	if ([[arr lastObject] isEqual: @"Yellow"] && ! [[arr lastObject] isEqual: @"Red"]) {
		NSLog(@"Testing lastObject ... sucess");
		result = result && true;
	} else {
		NSLog(@"Testing lastObject ... failed");
		result = result && false;
	}
		
	////////////////////Testing objectAtIndex:///////////////////
	if ([arr objectAtIndex: 1] == @"Green" && [arr objectAtIndex: 3] == @"Red") {
		NSLog(@"Testing objectAtIndex ... sucess");
		result = result && true;
	} else {
		NSLog(@"Testing objectAtIndex ... failed");
		result = result && false;
	}

	////////////////////Testing getObjects:range:///////////////////
	id *objects;
	NSRange range = NSMakeRange(2, 3);
	objects = malloc(sizeof(id) * range.length);
	[arr getObjects:objects range:range];
	if ([objects[0] isEqual: @"Blue"] && [objects[1] isEqual: @"Red"]
		&& [objects[2] isEqual: @"Yellow"]) {
		NSLog(@"Testing getObjects:range: ... sucess");
		result = result && true;
	} else {
		NSLog(@"Testing getObjects:range: ... failed");
		result = result && false;
	}	

	////////////////////Testing objectAtIndexedSubscript:///////////////////
	if ([arr objectAtIndexedSubscript: 1] == @"Green" && [arr objectAtIndexedSubscript: 3] == @"Red") {
		NSLog(@"Testing objectAtIndexedSubscript ... sucess");
		result = result && true;
	} else {
		NSLog(@"Testing objectAtIndexedSubscript ... failed");
		result = result && false;
	}

	////////////////////Testing objectsAtIndexes:///////////////////
	NSArray* subarr = [arr objectsAtIndexes: [[NSIndexSet alloc] initWithIndexesInRange: NSMakeRange(2, 3)]];
	if ([[subarr objectAtIndex: 0] isEqual: @"Blue"] && [[subarr objectAtIndex: 1] isEqual: @"Red"]
		&& [[subarr objectAtIndex: 2] isEqual: @"Yellow"]) {
		NSLog(@"Testing objectsAtIndexes ... sucess");
		result = result && true;
	} else {
		NSLog(@"Testing objectsAtIndexes ... failed");
		result = result && false;
	}

	////////////////////Testing objectEnumerator:///////////////////
	NSEnumerator* it = [arr objectEnumerator];
	Boolean enumRes = true;
	int i = 0;
	id aKey;
	while ((aKey = [it nextObject]) != nil) {
		if ([aKey isEqual: colors[i++]]) {
			enumRes = enumRes && true;
		} else {
			enumRes = enumRes && false;
			break;
		}
	}
	result = result && enumRes;
	if (enumRes) {
		NSLog(@"Testing objectEnumerator ... sucess");
	} else {
		NSLog(@"Testing objectEnumerator ... failed");
	}

	////////////////////Testing reverseObjectEnumerator:///////////////////
	it = [arr reverseObjectEnumerator];
	NSUInteger count = [arr count];
	enumRes = true;
	i = 0;
	while ((aKey = [it nextObject]) != nil) {
		if ([aKey isEqual: colors[count - 1 - i++]]) {
			enumRes = enumRes && true;
		} else {
			enumRes = enumRes && false;
			break;
		}
	}
	result = result && enumRes;
	if (enumRes) {
		NSLog(@"Testing reverseObjectEnumerator ... sucess");
	} else {
		NSLog(@"Testing reverseObjectEnumerator ... failed");
	}

	////////////////////Testing indexOfObject:///////////////////
	if ([arr indexOfObject: @"Green"] == 1 && [arr indexOfObject: @"Red"] == 0
		&& [arr indexOfObject: @"Yellow"] == 4 && [arr indexOfObject: @"Maginta"] == NSNotFound) {
		NSLog(@"Testing indexOfObject ... sucess");
		result = result && true;
	} else {
		NSLog(@"Testing indexOfObject ... failed");
		result = result && false;
	}

	////////////////////Testing indexOfObject:inRange:///////////////////
	if ([arr indexOfObject: @"Green" inRange: NSMakeRange(2,3)] == NSNotFound 
		&& [arr indexOfObject: @"Red" inRange: NSMakeRange(2,3)] == 3
		&& [arr indexOfObject: @"Yellow" inRange: NSMakeRange(1,4)] == 4 
		&& [arr indexOfObject: @"Maginta" inRange: NSMakeRange(3,2)] == NSNotFound) {
		NSLog(@"Testing indexOfObject:inRange: ... sucess");
		result = result && true;
	} else {
		NSLog(@"Testing indexOfObject:inRange: ... failed");
		result = result && false;
	}

	////////////////////Testing indexOfObjectIdenticalTo:///////////////////
	NSString* str = [NSString stringWithFormat:@"%@Green"];
	if ([arr indexOfObjectIdenticalTo: str] == NSNotFound 
		&& [arr indexOfObjectIdenticalTo: colors[0]] == 0) {
		NSLog(@"Testing indexOfObjectIdenticalTo ... sucess");
		result = result && true;
	} else {
		NSLog(@"Testing indexOfObjectIdenticalTo ... failed");
		result = result && false;
	}

/*TODO
– indexOfObjectIdenticalTo:inRange:
– indexOfObjectPassingTest:
– indexOfObjectWithOptions:passingTest:
– indexOfObjectAtIndexes:options:passingTest:
– indexesOfObjectsPassingTest:
– indexesOfObjectsWithOptions:passingTest:
– indexesOfObjectsAtIndexes:options:passingTest:
– indexOfObject:inSortedRange:options:usingComparator:
– makeObjectsPerformSelector:
– makeObjectsPerformSelector:withObject:
– enumerateObjectsUsingBlock:
– enumerateObjectsWithOptions:usingBlock:
– enumerateObjectsAtIndexes:options:usingBlock:
– firstObjectCommonWithArray:
– isEqualToArray:
– arrayByAddingObject:
– arrayByAddingObjectsFromArray:
– filteredArrayUsingPredicate:
– subarrayWithRange:
– sortedArrayHint
– sortedArrayUsingFunction:context:
– sortedArrayUsingFunction:context:hint:
– sortedArrayUsingDescriptors:
– sortedArrayUsingSelector:
– sortedArrayUsingComparator:
– sortedArrayWithOptions:usingComparator:
– componentsJoinedByString:
*/

	if (result) {
		NSLog(@"NSArray tested successfully");	
	} else {
		NSLog(@"NSArray test failed");	
	}
	NSLog(@"---------------");

	NSLog(@"Testing NSMutableArray");
	NSLog(@"---------------");

	NSMutableArray* mutableArr = [NSMutableArray arrayWithCapacity: 5];

	//Testing addObject
	id prevCount = [mutableArr count];
	[mutableArr addObject: @"This"];
	if ([mutableArr count] == 1 && prevCount == 0)
		NSLog(@"Testing addObject ... sucess");
	else
		NSLog(@"Testing addObject ... failed");

	//Testing addObjectsFromArray
	[mutableArr addObjectsFromArray: arr];
	if ([mutableArr containsObject: @"array"] == YES && [mutableArr containsObject: @"ses"] == NO)
		NSLog(@"Testing addObjectsFromArray ... sucess");
	else
		NSLog(@"Testing addObjectsFromArray ... failed");	

	//Testing exchangeObjectAtIndex:withObjectAtIndex:
	//array is now {"This", "This", "is", "an", "array"}
	[mutableArr exchangeObjectAtIndex: 1 withObjectAtIndex: 3];
	//array is now {"This", "an", "is", "This", "array"}
	if ([[mutableArr objectAtIndex: 1] isEqual: @"an"] && [[mutableArr objectAtIndex: 3] isEqual: @"This"])
		NSLog(@"Testing exchangeObjectAtIndex:withObjectAtIndex: ... sucess");
	else
		NSLog(@"Testing exchangeObjectAtIndex:withObjectAtIndex: ... failed");	

/* TODO
– addObject:
– addObjectsFromArray:
– insertObject:atIndex:
– insertObjects:atIndexes:
– removeAllObjects
– removeLastObject
– removeObject:
– removeObject:inRange:
– removeObjectAtIndex:
– removeObjectsAtIndexes:
– removeObjectIdenticalTo:
– removeObjectIdenticalTo:inRange:
– removeObjectsInArray:
– removeObjectsInRange:
– removeObjectsFromIndices:numIndices: Deprecated in iOS 4.0
– replaceObjectAtIndex:withObject:
– setObject:atIndexedSubscript:
– replaceObjectsAtIndexes:withObjects:
– replaceObjectsInRange:withObjectsFromArray:range:
– replaceObjectsInRange:withObjectsFromArray:
– setArray:
– exchangeObjectAtIndex:withObjectAtIndex:
– sortUsingDescriptors:
– sortUsingComparator:
– sortWithOptions:usingComparator:
– sortUsingFunction:context:
– sortUsingSelector:
– filterUsingPredicate:
*/

	NSLog(@"NSMutableArray tested successfully");
	NSLog(@"---------------");

	// //NSLog(@"here");
	
	// NSAutoreleasePool *pool;
	// pool = [NSAutoreleasePool new];

	// NSArray *myColors;

	// myColors = [NSArray arrayWithObjects: @"Red", @"Green", @"Blue", nil];

	// for (id color in myColors){
	// 	NSLog(@"%@", color);
	// }

	// CFArrayRef cfColors = (CFArrayRef) myColors;

	// NSLog(@"%d", CFArrayGetCount(cfColors));

	CFStringRef colors2[] = {@"Red", @"Green", @"Blue", @"Red", @"Yellow"};

	CFArrayRef arr2;
	 arr2 = CFArrayCreate(NULL, 
	 	(const void**)colors2,
	 	5, NULL);

	CFArrayAppendValue (arr2, (const void *)@"Cyan");



	for (id color1 in arr2){
	 	NSLog(@"%@", color1);
	}

	_CFArrayRemoveValue(arr2, @"Red");

	for (id color1 in arr2){
	 	NSLog(@"%@", color1);
	}	
	// NSArray *nsarr = (NSArray *) arr;
	// // [nsarr removeObject: @"Red"];
	
	// // NSLog(@"after removeObject");
	// // for (id color1 in arr){
	// // 	NSLog(@"%@", color1);
	// // }	
	// // NSLog(@"%d", [nsarr count]);

	// [nsarr dealloc];
	return 0;
}
