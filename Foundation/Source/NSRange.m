/** NSRange - range functions
 * Copyright (C) 1993, 1994, 1995 Free Software Foundation, Inc.
 *
 * Written by:  Adam Fedor <fedor@boulder.colorado.edu>
 * Date: Mar 1995
 *
 * This file is part of the GNUstep Base Library.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02111 USA.

   <title>NSRange class reference</title>
   $Date: 2010-02-19 00:12:46 -0800 (Fri, 19 Feb 2010) $ $Revision: 29669 $
 */

#import "common.h"

#define	IN_NSRANGE_M 1
#import "Foundation/NSException.h"
#import "Foundation/NSRange.h"
#import "Foundation/NSScanner.h"

@class	NSString;

static Class	NSStringClass = 0;
static Class	NSScannerClass = 0;
static SEL	scanIntSel;
static SEL	scanStringSel;
static SEL	scannerSel;
static BOOL	(*scanIntImp)(NSScanner*, SEL, int*);
static BOOL	(*scanStringImp)(NSScanner*, SEL, NSString*, NSString**);
static id 	(*scannerImp)(Class, SEL, NSString*);

static inline void
setupCache(void)
{
  if (NSStringClass == 0)
    {
      NSStringClass = [NSString class];
      NSScannerClass = [NSScanner class];
      scanIntSel = @selector(scanInt:);
      scanStringSel = @selector(scanString:intoString:);
      scannerSel = @selector(scannerWithString:);
      scanIntImp = (BOOL (*)(NSScanner*, SEL, int*))
	[NSScannerClass instanceMethodForSelector: scanIntSel];
      scanStringImp = (BOOL (*)(NSScanner*, SEL, NSString*, NSString**))
	[NSScannerClass instanceMethodForSelector: scanStringSel];
      scannerImp = (id (*)(Class, SEL, NSString*))
	[NSScannerClass methodForSelector: scannerSel];
    }
}

NSRange
NSRangeFromString(NSString *aString)
{
  NSScanner	*scanner;
  NSRange	range;

  setupCache();
  scanner = (*scannerImp)(NSScannerClass, scannerSel, aString);
  if ((*scanStringImp)(scanner, scanStringSel, @"{", NULL)
    && (*scanStringImp)(scanner, scanStringSel, @"location", NULL)
    && (*scanStringImp)(scanner, scanStringSel, @"=", NULL)
    && (*scanIntImp)(scanner, scanIntSel, (int*)&range.location)
    && (*scanStringImp)(scanner, scanStringSel, @",", NULL)
    && (*scanStringImp)(scanner, scanStringSel, @"length", NULL)
    && (*scanStringImp)(scanner, scanStringSel, @"=", NULL)
    && (*scanIntImp)(scanner, scanIntSel, (int*)&range.length)
    && (*scanStringImp)(scanner, scanStringSel, @"}", NULL))
    return range;
  else
    return NSMakeRange(0, 0);
}

NSString *
NSStringFromRange(NSRange range)
{
  setupCache();
  return [NSStringClass stringWithFormat: @"{location=%d, length=%d}",
    range.location, range.length];
}

GS_EXPORT void _NSRangeExceptionRaise ()
{
  [NSException raise: NSRangeException
	       format: @"Range location + length too great"];
}
