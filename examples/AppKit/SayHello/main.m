#import "say.h"
#import <Foundation/Foundation.h>

int main (void)
{
   id speaker;
   NSString *name = @"GNUstep !";
   NSAutoreleasePool *pool;

   pool = [NSAutoreleasePool new];
   speaker = [[Say alloc] init];

   [speaker sayHello];
   [speaker sayHelloTo:name];

   RELEASE(speaker);
   RELEASE(pool);
}
