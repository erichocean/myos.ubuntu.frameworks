/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <CoreAnimation/CABase.h>

// Composite means show Render Layer content to the window
@interface CACompositor : NSObject

@end

//void _CACompositorInitialize();
void _CACompositorPrepareComposite();
void _CACompositorComposite();
//void _CACompositorNeedsFlush(BOOL needsFlush);
