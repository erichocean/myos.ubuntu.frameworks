/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import <IOKit/IOKit.h>
#import "EAGL-private.h"

#import <IOKit/IOWindow.h>
#import <GL/gl.h>
#import <GL/glx.h>

BOOL _EAGLSwappingBuffers = NO;

static EAGLContext *_currentContext = nil;

#pragma mark - Static C functions

static bool checkGLXExtension(const char* extName)
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

    while (list < end)
    {
        int n = strcspn(list, " ");

        if ((extNameLen == n) && (strncmp(extName, list, n) == 0))
            return true;

        list += (n + 1);
    };
    return false;
}; // bool checkGLXExtension(const char* extName)

static void _EAGLContextCreateContext(EAGLContext *context)
{
    EGLint eglAttributes[] = {
        EGL_RED_SIZE, 8,
        EGL_GREEN_SIZE, 8,
        EGL_BLUE_SIZE, 8,
        EGL_DEPTH_SIZE, 0,
        EGL_MAX_SWAP_INTERVAL, 0,
        EGL_MIN_SWAP_INTERVAL, 0,
        EGL_NONE
    };
    EGLint eglContextAttributes[] = {
        EGL_CONTEXT_CLIENT_VERSION, 1,
        EGL_NONE
    };
    EGLint nConfigs = 0;
    EGLint versionMajor;
    EGLint versionMinor;
    
    context->_window = [IOWindowGetSharedWindow() retain];
    context->_display = XOpenDisplay(NULL);
    context->_eglDisplay = eglGetDisplay(context->_display);
    //DLog(@"eglGetError: %d",eglGetError());
    eglInitialize(context->_eglDisplay, &versionMajor, &versionMinor);
    //DLog(@"eglGetError: %d",eglGetError());
    //NSLog(@"Major and minor: %d %d", versionMajor, versionMinor);
    
    const char *ver = eglQueryString(context->_eglDisplay, EGL_VERSION);
    //NSLog(@"EGL_VERSION: %s", ver);
    
    // Choose FB config.
    if (!eglChooseConfig(context->_eglDisplay, eglAttributes, context->_eglFBConfig, 1, &nConfigs)) {
        NSLog(@"Couldn't choose any egl fb configs (nConfigs: %d), aborting", nConfigs);
        abort();
    }
    //DLog(@"nConfigs: %d", nConfigs);
    //NSLog(@"context->_eglFBConfig[0]: %p", context->_eglFBConfig[0]);
    context->_eglSurface = eglCreateWindowSurface(context->_eglDisplay, context->_eglFBConfig[0], context->_window->xwindow, 0);
    //NSLog(@"created EGL window surface");
    context->_eglContext = eglCreateContext(context->_eglDisplay, context->_eglFBConfig[0], EGL_NO_CONTEXT, eglContextAttributes);
    //NSLog(@"created EGL context: %p", context->_eglContext);
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
    eglDestroyContext(_eglDisplay, _eglContext);
    eglDestroySurface(_eglDisplay, _eglSurface);
    [super dealloc];
}

#pragma mark - Class methods

+ (BOOL)setCurrentContext:(EAGLContext *)context
{
    if (_currentContext) {
        //DLog();
        [_currentContext release];
    }
    _currentContext = [context retain];
    if (context) {
        //DLog(@"eglGetError: %d",eglGetError());
        eglMakeCurrent(context->_eglDisplay, context->_eglSurface, context->_eglSurface, context->_eglContext);
        //DLog(@"eglGetError: %d",eglGetError());
        //DLog(@"%d", eglSwapInterval(context->_eglDisplay, 0));
        //DLog(@"eglGetError: %d",eglGetError());
        return YES;
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
    glMatrixMode(GL_MODELVIEW);
    //DLog(@"glGetError: %d", glGetError());

    glLoadIdentity();

    glEnable(GL_DEPTH_TEST);
    //DLog(@"glGetError: %d", glGetError());
    glDepthFunc(GL_LEQUAL);
    glEnable(GL_TEXTURE_2D);
    //DLog(@"glGetError: %d", glGetError());
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    //DLog(@"glGetError: %d", glGetError());
    glEnable(GL_BLEND);
    //DLog(@"glGetError: %d", glGetError());
    glBlendFunc(GL_ONE,GL_ONE_MINUS_SRC_ALPHA);
    glAlphaFunc(GL_GREATER, 0);
    //DLog(@"glGetError: %d", glGetError());
    glEnable(GL_ALPHA_TEST);
    //DLog(@"glGetError: %d", glGetError());

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
    glClearColor(0,0,0,1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

void _EAGLFlush()
{
    glFlush();
}

void _EAGLSwapBuffers()
{
    glFlush();
    _EAGLSwappingBuffers = YES;
    EAGLContext *currentContext = _EAGLGetCurrentContext();
    eglSwapBuffers(currentContext->_eglDisplay, currentContext->_eglSurface);
    _EAGLSwappingBuffers = NO;
}

