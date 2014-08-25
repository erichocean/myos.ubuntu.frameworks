/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import <UIKit/UIFont.h>

@class NSFont;

- (id) initWithName:(NSString *)name size:(CGFloat)size;
UIFont* _UIFontCreateFontWithNSFont(NSFont* aFont);
NSFont* _UIFontGetNSFont(UIFont* font);
