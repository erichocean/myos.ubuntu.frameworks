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

#import <IOKit/IOKit.h>
#import "EAGL-private.h"

BOOL _EAGLSwappingBuffers = NO;

static EAGLContext *_currentContext = nil;

#pragma mark - Static C functions

bool checkGLXExtension(const char* extName)
{
    /*
     Search for extName in the extensions string.  Use of strstr()
     is not sufficient because extension names can be prefixes of
     other extension names.  Could use strtok() but the constant
     string returned by glGetString can be in read-only memory.
     */

    EAGLContext *context = _EAGLGetCurrentContext();
    Display *display = context->_display;
    int screen = DefaultScreen(display);
    char *list = (char*) glXQueryExtensionsString(display, screen);
    //NSLog(@"list: %s", list);
    char *end;
    int extNameLen;
    extNameLen = strlen(extName);
    end = list + strlen(list);
    while (list < end) {
        int n = strcspn(list, " ");

        if ((extNameLen == n) && (strncmp(extName, list, n) == 0))
            return true;

        list += (n + 1);
    };
    return false;
}; // bool checkGLXExtension(const char* extName)

static void _EAGLContextCreateContext(EAGLContext *context)
{
    int attribList[] = {
        GLX_DEPTH_SIZE, 1,
        GLX_RGBA,
        GLX_RED_SIZE, 1,
        GLX_GREEN_SIZE, 1,
        GLX_BLUE_SIZE, 1,
        None
    };
    context->_window = [IOWindowGetSharedWindow() retain];
    context->_display = XOpenDisplay(NULL);
    //Display *display = context->_window->display;
    int screen = DefaultScreen(context->_display);
    XVisualInfo *visualInfo;
    visualInfo = glXChooseVisual(context->_display, screen, attribList);
    if (!visualInfo) {
        NSLog(@"glXChooseVisual failed");
        return;
    }
    context->_glXContext = glXCreateContext(context->_display, visualInfo, NULL, GL_TRUE);
    DLog(@"created GLX context: %p", context->_glXContext);  
}

@implementation EAGLShareGroup

@end

@implementation EAGLContext

@synthesize API;
@synthesize shareGroup;

#pragma mark - Life cycle

- (id)initWithAPI:(EAGLRenderingAPI)api
{
    self = [super init];
    if (self) {
        API = api;
        shareGroup = [[EAGLShareGroup alloc] init];
        _EAGLContextCreateContext(self);
    }
    return self;
}

- (id)initWithAPI:(EAGLRenderingAPI)api sharegroup:(EAGLShareGroup *)aSharegroup
{
    self = [super init];
    if (self) {
        API = api;
        shareGroup = [aSharegroup retain];
        _EAGLContextCreateContext(self);
    }
    return self;
}

- (void)dealloc
{
    [shareGroup release];
    [_window release];
    glXDestroyContext(_window->display, _glXContext);
    //eglDestroySurface(_eglDisplay, _eglSurface);
    [super dealloc];
}

#pragma mark - Class methods

+ (BOOL)setCurrentContext:(EAGLContext *)context
{
    if (_currentContext) {
        [_currentContext release];
    }
    _currentContext = [context retain];
    //DLog(@"_currentContext: %@", _currentContext);
    if (context) {
        //DLog(@"context: %@", context);
        BOOL result = glXMakeCurrent(context->_display, context->_window->xwindow, context->_glXContext);
        //DLog(@"result: %d", result);
        if (result) {
            //DLog(@"Success");
            return YES;
        } else {
            //DLog(@"Failed to make current context");
            return NO;
        }
    }
    return NO;
}

+ (EAGLContext *)currentContext
{
    return _EAGLGetCurrentContext();
}

@end

#pragma mark - Public C functions

void EAGLGetVersion(unsigned int *major, unsigned int *minor)
{
    if (_currentContext->API == kEAGLRenderingAPIOpenGLES1) {
        *major = EAGL_MAJOR_VERSION;
        *minor = EAGL_MINOR_VERSION;
    } else {
        *major = 2;
        *minor = 0;
    }
}

#pragma mark - Private C functions

