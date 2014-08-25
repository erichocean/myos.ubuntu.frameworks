/*
 * Copyright (c) 2012. All rights reserved.
 *
 */

#import "BigAppleDelegate.h"

@implementation BigAppleDelegate

@synthesize window;
@synthesize appleView;
@synthesize sillyButton;

#pragma mark - Life cycle

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    DLog(@"mainScreen: %@", [UIScreen mainScreen]);
    self.window = [[[UIWindow alloc] initWithFrame:[UIScreen mainScreen].applicationFrame] autorelease];
    window.backgroundColor = [UIColor yellowColor];
    window.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    DLog(@"window: %@", window);
    self.appleView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"apple.png"]] autorelease];
    [window addSubview:appleView];

    DLog(@"appleView: %@", appleView);
    self.sillyButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.sillyButton.frame = CGRectMake(22,300,200,50);
    [sillyButton setTitle:@"Click Me!" forState:UIControlStateNormal];
    [sillyButton addTarget:self action:@selector(moveTheApple:) forControlEvents:UIControlEventTouchUpInside];
    [window addSubview:sillyButton];
    
    DLog(@"sillyButton: %@", sillyButton);
    [window makeKeyAndVisible];
}

- (void)dealloc
{
    [window release];
    [appleView release];
    [sillyButton release];
    [super dealloc];
}

#pragma mark - Actions

- (void)moveTheApple:(id)sender
{
    [UIView beginAnimations:@"moveTheApple" context:nil];
    [UIView setAnimationDuration:3];
    [UIView setAnimationBeginsFromCurrentState:YES];

    if (CGAffineTransformIsIdentity(appleView.transform)) {
        appleView.transform = CGAffineTransformMakeScale(0.5, 0.5);
        appleView.center = [window convertPoint:window.center toView:appleView.superview];
    } else {
        appleView.transform = CGAffineTransformIdentity;
        appleView.frame = CGRectMake(0,0,256,256);
    }
    
    [UIView commitAnimations];
}

@end

