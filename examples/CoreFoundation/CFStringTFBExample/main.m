#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

int main (int argc, const char * argv[])
{
	//NSLog(@"here");
	
	NSAutoreleasePool *pool;
	pool = [NSAutoreleasePool new];

	NSString *nsStr = @"Amr aboela";
       CFIndex length = CFStringGetLength((CFStringRef)nsStr);		

	NSLog(@"Cast from Foundation to Core Foundation");

	CFStringRef name = CFSTR("Helvetica");
	BOOL b = [name isEqualToString:@"Helvetica"];
	if (b) {
		NSLog(@"True");
	} else {
		NSLog(@"False");
	}
	NSLog(@"length(Amr aboela) = %d\n", length);
	NSLog(@"Cast from Foundation to Core Foundation");
	char strArr[] = {'a','m','r',' ','a','b','o','e','l','a','\0'};	
	CFStringRef cfstr = CFStringCreateWithCString(NULL,strArr,kCFStringEncodingUTF8);
	nsStr = (NSString*)cfstr;		
	NSLog(@"length(Amr aboela)array = %d\n", [nsStr length]);	

	return 0;
}
