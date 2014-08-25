/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import <CoreAnimation/CABase.h>

void _CALayerObserverInitialize();

@interface CALayerObserver : NSObject

@end

CALayerObserver *_CALayerObserverGetSharedObserver();

