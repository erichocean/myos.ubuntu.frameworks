/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import <CoreAnimation/CoreAnimation-private.h>

@implementation CABackingStore

#pragma mark - Life cycle

- (id)init
{
    self = [super init];
    if (self) {
        texture = [[EAGLTexture alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [texture release];
    [super dealloc];
}

@end

#pragma mark - ========== C functions ==========

void _CABackingStoreLoad(CABackingStore *backingStore, CGImageRef contents)
{
    _EAGLTextureLoad(backingStore->texture, contents);
    //DLog(@"backingStore->texture: %@", backingStore->texture);
}

void _CABackingStoreUnload(CABackingStore *backingStore)
{
    _EAGLTextureUnload(backingStore->texture);
}

BOOL _CABackingStoreUnloaded(CABackingStore *backingStore)
{
    return _EAGLTextureUnloaded(backingStore->texture);
}
