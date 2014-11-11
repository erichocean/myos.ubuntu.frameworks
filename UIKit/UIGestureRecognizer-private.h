/*
 Copyright © 2014 myOS Group.
 
 This file is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2 of the License, or (at your option) any later version.
 
 This file is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 Lesser General Public License for more details.
 
 Contributor(s):
 Amr Aboelela <amraboelela@gmail.com>
 */

#import <UIKit/UIGestureRecognizer.h>

void _UIGestureRecognizerSetView(UIGestureRecognizer *gr, UIView *v);
void _UIGestureRecognizerRecognizeTouches(UIGestureRecognizer *recognizer, NSSet *touches, UIEvent *event);
void _UIGestureRecognizerPerformActions(UIGestureRecognizer *recognizer);

@interface UIGestureRecognizer()

@property (nonatomic,readwrite) UIGestureRecognizerState state;

- (void)_changeStatus;
- (void)ignoreTouch:(UITouch *)touch forEvent:(UIEvent *)event;		// don't override

// override, but be sure to call super
- (void)reset;
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

@end