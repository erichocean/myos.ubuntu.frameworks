#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

int main (int argc, const char * argv[])
{
	NSAutoreleasePool *pool;
	pool = [NSAutoreleasePool new];
	Boolean result;

	NSLog(@"Testing NSArray");
	NSLog(@"---------------");
	result = true;

	NSArray* arr = [NSArray arrayWithObjects: @"This", @"is", @"an", @"array", nil];
	
	///////////////////Testing count/////////////////////////////
	if ([arr count] == 4) {
		NSLog(@"Testing count ... sucess");
		result = result && true;
	} else {
		NSLog(@"Testing count ... failed");
		result = result && false;
	}
		
	///////////////////Testing containsObject////////////////////
	if ([arr containsObject: @"This"] == YES && [arr containsObject: @"Thiso"] == NO) {
		NSLog(@"Testing containsObject ... sucess");
		result = result && true;
	} else {
		NSLog(@"Testing containsObject ... failed");
		result = result && false;
	}
		

	////////////////////Testing lastObject////////////////////////
	if ([[arr lastObject] isEqual: @"array"] && ! [[arr lastObject] isEqual: @"This"]) {
		NSLog(@"Testing lastObject ... sucess");
		result = result && true;
	} else {
		NSLog(@"Testing lastObject ... failed");
		result = result && false;
	}
		
	////////////////////Testing objectAtIndex:///////////////////
	if ([arr objectAtIndex: 1] == @"is" && [arr objectAtIndex: 3] == @"array") {
		NSLog(@"Testing objectAtIndex ... sucess");
		result = result && true;
	} else {
		NSLog(@"Testing objectAtIndex ... failed");
		result = result && false;
	}

/*TODO
– getObjects:range:
– objectAtIndexedSubscript:
– objectsAtIndexes:
– objectEnumerator
– reverseObjectEnumerator
– getObjects: Deprecated in iOS 4.0
– indexOfObject:
– indexOfObject:inRange:
– indexOfObjectIdenticalTo:
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

	// NSMutableArray* mutableArr = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
	// int y = 1;
	// int *x = &y;
	
	// NSLog(@"here1");
	// CFArrayAppendValue(mutableArr, x);
	// NSLog(@"here2");
	// NSLog(@"%d", CFArrayGetCount(mutableArr));
	// CFRange range = {0, CFArrayGetCount(mutableArr)};
	// CFIndex b = CFArrayGetFirstIndexOfValue (mutableArr, range, x);
	// int m = 2;
	// int *n = &m;
	// CFArrayAppendValue(mutableArr, n);
	// CFArrayRemoveValueAtIndex(mutableArr, 1);
	// y = 5;
	// int *k = &y;
	// NSLog(@"here3");
	// CFArrayInsertValueAtIndex(mutableArr, 1, k);
	return 0;
}
