/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import <UIKit/UIGestureRecognizer.h>

void _UIGestureRecognizerSetView(UIGestureRecognizer *gr, UIView *v);
void _UIGestureRecognizerRecognizeTouches(UIGestureRecognizer *recognizer, NSSet *touches, UIEvent *event);
void _UIGestureRecognizerPerformActions(UIGestureRecognizer *recognizer);

@interface UIGestureRecognizer()

- (void)_changeStatus;

@end
