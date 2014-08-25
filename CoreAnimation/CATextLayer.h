/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import "CALayer.h"

extern NSString *const kCATruncationNone;
extern NSString *const kCATruncationStart;
extern NSString *const kCATruncationEnd;
extern NSString *const kCATruncationMiddle;

extern NSString *const kCAAlignmentNatural;
extern NSString *const kCAAlignmentLeft;
extern NSString *const kCAAlignmentRight;
extern NSString *const kCAAlignmentCenter;
extern NSString *const kCAAlignmentJustified;

@interface CATextLayer : CALayer
{
@package
 	id string;
 	CFTypeRef font;
 	CGFloat fontSize;
 	CGColorRef foregroundColor;
 	BOOL wrapped;
 	NSString *alignmentMode;
 	NSString *truncationMode;
 	BOOL secureTextEntry;
 	NSRange selectedRange;
}

@property (copy) id string;
@property CFTypeRef font;
@property CGFloat fontSize;
@property (assign) CGColorRef textColor;
@property (getter=isWrapped) BOOL wrapped;
@property (copy) NSString *truncationMode;
@property (copy) NSString *alignmentMode;
@property (getter=isSecureTextEntry) BOOL secureTextEntry;
@property (assign) NSRange selectedRange;

@end
