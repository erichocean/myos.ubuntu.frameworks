#include "CoreFoundation/CFArray.h"
#include "../CFTesting.h"

#define ARRAY_SIZE 5
const CFIndex array[ARRAY_SIZE] = { 1, 2, 3, 4, 5 };

int main (void)
{
  CFArrayRef a;
  CFIndex n;
  
  a = CFArrayCreate (NULL, (const void**)&array, ARRAY_SIZE, NULL);
  PASS(a != NULL, "CFArray created.");
  
  n = CFArrayGetCount (a);
  PASS(n == ARRAY_SIZE, "CFArray has correct number of values.");
  n = (CFIndex)CFArrayGetCountOfValue (a, CFRangeMake(0, ARRAY_SIZE), (const void*)3);
  PASS(n == 1, "Found 1 occurence of the value.");
  
  n = (CFIndex)CFArrayGetValueAtIndex (a, 1);
  PASS(n == 2, "Found value.");
  
  CFRelease (a);
  
  return 0;
}
