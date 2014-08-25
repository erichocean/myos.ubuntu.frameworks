/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <GL/gl.h>

@interface EAGLTexture : NSObject
{
@package
    GLuint textureID;
}

@end

void _EAGLTextureLoad(EAGLTexture *texture, CGImageRef image);
void _EAGLTextureUnload(EAGLTexture *texture);
BOOL _EAGLTextureUnloaded(EAGLTexture *texture);
