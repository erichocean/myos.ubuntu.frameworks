#include <Foundation/Foundation.h>

@interface Greeter:NSObject
{
  /* This is left empty on purpose:
   ** Normally instance variables would be declared here,
   ** but these are not used in our example.
   */
}

- (void)greet;

@end

#include <stdio.h>

@implementation Greeter

- (void)greet
{
	printf("Hello, World!\n");
}

@end

#include <stdlib.h>

int main(void)
{
	id myGreeter;
	myGreeter=[[Greeter alloc] init];

	[myGreeter greet];

	[myGreeter release];
	return EXIT_SUCCESS;
}
