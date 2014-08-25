/** <title>CGBitmapContext</title>
 
 <abstract>C Interface to graphics drawing library</abstract>
 
 Copyright <copy>(C) 2009 Free Software Foundation, Inc.</copy>

 Author: Eric Wasylishen
 Date: January 2010
  
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */
#import <stdlib.h>
#import <png.h>
#import "CGBitmapContext-private.h"
#import "CGContext-private.h"

@interface CGBitmapContext : CGContext
{
@public
  CGColorSpaceRef cs;
  void *data;
  void *releaseInfo;
  CGBitmapContextReleaseDataCallback cb;
}
- (id) initWithSurface: (cairo_surface_t *)target
            colorspace: (CGColorSpaceRef)colorspace
                  data: (void*)d
           releaseInfo: (void*)i
       releaseCallback: (CGBitmapContextReleaseDataCallback)releaseCallback;     
@end

@implementation CGBitmapContext

- (id) initWithSurface: (cairo_surface_t *)target
            colorspace: (CGColorSpaceRef)colorspace
                  data: (void*)d
           releaseInfo: (void*)i
       releaseCallback: (CGBitmapContextReleaseDataCallback)releaseCallback;     
{
  CGSize size = CGSizeMake(cairo_image_surface_get_width(target),
                           cairo_image_surface_get_height(target));
  if (nil == (self = [super initWithSurface: target size: size]))
  {
    return nil;
  }
  cs = CGColorSpaceRetain(colorspace);
  data = d;
  releaseInfo = i;
  cb = releaseCallback;
  return self;
}

- (void)dealloc
{
    CGColorSpaceRelease(cs);
    if (cb) {
        cb(releaseInfo, data);
    }
    [super dealloc];    
}

@end


CGContextRef CGBitmapContextCreate(
  void *data,
  size_t width,
  size_t height,
  size_t bitsPerComponent,
  size_t bytesPerRow,
  CGColorSpaceRef cs,
  CGBitmapInfo info)
{
  return CGBitmapContextCreateWithData(data, width, height, bitsPerComponent,
    bytesPerRow, cs, info, NULL, NULL);
}

static void OPBitmapDataReleaseCallback(void *info, void *data)
{
  free(data);
}

CGContextRef CGBitmapContextCreateWithData(
  void *data,
  size_t width,
  size_t height,
  size_t bitsPerComponent,
  size_t bytesPerRow,
  CGColorSpaceRef cs,
  CGBitmapInfo info,
  CGBitmapContextReleaseDataCallback callback,
  void *releaseInfo)
{
  cairo_format_t format;
  cairo_surface_t *surf;  

  if (0 != (info & kCGBitmapFloatComponents))
  {
  	NSLog(@"Float components not supported"); 
    return nil;
  }
  
  const int order = info & kCGBitmapByteOrderMask;
  if (!((NSHostByteOrder() == NS_LittleEndian) && (order == kCGBitmapByteOrder32Little))
    && !((NSHostByteOrder() == NS_BigEndian) && (order == kCGBitmapByteOrder32Big))
	&& !(order == kCGBitmapByteOrderDefault))
  {
  	NSLog(@"Bitmap context must be native-endiand");
    return nil;
  }

  const int alpha = info &  kCGBitmapAlphaInfoMask;
  const CGColorSpaceModel model = CGColorSpaceGetModel(cs);
  const size_t numComps = CGColorSpaceGetNumberOfComponents(cs);
  
  if (bitsPerComponent == 8
      && numComps == 3
      && model == kCGColorSpaceModelRGB
      && alpha == kCGImageAlphaPremultipliedFirst)
  {
  	format = CAIRO_FORMAT_ARGB32;
        //format = CAIRO_CONTENT_COLOR_ALPHA;
  }
  else if (bitsPerComponent == 8
      && numComps == 3
      && model == kCGColorSpaceModelRGB
      && alpha == kCGImageAlphaNoneSkipFirst)
  {
  	format = CAIRO_FORMAT_RGB24;
  }
  else if (bitsPerComponent == 8 && alpha == kCGImageAlphaOnly)
  {
  	format = CAIRO_FORMAT_A8;
  }
  else if (bitsPerComponent == 1 && alpha == kCGImageAlphaOnly)
  {
  	format = CAIRO_FORMAT_A1;
  }
  else
  {
  	NSLog(@"Unsupported bitmap format");
    return nil;
  }
  
  
    if (data == NULL) {
        data = malloc(height * bytesPerRow); // FIXME: checks
        memset(data,0,height*bytesPerRow);
        callback = (CGBitmapContextReleaseDataCallback)OPBitmapDataReleaseCallback;
    }
    surf = cairo_image_surface_create_for_data(data, format, width, height, bytesPerRow);
    return [[CGBitmapContext alloc] initWithSurface: surf
                                         colorspace: cs
                                               data: data
                                        releaseInfo: releaseInfo
	                            releaseCallback: callback];
}


CGImageAlphaInfo CGBitmapContextGetAlphaInfo(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
    switch (cairo_image_surface_get_format(cairo_get_target(ctx->ct)))
	{
	  case CAIRO_FORMAT_ARGB32:
	    return kCGImageAlphaPremultipliedFirst;
	  case CAIRO_FORMAT_RGB24:
	    return kCGImageAlphaNoneSkipFirst;
	  case CAIRO_FORMAT_A8:
	  case CAIRO_FORMAT_A1:
	    return kCGImageAlphaOnly;
	  default:
	    return kCGImageAlphaNone;
	}
  }
  return kCGImageAlphaNone;
}

