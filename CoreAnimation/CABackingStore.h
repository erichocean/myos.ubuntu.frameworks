/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import <CoreAnimation/CABase.h>

@class EAGLTexture;

@interface CABackingStore : NSObject
{
@package
    EAGLTexture *texture;
}

@end

void _CABackingStoreLoad(CABackingStore *backingStore, CGImageRef contents);
void _CABackingStoreUnload(CABackingStore *backingStore);
BOOL _CABackingStoreUnloaded(CABackingStore *backingStore);
