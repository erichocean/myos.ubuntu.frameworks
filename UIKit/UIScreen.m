/*
 * Copyright (c) 2011, The Iconfactory. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of The Iconfactory nor the names of its contributors may
 *    be used to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE ICONFACTORY BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <UIKit/UIScreen.h>
#import <UIKit/UIImage-private.h>
#import <UIKit/UIImageView.h>
#import <UIKit/UIApplication.h>
#import <UIKit/UIViewLayoutManager.h>
#import <UIKit/UIColor.h>
//#import <UIKit/UIGeometry.h>
#import <UIKit/UIScreenMode.h>
#import <UIKit/UIWindow.h>

NSString *const UIScreenDidConnectNotification = @"UIScreenDidConnectNotification";
NSString *const UIScreenDidDisconnectNotification = @"UIScreenDidDisconnectNotification";
NSString *const UIScreenModeDidChangeNotification = @"UIScreenModeDidChangeNotification";

NSMutableArray *_allScreens = nil;

@implementation UIScreen

@synthesize bounds=_bounds;
@synthesize applicationFrame;
@synthesize availableModes;
@synthesize currentMode; 
@synthesize scale=_scale;

#pragma mark Life cycle

+ (void)initialize
{
    if (self == [UIScreen class]) {
        _allScreens = [[NSMutableArray alloc] init];
    }
}

- (id)initWithBounds:(CGRect)myBounds
{
    if ((self = [super init])) {
        _bounds = myBounds;
        [_allScreens addObject:self];
        //_layer = [[CALayer layer] retain];
        //_layer.delegate = self;		// required to get the magic of the UIViewLayoutManager...
        //_layer.layoutManager = [UIViewLayoutManager layoutManager];

      //  _layer.geometryFlipped = YES;
        //_layer.sublayerTransform = CATransform3DMakeScale(1,-1,1);
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_allScreens removeObject:[NSValue valueWithNonretainedObject:self]];
    //[_layer release];
    [currentMode release];
    [super dealloc];
}

#pragma mark - Accessors

- (CGFloat)scale
{
    return 1;
}

- (CGRect)applicationFrame
{
    const float statusBarHeight = [UIApplication sharedApplication].statusBarHidden? 0 : 20;
    const CGSize size = [self bounds].size;
    return CGRectMake(0,statusBarHeight,size.width,size.height-statusBarHeight);
}

- (NSArray *)availableModes
{
    return [NSArray arrayWithObject:self.currentMode];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; bounds = %@; mode = %@>", [self className], self, NSStringFromCGRect(self.bounds), self.currentMode];
}

#pragma mark - Class methods

+ (UIScreen *)mainScreen
{
    //return ([_allScreens count] > 0)? [[_allScreens objectAtIndex:0] nonretainedObjectValue] : nil;
    return ([_allScreens count] > 0)? [_allScreens objectAtIndex:0] : nil;
}

+ (NSArray *)screens
{
    NSMutableArray *screens = [NSMutableArray arrayWithCapacity:[_allScreens count]];
    
    for (NSValue *v in _allScreens) {
        [screens addObject:[v nonretainedObjectValue]];
    }
    
    return screens;
}

#pragma mark - Helpers

- (CGPoint)convertPoint:(CGPoint)toConvert toScreen:(UIScreen *)toScreen
{
    // there is only one screen    
    return toConvert;
}

- (CGPoint)convertPoint:(CGPoint)toConvert fromScreen:(UIScreen *)fromScreen
{
    // there is only one screen    
    return toConvert;
}

- (CGRect)convertRect:(CGRect)toConvert toScreen:(UIScreen *)toScreen
{
    // there is only one screen    
    return toConvert;
} 

- (CGRect)convertRect:(CGRect)toConvert fromScreen:(UIScreen *)fromScreen
{
    // there is only one screen    
    return toConvert;
}

- (void)becomeMainScreen
{
    NSValue *entry = [NSValue valueWithNonretainedObject:self];
    NSInteger index = [_allScreens indexOfObject:entry];
    [_allScreens removeObjectAtIndex:index];
    [_allScreens insertObject:entry atIndex:0];
}

- (void)layoutSubviews
{
/*
    if ([self _hasResizeIndicator]) {
        const CGSize layerSize = _layer.bounds.size;
    }*/
}

- (id)actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    return [NSNull null];
}

@end

#pragma mark - Private C functions

UIView *_UIScreenHitTest(UIScreen *screen, CGPoint touchPoint, UIEvent *theEvent)
{
    UIWindow *window = [UIApplication sharedApplication]->_keyWindow;

    if (window.screen == screen) {
        CGPoint windowPoint = [window convertPoint:touchPoint fromWindow:nil];
        UIView *touchedView = [window hitTest:windowPoint withEvent:theEvent];
        if (touchedView) {
            return touchedView;
        }
    }
    return nil;
}

