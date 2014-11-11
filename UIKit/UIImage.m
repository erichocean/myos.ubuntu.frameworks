/*
 * Copyright (c) 2011, The Iconfactory. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of The Iconfactory nor the names of its contributors may
 *    be used to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE ICONFACTORY BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <UIKit/UIKit-private.h>
#import <OpenGLES/EAGL-private.h>

NSMutableDictionary *_imageCache = nil;

#pragma mark - Static functions

static UIImage *_UIImageCachedImageForName(NSString *name)
{
    return [[UIImage imageCache] objectForKey:name];
}

static UIImage *_UIImageNALoadImageNamed(NSString *name)
{
    //DLog(@"name: %@", name);
    //NSBundle *bundle = [NSBundle mainBundle];
    //DLog(@"bundle: %@", bundle);
    NSString *path = name;//[[bundle resourcePath] stringByAppendingPathComponent:name];
    //DLog(@"path: %@", path);
    UIImage *img = [UIImage imageWithContentsOfFile:path];
    /*
     if (!img) {
     // if nothing is found, try again after replacing any underscores in the name with dashes.
     // I don't know why, but UIKit does something similar. it probably has a good reason and it might not be this simplistic, but
     // for now this little hack makes Ramp Champ work. :)
     path = [[[bundle resourcePath] stringByAppendingPathComponent:[[name stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@"-"]] stringByAppendingPathExtension:[name pathExtension]];
     img = [self imageWithContentsOfFile:path];
     }*/
    return img;
}

static UIImage *_UIImageLoadImageNamed(NSString *name)
{
    //DLog(@"name: %@", name);
    NSBundle *bundle = [NSBundle mainBundle];
    //DLog(@"bundle: %@", bundle);
    NSString *path = [[bundle resourcePath] stringByAppendingPathComponent:name];
    //DLog(@"path: %@", path);
    UIImage *img = [UIImage imageWithContentsOfFile:path];
    /*
     if (!img) {
     // if nothing is found, try again after replacing any underscores in the name with dashes.
     // I don't know why, but UIKit does something similar. it probably has a good reason and it might not be this simplistic, but
     // for now this little hack makes Ramp Champ work. :)
     path = [[[bundle resourcePath] stringByAppendingPathComponent:[[name stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@"-"]] stringByAppendingPathExtension:[name pathExtension]];
     img = [self imageWithContentsOfFile:path];
     }*/
    return img;
}

@implementation UIImage

#pragma mark - Life cycle

- (id)initWithData:(NSData *)data
{
    if (data) {
        return nil;
    } else {
        return nil;
    }
}

- (id)initWithContentsOfFile:(NSString *)path
{
    CGDataProviderRef pngData;
#ifdef NA
    if ([path rangeOfString:@"/"].length > 0) {
        pngData = CGDataProviderCreateWithFilename([path cString]);
        //DLog(@"pngData: %@", pngData);
        _image = CGImageCreateWithPNGDataProvider(pngData, NULL, YES, kCGRenderingIntentDefault);
    } else {
        pngData = CGDataProviderCreateWithFilenameWithAsset([path cString]);
        //DLog(@"pngData: %@", pngData);
        _image = CGImageCreateWithPNGDataProviderWithAsset(pngData, NULL, YES, kCGRenderingIntentDefault);
    }
#else
    pngData = CGDataProviderCreateWithFilename([path cString]);
    //DLog(@"pngData: %@", pngData);
    _image = CGImageCreateWithPNGDataProvider(pngData, NULL, YES, kCGRenderingIntentDefault);
#endif
    //DLog(@"_image: %@", _image);
    CGDataProviderRelease(pngData);
    return self;
}

- (id)initWithCGImage:(CGImageRef)imageRef
{
    if (!imageRef) {
        [self release];
        return nil;
    } else if ((self=[super init])) {
        _image = imageRef;
        CGImageRetain(_image);
    }
    return self;
}

- (void)dealloc
{
    if (_image) {
        CGImageRelease(_image);
    }
    [super dealloc];
}

#pragma mark - Accessors

