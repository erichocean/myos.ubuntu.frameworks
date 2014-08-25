/*
 * Copyright (c) 2013. All rights reserved.
 */

#import <OpenGLES/EAGL.h>

extern BOOL _EAGLSwappingBuffers;

extern EAGLContext *_EAGLGetCurrentContext();
extern void _EAGLSetup();
extern void _EAGLSetSwapInterval(int interval);
extern void _EAGLClear();
extern void _EAGLFlush();
extern void _EAGLSwapBuffers();

