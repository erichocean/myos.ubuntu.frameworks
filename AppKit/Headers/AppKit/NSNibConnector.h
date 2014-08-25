/* 
   NSNibConnector.h

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <richard@branstorm.co.uk>
   Date: 1999
   
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

#ifndef _GNUstep_H_NSNibConnector
#define _GNUstep_H_NSNibConnector
#import <GNUstepBase/GSVersionMacros.h>

#import <Foundation/NSObject.h>

@class NSString;

@interface NSNibConnector : NSObject <NSCoding>
{
  id		_src;
  id		_dst;
  NSString	*_tag;
}

- (id) destination;
- (void) establishConnection;
- (NSString*) label;
- (void) replaceObject: (id)anObject withObject: (id)anotherObject;
- (id) source;
- (void) setDestination: (id)anObject;
- (void) setLabel: (NSString*)label;
- (void) setSource: (id)anObject;
@end

@interface NSNibControlConnector : NSNibConnector
- (void) establishConnection;
@end

@interface NSNibOutletConnector : NSNibConnector
- (void) establishConnection;
@end

#endif