- (CGSize)size
{
    return CGSizeMake(CGImageGetWidth(_image), CGImageGetHeight(_image));
}

- (NSInteger)leftCapWidth
{
    return 0;
}

- (NSInteger)topCapHeight
{
    return 0;
}

- (CGImageRef)CGImage
{
    return _image;
}

- (UIImageOrientation)imageOrientation
{
    return UIImageOrientationUp;
}

- (CGFloat)scale
{
    return 1.0;
}

#pragma mark - Class methods

+ (NSMutableDictionary *)imageCache
{
    if (_imageCache == nil) {
        _imageCache = [[NSMutableDictionary alloc] init];
    }
    return _imageCache;
}

+ (UIImage *)imageNamed:(NSString *)name
{
    //DLog(@"name: %@", name);

    UIImage *img = _UIImageCachedImageForName(name);

    if (!img) {
        // as per the iOS docs, if it fails to find a match with the bare name, it re-tries by appending a png file extension
#ifdef NA
        img = _UIImageNALoadImageNamed(name) ?: _UIImageNALoadImageNamed([name stringByAppendingPathExtension:@"png"]);
#else
        img = _UIImageLoadImageNamed(name) ?: _UIImageLoadImageNamed([name stringByAppendingPathExtension:@"png"]);
#endif
        _UIImageCacheImage(img, name);
    }

    return img;

/*
    // first try it with the given name
    UIImage *image = _UIImageLoadImageNamed(name);
    
    // if nothing is found, try again after replacing any underscores in the name with dashes.
    // I don't know why, but UIKit does something similar. it probably has a good reason and it might not be this simplistic, but
    // for now this little hack makes Ramp Champ work. :)
    if (!image) {
        image = _UIImageLoadImageNamed([name stringByReplacingOccurrencesOfString:@"_" withString:@"-"]);
    }
    return image;*/
}

+ (UIImage *)imageWithData:(NSData *)data
{
    return [[[UIImage alloc] initWithData:data] autorelease];
}

+ (UIImage *)imageWithContentsOfFile:(NSString *)path
{
    return [[[UIImage alloc] initWithContentsOfFile:path] autorelease];
}

+ (UIImage *)imageWithCGImage:(CGImageRef)imageRef
{
    return [[[UIImage alloc] initWithCGImage:imageRef] autorelease];
}

#pragma mark - Public methods

- (void)drawAtPoint:(CGPoint)point blendMode:(CGBlendMode)blendMode alpha:(CGFloat)alpha
{
    const CGSize size = self.size;
    [self drawInRect:CGRectMake(point.x,point.y,size.width,size.height) blendMode:blendMode alpha:alpha];
}

- (void)drawInRect:(CGRect)rect blendMode:(CGBlendMode)blendMode alpha:(CGFloat)alpha
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGContextSetBlendMode(ctx, blendMode);
    CGContextSetAlpha(ctx, alpha);
    [self drawInRect:rect];
    CGContextRestoreGState(ctx);
}

- (void)drawAtPoint:(CGPoint)point
{
    const CGSize size = self.size;
    [self drawInRect:CGRectMake(point.x,point.y,size.width,size.height)];
}

- (void)drawInRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, rect.origin.x, rect.origin.y+rect.size.height);
    CGContextScaleCTM(ctx, 1.0, -1.0);
    CGContextDrawImage(ctx, CGRectMake(0,0,rect.size.width,rect.size.height), _image);
    CGContextRestoreGState(ctx);
}

@end

#pragma mark - Shared functions

void UIImageWriteToSavedPhotosAlbum(UIImage *image, id completionTarget, SEL completionSelector, void *contextInfo)
{
    [[UIPhotosAlbum sharedPhotosAlbum] writeImage:image completionTarget:completionTarget action:completionSelector context:contextInfo];
}

void UISaveVideoAtPathToSavedPhotosAlbum(NSString *videoPath, id completionTarget, SEL completionSelector, void *contextInfo)
{
}

BOOL UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(NSString *videoPath)
{
    return NO;
}

NSData *UIImageJPEGRepresentation(UIImage *image, CGFloat compressionQuality)
{
    return nil;
}

