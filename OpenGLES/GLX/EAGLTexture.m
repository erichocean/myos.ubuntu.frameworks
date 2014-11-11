/*
 Copyright © 2014 myOS Group.
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 Lesser General Public License for more details.
 
 Contributor(s):
 Amr Aboelela <amraboelela@gmail.com>
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
        //DLog(@"textureID: %d", textureID);
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
        //DLog(@"textureID: %d", texture->textureID);
        //GLuint textureID = 0;
        //glGenTextures(1, &textureID);
    }
    glBindTexture(GL_TEXTURE_2D, texture->textureID);

    //DLog(@"width:%d, height:%d, textureID:%d", width, height, texture->textureID);

    //glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, data);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    //DLog(@"glGetError: %d", glGetError());
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
}

void _EAGLTextureUnload(EAGLTexture *texture)
{
    if (texture->textureID > 0) {
        glDeleteTextures(1, &texture->textureID);
        texture->textureID = 0;
    }
}

BOOL _EAGLTextureUnloaded(EAGLTexture *texture)
{
    return (texture->textureID == 0);
}

