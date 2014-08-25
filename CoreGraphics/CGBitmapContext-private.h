
#import <CoreGraphics/CGContext.h>
#import <CoreGraphics/CGBitmapContext.h>

CGContextRef _CGBitmapContextCreate(size_t width, size_t height);
CGContextRef _CGBitmapContextCreateWithOptions(CGSize size, BOOL opaque, CGFloat scale);