NSData *UIImagePNGRepresentation(UIImage *image)
{
    return nil;
}

NSString *_UIImageMacPathForFile(NSString* path)
{
    NSString *home = [path stringByDeletingLastPathComponent];
    NSString *filename = [path lastPathComponent];
    NSString *extension = [filename pathExtension];
    NSString *bareFilename = [filename stringByDeletingPathExtension];

    return [home stringByAppendingPathComponent:[[bareFilename stringByAppendingString:@"@mac"] stringByAppendingPathExtension:extension]];
}

NSString *_UIImagePathForFile(NSString* path)
{
    NSString *macPath = _UIImageMacPathForFile(path);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:macPath]) {
        return macPath;
    } else {
        return path;
    }
}

void _UIImageCacheImage(UIImage *image, NSString *name)
{
    if (image && name) {
        [[UIImage imageCache] setObject:image forKey:name];
    }
}

// NSString *_UIImageNameForCachedImage(UIImage* image)
// {
//     __block NSString * result = nil;
//     [[UIImage imageCache] enumerateKeysAndObjectsUsingBlock: ^(id key, id obj, BOOL *stop) {
//         if ( obj == image ) {
//             result = [key copy];
//             *stop = YES;
//         }
//     }];
//     return [result autorelease];
// }

UIImage *_UIImageFrameworkImageWithName(NSString* name, NSUInteger leftCapWidth, NSUInteger topCapHeight)
{
    UIImage *image = _UIImageCachedImageForName(name);

    if (!image) {
        NSBundle *frameworkBundle = [NSBundle bundleWithIdentifier:@"org.chameleonproject.UIKit"];
        NSString *frameworkFile = [[frameworkBundle resourcePath] stringByAppendingPathComponent:name];
        image = [UIImage imageWithContentsOfFile:frameworkFile];// stretchableImageWithLeftCapWidth:leftCapWidth topCapHeight:topCapHeight];
        _UIImageCacheImage(image, name);
    }
    return image;
}

UIImage *_UIImageBackButtonImage()
{
    return _UIImageFrameworkImageWithName(@"<UINavigationBar> back.png", 18, 0);
}

UIImage *_UIImageHighlightedBackButtonImage()
{
    return _UIImageFrameworkImageWithName(@"<UINavigationBar> back-highlighted.png", 18, 0);
}

UIImage *_UIImageToolbarButtonImage()
{
    return _UIImageFrameworkImageWithName(@"<UIToolbar> button.png", 6, 0);
}

UIImage *_UIImageHighlightedToolbarButtonImage()
{
    return _UIImageFrameworkImageWithName(@"<UIToolbar> button-highlighted.png", 6, 0);
}

UIImage *_UIImageLeftPopoverArrowImage()
{
    return _UIImageFrameworkImageWithName(@"<UIPopoverView> arrow-left.png", 0, 0);
}

UIImage *_UIImageRightPopoverArrowImage()
{
    return _UIImageFrameworkImageWithName(@"<UIPopoverView> arrow-right.png", 0, 0);
}

UIImage *_UIImageTopPopoverArrowImage()
{
    return _UIImageFrameworkImageWithName(@"<UIPopoverView> arrow-top.png", 0, 0);
}

UIImage *_UIImageBottomPopoverArrowImage()
{
    return _UIImageFrameworkImageWithName(@"<UIPopoverView> arrow-bottom.png", 0, 0);
}

UIImage *_UIImagePopoverBackgroundImage()
{
    return _UIImageFrameworkImageWithName(@"<UIPopoverView> background.png", 23, 23);
}

UIImage *_UIImageRoundedRectButtonImage()
{
    return _UIImageFrameworkImageWithName(@"<UIRoundedRectButton> normal.png", 12, 9);
}

UIImage *_UIImageHighlightedRoundedRectButtonImage()
{
    return _UIImageFrameworkImageWithName(@"<UIRoundedRectButton> highlighted.png", 12, 9);
}

UIImage *_UIImageWindowResizeGrabberImage()
{
    return _UIImageFrameworkImageWithName(@"<UIScreen> grabber.png", 0, 0);
}

