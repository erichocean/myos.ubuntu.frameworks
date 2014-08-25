#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

#import <CoreGraphics/StandardGlyphNames.h>

extern const char * const StandardGlyphNames[258];
extern const char * const StandardGlyphNamesKeys[258];

int main (int argc, const char * argv[])
{
	
    NSAutoreleasePool *pool;
	pool = [NSAutoreleasePool new];

    NSLog(@"test: %s", StandardGlyphNames[0]);

	NSDictionary *myColors;

	NSArray *keys = [NSArray arrayWithObjects:@"key1", @"key2", @"key3", nil];

    NSArray *objects = [NSArray arrayWithObjects:@"How", @"are", @"you", nil];

    myColors = [NSDictionary dictionaryWithObjects:objects forKeys:keys];

    CFDictionaryRef cfDict = myColors;
    CFStringRef value = CFDictionaryGetValue(cfDict, CFSTR("key1"));
    NSLog(@"value: %@", value);

    CFMutableDictionaryRef dict = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(dict, CFSTR("hey"), CFSTR("Ahmed"));
    CFDictionarySetValue(dict, CFSTR("hey1"), CFSTR("Ahmed1"));
    CFDictionarySetValue(dict, CFSTR("hey2"), CFSTR("Ahmed2"));	


    NSLog(@"%@", (id) CFDictionaryGetValue(dict, (const void*) @"hey2"));
    NSLog(@"%@", CFDictionaryGetCount(dict));

    NSMutableDictionary* nsDict = dict;

    for (id key in nsDict) {
        NSLog(@"%@", key);
    }

    NSLog(@"here");

	return 0;
}
