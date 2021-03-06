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

#import <UIKit/UIKit-private.h>
 
static id _UIViewControllerNearestParentViewControllerThatIsKindOf(UIViewController *aController, Class c)
{
    UIViewController *controller = aController->_parentViewController;
    while (controller && ![controller isKindOfClass:c]) {
        controller = controller->_parentViewController;
    }
    return controller;
}

@implementation UIViewController

@synthesize view=_view, wantsFullScreenLayout=_wantsFullScreenLayout, title=_title, contentSizeForViewInPopover=_contentSizeForViewInPopover;
@synthesize modalInPopover=_modalInPopover, toolbarItems=_toolbarItems, modalPresentationStyle=_modalPresentationStyle, editing=_editing;
@synthesize modalViewController=_modalViewController, parentViewController=_parentViewController;
@synthesize modalTransitionStyle=_modalTransitionStyle, hidesBottomBarWhenPushed=_hidesBottomBarWhenPushed;
@synthesize searchDisplayController=_searchDisplayController, tabBarItem=_tabBarItem, tabBarController=_tabBarController;

#pragma mark - Life cycle

- (id)init
{
    return [self initWithNibName:nil bundle:nil];
} 

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
    if ((self=[super init])) {
        _contentSizeForViewInPopover = CGSizeMake(320,1100);
        _hidesBottomBarWhenPushed = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    //DLog();
}

- (void)viewDidUnload
{
}

- (void)viewWillAppear:(BOOL)animated
{
}

- (void)viewDidAppear:(BOOL)animated
{
}

- (void)viewWillDisappear:(BOOL)animated
{
}

- (void)viewDidDisappear:(BOOL)animated
{
}

- (void)dealloc
{
    _view->_viewController=nil;
    [_modalViewController release];
    [_navigationItem release];
    [_title release];
    [_view release];
    //DLog();
    [super dealloc];
}

#pragma mark - Accessors

- (NSString *)nibName
{
    return nil;
}

- (NSBundle *)nibBundle
{
    return nil;
}

- (UIResponder *)nextResponder
{
    return _view.superview;
}

- (BOOL)isViewLoaded
{
    return (_view != nil);
}

- (UIView *)view
{
    //DLog();
    if ([self isViewLoaded]) {
        return _view;
    } else {
        [self loadView];
        //DLog();
        [self viewDidLoad];
        return _view;
    }
}

- (void)setView:(UIView *)aView
{
    //DLog();
    if (aView != _view) {
        //DLog();
        if (_view) {
            _view->_viewController=nil;
            [_view release];
        }
        _view = [aView retain];
        //DLog();
        _view->_viewController=self;
    }
}

- (UIInterfaceOrientation)interfaceOrientation
{
    return (UIInterfaceOrientation)UIDeviceOrientationPortrait;
}

- (UINavigationItem *)navigationItem
{
    if (!_navigationItem) {
        _navigationItem = [[UINavigationItem alloc] initWithTitle:self.title];
    }
    return _navigationItem;
}

- (void)setToolbarItems:(NSArray *)theToolbarItems animated:(BOOL)animated
{
    if (_toolbarItems != theToolbarItems) {
        [_toolbarItems release];
        _toolbarItems = [theToolbarItems retain];
        [self.navigationController.toolbar setItems:_toolbarItems animated:animated];
    }
}

- (void)setToolbarItems:(NSArray *)theToolbarItems
{
    [self setToolbarItems:theToolbarItems animated:NO];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    _editing = editing;
}

- (void)setEditing:(BOOL)editing
{
    [self setEditing:editing animated:NO];
}

- (UIBarButtonItem *)editButtonItem
{
    // this should really return a fancy bar button item that toggles between edit/done and sends setEditing:animated: messages to this controller
    return nil;
}

- (UINavigationController *)navigationController
{
    return _UIViewControllerNearestParentViewControllerThatIsKindOf(self, [UINavigationController class]);
}

- (UISplitViewController *)splitViewController
{
    return _UIViewControllerNearestParentViewControllerThatIsKindOf(self, [UISplitViewController class]);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; title = %@; view = %@>", [self className], self, self.title, self.view];
}

#pragma mark - Delegates

- (void)didReceiveMemoryWarning
{
}

#pragma mark - Public methods

- (void)loadView
{
    //DLog(); 
    CGRect frame = [[UIScreen mainScreen] bounds]; 
    frame = CGRectMake(frame.origin.x, frame.origin.y+_kStatusBarHeight, frame.size.width, frame.size.height-_kStatusBarHeight);
    //frame = CGRectMake(frame.origin.x, frame.origin.y+50, frame.size.width, frame.size.height-50);
    self.view = [[[UIView alloc] initWithFrame:frame] autorelease];
}

- (void)presentModalViewController:(UIViewController *)modalViewController animated:(BOOL)animated
{
    if (!_modalViewController && _modalViewController != self) {
        _modalViewController = [modalViewController retain];
        _modalViewController->_parentViewController = self;

        UIWindow *window = self.view.window;
        UIView *selfView = self.view;
        UIView *newView = _modalViewController.view;

        newView.autoresizingMask = selfView.autoresizingMask;
        newView.frame = _wantsFullScreenLayout? window.screen.bounds : window.screen.applicationFrame;

        [window addSubview:newView];
        [_modalViewController viewWillAppear:animated];

        [self viewWillDisappear:animated];
        selfView.hidden = YES;		// I think the real one may actually remove it, which would mean needing to remember the superview, I guess? Not sure...
        [self viewDidDisappear:animated];
        [_modalViewController viewDidAppear:animated];
    }
}

- (void)dismissModalViewControllerAnimated:(BOOL)animated
{
    // NOTE: This is not implemented entirely correctly - the actual dismissModalViewController is somewhat subtle.
    // There is supposed to be a stack of modal view controllers that dismiss in a specific way,e tc.
    // The whole system of related view controllers is not really right - not just with modals, but everything else like
    // navigationController, too, which is supposed to return the nearest nav controller down the chain and it doesn't right now.

    if (_modalViewController) {
        
        // if the modalViewController being dismissed has a modalViewController of its own, then we need to go dismiss that, too.
        // otherwise things can be left hanging around.
        if (_modalViewController.modalViewController) {
            [_modalViewController dismissModalViewControllerAnimated:animated];
        }
        
        self.view.hidden = NO;
        [self viewWillAppear:animated];
        
        [_modalViewController.view removeFromSuperview];
        _modalViewController->_parentViewController = nil;
        [_modalViewController autorelease];
        _modalViewController = nil;

        [self viewDidAppear:animated];
    } else {
        [self->_parentViewController dismissModalViewControllerAnimated:animated];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
}

@end
