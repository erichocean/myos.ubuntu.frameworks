#include "CoreFoundation/CFArray.h"
#include "../CFTesting.h"

#define ARRAY_SIZE 5
const CFIndex array[ARRAY_SIZE] = { 5, 2, 3, 4, 1 };

CFComparisonResult comp (const void *val1, const void *val2, void *context)
{
  return val1 == val2 ? kCFCompareEqualTo : (val1 < val2 ? kCFCompareLessThan :
    kCFCompareGreaterThan);
}

int main (void)
{
  CFArrayRef a;
  CFMutableArrayRef ma;
  CFIndex n;
  
  a = CFArrayCreate (NULL, (const void**)&array, ARRAY_SIZE, NULL);
  PASS(a != NULL, "CFArray created.");
  
  ma = CFArrayCreateMutableCopy (NULL, 6, a);
  PASS(ma != NULL, "CFMutableArray created.");
  
  n = 7;
  CFArrayAppendValue (ma, (const void*)n);
  n = CFArrayGetCount ((CFArrayRef)ma);
  PASS(n == ARRAY_SIZE + 1, "CFMutableArray has correct number of values.");
  
  CFArraySortValues (ma, CFRangeMake(0, n), &comp, NULL);
  PASS((CFIndex)CFArrayGetValueAtIndex((CFArrayRef)ma, 0) == 1
    && (CFIndex)CFArrayGetValueAtIndex((CFArrayRef)ma, ARRAY_SIZE) == 7,
    "Array sorted correctly.");
  
  return 0;
}