UIImage *_UIImageButtonBarSystemItemAdd()
{
    return _UIImageFrameworkImageWithName(@"<UIBarButtonSystemItem> add.png", 0, 0);
}

UIImage *_UIImageButtonBarSystemItemReply()
{
    return _UIImageFrameworkImageWithName(@"<UIBarButtonSystemItem> reply.png", 0, 0);
}

UIImage *_UIImageToolbarImage(UIImage *image)
{
    // NOTE.. I don't know where to put this, really, but it seems like the real UIKit reduces image size by 75% if they are too
    // big for a toolbar. That seems funky, but I guess here is as good a place as any to do that? I don't really know...

    CGSize imageSize = image.size;
    CGSize size = CGSizeZero;
    
    if (imageSize.width > 24 || imageSize.height > 24) {
        size.height = imageSize.height * 0.75f;
        size.width = imageSize.width / imageSize.height * size.height;
    } else {
        size = imageSize;
    }
    CGRect rect = CGRectMake(0,0,size.width,size.height);
    
    UIGraphicsBeginImageContext(size);
    [[UIColor colorWithRed:101/255.f green:104/255.f blue:121/255.f alpha:1] setFill];
    UIRectFill(rect);
    [image drawInRect:rect blendMode:kCGBlendModeDestinationIn alpha:1];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}

UIImage *_UIImageTabBarBackgroundImage()
{
    return _UIImageFrameworkImageWithName(@"<UITabBar> background.png", 6, 0);
}

UIImage *_UIImageTabBarItemImage()
{
    return _UIImageFrameworkImageWithName(@"<UITabBar> item.png", 8, 0);
}

UIImage *_UIImageCaptureScreen()
{
    //UIScreen *screen = [UIScreen mainScreen];
    //CGFloat s = screen->_scale;
    //if ([screen respondsToSelector:@selector(scale)]) {
    //s = (int)screen->_scale;
    //}
    //DLog(@"s: %.1f", s);
    
    EAGLContext *context = _EAGLGetCurrentContext();
    //_hScale = context->_width * 1.0 / _kScreenWidth;
    //_vScale = context->_height * 1.0 / _kScreenHeight;
    
    //CGRect frame = [screen bounds];
    const int w = context->_width;
    const int h = context->_height;
    const NSInteger myDataLength = w * h * 4;
    DLog(@"w: %d, h: %d", w, h);
    // allocate array and read pixels into it.
    GLubyte *buffer = (GLubyte *)malloc(myDataLength);
    DLog();
    glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
    DLog();
    // gl renders "upside down" so swap top to bottom into new array.
    // there's gotta be a better way, but this works.
    /*GLubyte *buffer2 = (GLubyte *)malloc(myDataLength);
     DLog();
     for (int y = 0; y < h*s; y++) {
     memcpy(buffer2 + (h*s - 1 - y) * w * 4 * s, buffer + (y * 4 * w * s), w * 4 * s);
     }*/
    //DLog();
    //free(buffer); // work with the flipped buffer, so get rid of the original one.
    //DLog();
    // make data provider with data.
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, myDataLength, NULL);
    // prep the ingredients
    /*int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = 4 * w * s;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;//kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;*/
    DLog();
    // make the cgimage
    
    CGImageRef imageRef = [[CGImage alloc] initWithWidth:w
                                                  height:h
                                        bitsPerComponent:8
                                            bitsPerPixel:32
                                             bytesPerRow:4*w
                                              colorSpace:CGColorSpaceCreateWithName(kCGColorSpaceAdobeRGB1998)
                                              bitmapInfo:kCGImageAlphaPremultipliedLast
                                                provider:provider
                                                  decode:NULL
                                       shouldInterpolate:YES
                                                  intent:kCGRenderingIntentDefault];
    
    //CGImageRef imageRef = CGImageCreate(w, h, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    DLog();
    // then make the uiimage from that
    UIImage *image = [[[UIImage alloc] initWithCGImage:imageRef] autorelease];
    CGImageRelease(imageRef);
    return image;
    //return [UIImage imageWithCGImage:imageRef scale:s orientation:UIImageOrientationUp];
}
