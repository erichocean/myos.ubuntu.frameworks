#include "Testing.h"
#include <Foundation/NSArchiver.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSData.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSString.h>
#include <limits.h>

@interface Model : NSObject <NSCoding>
{
  int cint;
  unsigned int cuint;
  NSInteger nsint;
  NSUInteger nsuint;
}
@end
@implementation Model
-(void)setValues
{
  cint = -1234567890;
  cuint = 1234567890;
  nsint = -1234567890;
  nsuint = 1234567890;
}
- (BOOL)testCInt:(Model *)o
{
  return (cint == o->cint);
}
- (BOOL)testCUInt:(Model *)o
{
  return (cuint == o->cuint);
}
- (BOOL)testNSInteger:(Model *)o
{
  return (nsint == o->nsint);
}
- (BOOL)testNSUInteger:(Model *)o
{
  return (nsuint == o->nsuint);
}

-(void)encodeWithCoder:(NSCoder *)coder
{
  [coder encodeValueOfObjCType:@encode(int) at:&cint];
  [coder encodeValueOfObjCType:@encode(unsigned int) at:&cuint];
  [coder encodeValueOfObjCType:@encode(NSInteger) at:&nsint];
  [coder encodeValueOfObjCType:@encode(NSUInteger) at:&nsuint];
}
-(id)initWithCoder:(NSCoder *)coder
{
  /* encoded as int - decoded as NSInteger. */
  [coder decodeValueOfObjCType: @encode(NSInteger) at: &nsint];
  /* encoded as unsinged int - decoded as NSUInteger. */
  [coder decodeValueOfObjCType: @encode(NSUInteger) at: &nsuint];
  /* encoded as NSInteger - decoded as int. */
  [coder decodeValueOfObjCType: @encode(int) at: &cint];
  /* encoded as NSUInteger - decoded as unsigned int. */
  [coder decodeValueOfObjCType: @encode(unsigned int) at: &cuint];
  return self;
}
@end


static NSFileManager *fm;
NSString *str = @"Do not taunt happy fun ball";
#define TEST_DECL(testType,testName) \
void testWriteBasicType_##testName (char *typeName, testType *toEncode) \
{ \
  NSData *data; \
  NSMutableData *mData;	\
  NSString *fileName; \
  long typeSize = sizeof(testType); \
  fileName = [[NSString stringWithFormat:@"%s-%li.type",typeName,typeSize] retain]; \
  if (![fm isReadableFileAtPath:fileName]) \
    {	\
      NSArchiver *arch;	\
      mData = [[NSMutableData alloc] init];	\
      arch = [[NSArchiver alloc] initForWritingWithMutableData: mData];	\
      [arch encodeValueOfObjCType:@encode(testType) at:toEncode];	\
      [arch encodeObject:str]; \
      [mData writeToFile:fileName atomically:YES]; \
      data = [NSData dataWithContentsOfFile:fileName]; \
      PASS([data isEqual:mData], \
	   "can write %s of size %li", typeName, typeSize); \
      [fileName release]; \
      [mData release]; \
      [arch release]; \
    } \
} \
void testReadBasicType_##testName (char *pre, testType *expect, testType *toDecode) \
{ \
  NSData *data; \
  NSUnarchiver *unArch; \
  NSString *str2; \
  NSArray *encodedFiles; \
  NSString *prefix = [[NSString stringWithCString:pre] retain]; \
  unsigned int i, c; \
  encodedFiles = [[NSBundle bundleWithPath: [fm currentDirectoryPath]] \
	  		pathsForResourcesOfType:@"type" inDirectory:nil]; \
  for (i = 0, c = [encodedFiles count]; i < c; i++) \
    { \
      NSString *fileName = [encodedFiles objectAtIndex:i]; \
      if ([[fileName lastPathComponent] hasPrefix:prefix]) \
	{ \
	  data = [NSData dataWithContentsOfFile:fileName]; \
	  unArch = [[NSUnarchiver alloc] initForReadingWithData:data]; \
	  NS_DURING \
	    [unArch decodeValueOfObjCType:@encode(testType) at:toDecode]; \
	  NS_HANDLER \
	    NSLog(@"%@ %@", [localException name], [localException reason]); \
	    PASS(0, "can unarchive %s from %s", pre, [fileName cString]); \
	  NS_ENDHANDLER \
	  str2 = [unArch decodeObject]; \
	  PASS((VAL_TEST(*expect,*toDecode) && [str isEqual:str2]), \
		"can unarchive %s from %s", pre, [fileName cString]); \
	} \
    } \
} 