CGBitmapInfo CGBitmapContextGetBitmapInfo(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
    return cairo_image_surface_get_stride(cairo_get_target(ctx->ct));
  }
  return 0;
}

size_t CGBitmapContextGetBitsPerComponent(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
    switch (cairo_image_surface_get_format(cairo_get_target(ctx->ct)))
	{
	  case CAIRO_FORMAT_ARGB32:
	  case CAIRO_FORMAT_RGB24:
	  case CAIRO_FORMAT_A8:
	    return 8;
	  case CAIRO_FORMAT_A1:
	    return 1;
	  default:
	    return 0;
	}
  }
  return 0;
}

size_t CGBitmapContextGetBitsPerPixel(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
    switch (cairo_image_surface_get_format(cairo_get_target(ctx->ct)))
	{
	  case CAIRO_FORMAT_ARGB32:
	  case CAIRO_FORMAT_RGB24:
	    return 32;
	  case CAIRO_FORMAT_A8:
	    return 8;
	  case CAIRO_FORMAT_A1:
	    return 1;
	  default:
	    return 0;
	}
  }
  return 0;
}

size_t CGBitmapContextGetBytesPerRow(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
    return cairo_image_surface_get_stride(cairo_get_target(ctx->ct));
  }
  return 0;
}

CGColorSpaceRef CGBitmapContextGetColorSpace(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
  	return ((CGBitmapContext*)ctx)->cs;
  }
  return nil;
}

void *CGBitmapContextGetData(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
    return cairo_image_surface_get_data(cairo_get_target(ctx->ct));
  }
  return 0;
}

size_t CGBitmapContextGetHeight(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
    return cairo_image_surface_get_height(cairo_get_target(ctx->ct));
  }
  return 0;
}

size_t CGBitmapContextGetWidth(CGContextRef ctx)
{
  if ([ctx isKindOfClass: [CGBitmapContext class]])
  {
    return cairo_image_surface_get_width(cairo_get_target(ctx->ct));
  }
  return 0;
}

static void OpalReleaseContext(void *info, const void *data, size_t size)
{
    CGContextRelease(info);
}

CGImageRef CGBitmapContextCreateImage(CGContextRef ctx)
{
    if ([ctx isKindOfClass: [CGBitmapContext class]])
    {
        size_t width = CGBitmapContextGetWidth(ctx);
        size_t height = CGBitmapContextGetHeight(ctx);
        size_t bytesPerRow = width*4;

        png_bytep data = CGBitmapContextGetData(ctx);
        size_t dataSize = bytesPerRow*height;

        // We have to swap red and blue colors, as cairo flips them!
        int count=0;
        for (int i=0; i<height; i++) {
            for (int j=0; j<bytesPerRow; j+=4) {
                //if (j % 4 == 0) {
                png_byte temp = data[count];
                data[count] = data[count+2];
                data[count+2] = temp;
                //}
                count+=4;
            }
        }
        CGDataProviderRef provider = CGDataProviderCreateWithData(CGContextRetain(ctx), data, dataSize, OpalReleaseContext);
        //CGDataProviderRef provider = CGDataProviderCreateWithData(nil, data, dataSize, NULL);
        CGImageRef img = [[CGImage alloc] initWithWidth:width
                                                 height:height
                                       bitsPerComponent:8
                                           bitsPerPixel:32
                                            bytesPerRow:bytesPerRow
                                             colorSpace:CGColorSpaceCreateDeviceRGB() 
                                             bitmapInfo:kCGImageAlphaPremultipliedLast
                                               provider:provider
                                                 decode:NULL
                                      shouldInterpolate:true
                                                 intent:kCGRenderingIntentDefault];

        CGDataProviderRelease(provider);
        return img;
    }
    return nil;
}

CGContextRef _CGBitmapContextCreate(size_t width, size_t height)
{
    int bitmapBytesPerRow   = (width * 4);
    //int bitmapByteCount     = (bitmapBytesPerRow * height);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if (colorSpace == NULL) {
        return nil;
    }
    /*void* bitmapData = malloc(bitmapByteCount);
    if (bitmapData == NULL) {
        CGColorSpaceRelease(colorSpace);
        return nil;
    }*/

    return CGBitmapContextCreate (NULL,
                                  width,
                                  height,
                                  8,
                                  bitmapBytesPerRow,
                                  colorSpace,
                                  kCGImageAlphaPremultipliedLast);
}

CGContextRef _CGBitmapContextCreateWithOptions(CGSize size, BOOL opaque, CGFloat scale)
{
    if (scale == 0.f) {
        scale = 1.0; //[UIScreen mainScreen].scale;
    }
    
    const size_t width = size.width * scale;
    const size_t height = size.height * scale;
    
    if (width > 0 && height > 0) {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        //CGContextRef ctx = CGBitmapContextCreate(NULL, width, height, 8, 4*width, colorSpace, (opaque? kCGImageAlphaNoneSkipFirst : kCGImageAlphaPremultipliedFirst));
        CGContextRef ctx = CGBitmapContextCreate(NULL, width, height, 8, 4*width, colorSpace, kCGImageAlphaPremultipliedFirst);
        //CGContextConcatCTM(ctx, CGAffineTransformMake(1, 0, 0, -1, 0, height));
        //CGContextScaleCTM(ctx, 1.f/scale, 1.f/scale);
        CGColorSpaceRelease(colorSpace);
        return ctx;
    }
    return nil;
}

