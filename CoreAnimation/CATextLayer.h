/*
 Copyright © 2014 myOS Group.
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 Lesser General Public License for more details.
 
 Contributor(s):
 Amr Aboelela <amraboelela@gmail.com>
 */

#import <CoreAnimation/CoreAnimation.h>

extern NSString *const kCATruncationNone;
extern NSString *const kCATruncationStart;
extern NSString *const kCATruncationEnd;
extern NSString *const kCATruncationMiddle;

extern NSString *const kCAAlignmentNatural;
extern NSString *const kCAAlignmentLeft;
extern NSString *const kCAAlignmentRight;
extern NSString *const kCAAlignmentCenter;
extern NSString *const kCAAlignmentJustified;

@interface CATextLayer : CALayer {
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