EAGLContext *_EAGLGetCurrentContext()
{
    return _currentContext;
}

void _EAGLSetup()
{
    //DLog();
    glMatrixMode(GL_MODELVIEW);

    glLoadIdentity();

    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    glEnable(GL_TEXTURE_2D);
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    //DLog(@"glGetError: %d", glGetError());
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE,GL_ONE_MINUS_SRC_ALPHA);
    glAlphaFunc(GL_GREATER, 0);
    glEnable(GL_ALPHA_TEST);

/*    void(*swapInterval)(int);
    if (checkGLXExtension("GLX_MESA_swap_control")) {
        swapInterval = (void (*)(int)) glXGetProcAddress((const GLubyte*) "glXSwapIntervalMESA");
        NSLog(@"GLX_MESA_swap_control");
    } else if (checkGLXExtension("GLX_SGI_swap_control")) {
        swapInterval = (void (*)(int)) glXGetProcAddress((const GLubyte*) "glXSwapIntervalSGI");
        NSLog(@"GLX_SGI_swap_control");
    } else {
        printf("no vsync?!\n");
    }

//    NSLog(@"glXSwapIntervalMESA(): %d", glXSwapIntervalMESA(1));
    swapInterval(1);
*/
//    glXSwapIntervalMESA(1);
/*    int(*swapInterval)(int);
    swapInterval = (int (*)(int))glXGetProcAddress((const GLubyte*) "glXSwapIntervalMESA");
    //swapInterval = (int(*)(int))glXGetProcAddress((const GLubyte*) "glXSwapIntervalSGI");
    NSLog(@"swapInterval: %p", swapInterval);
    NSLog(@"swapInterval(): %d", swapInterval(1));
*/
 /*   int(*getSwapInterval)();
    getSwapInterval = (int (*)())glXGetProcAddress((const GLubyte*) "glXGetSwapIntervalMESA");
    NSLog(@"getSwapInterval: %p", getSwapInterval);
    NSLog(@"getSwapInterval(): %d", getSwapInterval());
*/
    _EAGLSetSwapInterval(1);
}

void _EAGLSetSwapInterval(int interval)
{
    void(*swapInterval)(int);
    if (checkGLXExtension("GLX_MESA_swap_control")) {
        swapInterval = (void (*)(int)) glXGetProcAddress((const GLubyte*) "glXSwapIntervalMESA");
        NSLog(@"GLX_MESA_swap_control");
        _currentContext->_vSyncEnabled = YES;
    } else if (checkGLXExtension("GLX_SGI_swap_control")) {
        swapInterval = (void (*)(int)) glXGetProcAddress((const GLubyte*) "glXSwapIntervalSGI");
        NSLog(@"GLX_SGI_swap_control");
        _currentContext->_vSyncEnabled = YES;
    } else {
        printf("no vsync?!\n");
        _currentContext->_vSyncEnabled = NO;
        return;
    }
    swapInterval(interval);
}

void _EAGLClear()
{
    //DLog();
    glClearColor(0,0,0,0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

void _EAGLFinish()
{
    glFinish();
}

void _EAGLFlush()
{
    //EAGLContext *context = _EAGLGetCurrentContext();

    //int retraceCount;
    
    //glXGetVideoSyncSGI(&retraceCount);
    //NSLog(@"retraceCount: %d", retraceCount);
    //glXWaitVideoSyncSGI(2, (retraceCount+1) % 2, &retraceCount);
 
//    glFlush();

   //int(*getSwapInterval)();
    //getSwapInterval = (int (*)())glXGetProcAddress((const GLubyte*) "glXGetSwapIntervalMESA");
    //NSLog(@"getSwapInterval: %p", getSwapInterval);
    //NSLog(@"getSwapInterval(): %d", getSwapInterval());
    //getSwapInterval();
    //glXSwapBuffers(context->_window->display, context->_window->xwindow);
    //DLog(@"glGetError: %d",glGetError());
}

void _EAGLSwapBuffers()
{
    _EAGLSwappingBuffers = YES;
    glFlush();
    _EAGLSwappingBuffers = NO;
}

