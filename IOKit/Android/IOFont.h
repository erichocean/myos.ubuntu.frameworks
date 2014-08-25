/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import <CoreGraphics/CGFont-private.h>
#import <cairo.h>

@class CGFont;

@interface IOFont : CGFont
{
@public
    cairo_scaled_font_t *cairofont;
}
@end
