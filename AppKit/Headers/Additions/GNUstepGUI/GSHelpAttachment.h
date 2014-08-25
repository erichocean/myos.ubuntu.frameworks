/** <title>GSHelpAttachment</title>

   Copyright (C) 2011 Free Software Foundation, Inc.

   Author: Wolfgang Lux <wolfgang.lux@gmail.com>
   Date:   Jan 2011
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

#ifndef _GNUstep_H_GSHelpAttachment
#define _GNUstep_H_GSHelpAttachment

#import <AppKit/NSTextAttachment.h>

@interface GSHelpLinkAttachment : NSTextAttachment
{
  NSString *fileName, *markerName;
}

- (id) initWithFileName: (NSString *)aFileName
	     markerName: (NSString *)aMarkerName;
- (void) dealloc;
- (NSString *)fileName;
- (NSString *)markerName;

@end

@interface GSHelpMarkerAttachment : NSTextAttachment
{
  NSString *markerName;
}

- (id) initWithMarkerName: (NSString *)aMarkerName;
- (void) dealloc;
- (NSString *)markerName;

@end

#endif /* _GNUstep_H_GSHelpAttachment */
