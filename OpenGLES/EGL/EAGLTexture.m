/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import "EAGLTexture.h"
#import <CoreGraphics/CoreGraphics-private.h>

@implementation EAGLTexture

#pragma mark - Life cycle

- (id)init
{
    self = [super init];
    if (self) {
        glGenTextures(1, &textureID);
    }
    return self;
}

- (void)dealloc
{
    if (textureID>0) {
        glDeleteTextures(1, &textureID);
    }
    [super dealloc];
}

#pragma mark - Accessors

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; textureID:%d>", [self className], self, textureID];
}

@end

#pragma mark - ========== C functions ==========

void _EAGLTextureLoad(EAGLTexture *texture, CGImageRef image)
{
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    CGDataProviderRef provider = CGImageGetDataProvider(image);
    const uint8_t *data = (const uint8_t *)[provider bytePointer];
 
    if (texture->textureID == 0) {
        glGenTextures(1, &texture->textureID);
        GLuint textureID = 0;
        glGenTextures(1, &textureID);
        //DLog(@"glGetError: %d", glGetError());
    }
    glBindTexture(GL_TEXTURE_2D, texture->textureID);
    //DLog(@"glGetError: %d", glGetError());

    //DLog(@"width:%d, height:%d, textureID:%d", width, height, texture->textureID);

    //glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, data);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    //DLog(@"glGetError: %d", glGetError());
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    //DLog(@"glGetError: %d", glGetError());
}

void _EAGLTextureUnload(EAGLTexture *texture)
{
    if (texture->textureID > 0) {
        //DLog(@"textureID: %d", texture->textureID);
        glDeleteTextures(1, &texture->textureID);
        //DLog(@"glGetError: %d", glGetError());
        texture->textureID = 0;
    }
}

BOOL _EAGLTextureUnloaded(EAGLTexture *texture)
{
    return (texture->textureID == 0);
}
