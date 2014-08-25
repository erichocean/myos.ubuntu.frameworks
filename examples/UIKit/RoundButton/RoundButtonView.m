/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import "RoundButtonView.h"

@implementation RoundButtonView

@synthesize button;

#pragma mark - Life cycle

- (id)initWithFrame:(CGRect)theFrame
{
    self = [super initWithFrame:theFrame];
    if (self) {
        self.backgroundColor = [UIColor greenColor];
        self.button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        self.button.backgroundColor = [UIColor whiteColor];
        self.button.layer.borderColor = [[UIColor grayColor] CGColor];
        self.button.frame = CGRectMake(50,50,200,100);
        [self.button setTitle:@"Toto" forState:UIControlStateNormal];
        [self.button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        self.button.titleLabel.font = [UIFont boldSystemFontOfSize:30];
//        [button addTarget:self action:@selector(clickedButton:) forControlEvents:UIControlEventTouchDown];
//        [button addTarget:self action:@selector(unClickButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
    }
    return self;
}

- (void)dealloc
{
    [button release];
    [super dealloc];
}

#pragma mark - Actions
/*
- (void)clickedButton:(id)sender
{
    DLog(@"sender: %@", sender);
    self.button.highlighted = YES;
//    [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(unClickButton) userInfo:nil repeats:NO];
}

- (void)unClickButton:(id)sender
{
    DLog(@"sender: %@", sender);
    self.button.highlighted = NO;
}
*/
@end