#define VAL_TEST(testX,testY) testX == testY
TEST_DECL(int, int);
TEST_DECL(unsigned int, uint);
TEST_DECL(long, long);
TEST_DECL(unsigned long, ulong);
TEST_DECL(long long, llong);
TEST_DECL(unsigned long long, ullong);
TEST_DECL(signed char, schar);
TEST_DECL(unsigned char, uchar);
TEST_DECL(short, short);
TEST_DECL(unsigned short, ushort);
#undef VAL_TEST
#define VAL_TEST(testx, testy) EQ(testx,testy)
TEST_DECL(float, float);
TEST_DECL(double, double);

int main()
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  id obj1, obj2;
  NSData *data;
  int i = 2147483647;
  int i2;
  unsigned int ui = 4294967295U;
  unsigned int ui2;
  long l = 2147483647L;
  long l2; 
  long long ll = 9223372036854775807LL;
  long long ll2;
  unsigned long long ull = 18446744073709551615ULL;
  unsigned long long ull2;
  unsigned long ul = 4294967295UL;
  unsigned long ul2;
  signed char c = 127;
  signed char c2;
  unsigned char uc = 255;
  unsigned char uc2;
  short s = 32767;
  short s2;
  unsigned short us = 65535;
  unsigned short us2;
  float f = 3.40282347e+38F;
  float f2;
  double d = 1.7976931348623157e+308;
  double d2;
  
  fm = [NSFileManager defaultManager];
  
  testWriteBasicType_int("int", &i);
  testReadBasicType_int("int", &i, &i2);
  
  testWriteBasicType_uint("uint", &ui);
  testReadBasicType_uint("uint", &ui, &ui2);
  
  testWriteBasicType_long("long", &l);
  testReadBasicType_long("long", &l, &l2);
  
  testWriteBasicType_ulong("ulong", &ul);
  testReadBasicType_ulong("ulong", &ul, &ul2);
  
  testWriteBasicType_llong("llong", &ll);
  testReadBasicType_llong("llong", &ll, &ll2);
  
  testWriteBasicType_ullong("ullong", &ull);
  testReadBasicType_ullong("ullong", &ull, &ull2);
  
  testWriteBasicType_schar("schar", &c);
  testReadBasicType_schar("schar", &c, &c2);
  
  testWriteBasicType_uchar("uchar", &uc);
  testReadBasicType_uchar("uchar", &uc, &uc2);
  
  testWriteBasicType_short("short", &s);
  testReadBasicType_short("short", &s, &s2);
  
  testWriteBasicType_float("float", &f);
  testReadBasicType_float("float", &f, &f2);
  
  testWriteBasicType_double("double", &d);
  testReadBasicType_double("double", &d, &d2);
  
  testWriteBasicType_ushort("ushort", &us);
  testReadBasicType_ushort("ushort", &us, &us2);
  
  obj1 = [Model new];
  [obj1 setValues];
  data = [NSArchiver archivedDataWithRootObject: obj1];
  obj2 = [NSUnarchiver unarchiveObjectWithData: data];
  PASS([obj1 testCInt:obj2],       "archiving as int - dearchiving as NSInteger");
  PASS([obj1 testCUInt:obj2],      "archiving as unsigned int - dearchiving as NSUInteger");
  PASS([obj1 testNSInteger:obj2],  "archiving as NSInteger - dearchiving as int");
  PASS([obj1 testNSUInteger:obj2], "archiving as NSUInteger - dearchiving as unsigned int");
  
  [pool release]; pool = nil;
  return 0;
}
