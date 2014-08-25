/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import <UIKit/UIEvent.h>

@interface UIEvent (private)
- (id)initWithEventType:(UIEventType)type;
@end

void _UIEventSetTouch(UIEvent* event, UITouch* touch);
void _UIEventSetTimestamp(UIEvent* event, NSTimeInterval timestamp);
//void _UIEventSetUnhandledKeyPressEvent(UIEvent* event);
//BOOL _UIEventIsUnhandledKeyPressEvent(UIEvent* event);
