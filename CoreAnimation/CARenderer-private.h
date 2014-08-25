/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <CoreAnimation/CARenderer.h>

extern CFMutableSetRef _needsDisplayLayers;
extern CFMutableSetRef _needsDisplayPresentationLayers;

void _CARendererInitialize();
//int _CARendererNumberOfNeedsDisplayLayers();
//void _CARendererAddToDisplayLayers(CALayer *layer);
//void _CARendererAddToDisplayPresentationLayers(CALayer *layer);
void _CARendererDisplayLayers(BOOL isModelLayer);
//void _CARendererDisplayPresentationLayers();
void _CARendererLoadRenderLayers();
