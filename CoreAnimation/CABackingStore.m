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

#import <CoreAnimation/CoreAnimation-private.h>

@implementation CABackingStore

#pragma mark - Life cycle

- (id)init
{
    self = [super init];
    if (self) {
        _texture = [[EAGLTexture alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_texture release];
    [super dealloc];
}

@end

#pragma mark - Shared functions

void _CABackingStoreLoad(CABackingStore *backingStore, NSArray *images)
{
    //DLog();
    _EAGLTextureLoad(backingStore->_texture, images);
    //DLog(@"backingStore->_texture: %@", backingStore->_texture);
}

void _CABackingStoreUnload(CABackingStore *backingStore)
{
    //DLog();
    _EAGLTextureUnload(backingStore->_texture);
}

BOOL _CABackingStoreUnloaded(CABackingStore *backingStore)
{
    return _EAGLTextureUnloaded(backingStore->_texture);
}
