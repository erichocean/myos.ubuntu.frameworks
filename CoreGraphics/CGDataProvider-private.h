/** <title>CGDataProvider</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen <ewasylishen@gmail.com>
   Date: June, 2010
   Author: BALATON Zoltan <balaton@eik.bme.hu>
   Date: 2006

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   */

#import <Foundation/NSObject.h>
#import "CGDataProvider.h"

/**
 * CGDataProvider abstract base class
 */
@interface CGDataProvider : NSObject
{

}

// Opal internal access - Sequential
- (size_t) getBytes: (void *)buffer count: (size_t)count;
- (off_t) skipForward: (off_t)count;
- (void) rewind;

// Opal internal access - Direct
- (size_t) size;
- (const void *)bytePointer;
- (void)releaseBytePointer: (const void *)pointer;
- (size_t) getBytes: (void *)buffer atPosition: (off_t)position count: (size_t)count;

- (CFDataRef) copyData;
@end

/**
 * CGDataProvider subclass for direct data providers
 */
@interface CGDataProviderDirect : CGDataProvider
{
@public
    size_t size;
    off_t pos;
    void *info;
    CGDataProviderGetBytePointerCallback getBytePointerCallback;
    CGDataProviderReleaseBytePointerCallback releaseBytePointerCallback;
    CGDataProviderGetBytesAtOffsetCallback getBytesAtOffsetCallback;
    CGDataProviderGetBytesAtPositionCallback getBytesAtPositionCallback;
    CGDataProviderReleaseInfoCallback releaseInfoCallback;
}

@end

/**
 * CGDataProvider subclass for sequential data providers
 */
@interface CGDataProviderSequential : CGDataProvider
{
@public
    void *info;
    NSData *directBuffer;
    CGDataProviderGetBytesCallback getBytesCallback;
    CGDataProviderSkipBytesCallback skipBytesCallback;
    CGDataProviderSkipForwardCallback skipForwardCallback;
    CGDataProviderRewindCallback rewindCallback;
    CGDataProviderReleaseInfoCallback releaseInfoCallback;
}

- (NSData *)directBuffer;

@end

/**
 * These functions provide access to the data in a CGDataProvider.
 * Sequential or Direct Access functions can be used regardless of the
 * internal type of the data provider.
 */

/* Sequential Access */

size_t OPDataProviderGetBytes(CGDataProviderRef dp, void *buffer, size_t count);
off_t OPDataProviderSkipForward(CGDataProviderRef dp, off_t count);
void OPDataProviderRewind(CGDataProviderRef dp);

/* Direct Access */

size_t OPDataProviderGetSize(CGDataProviderRef dp);
const void *OPDataProviderGetBytePointer(CGDataProviderRef dp);
size_t OPDataProviderGetBytesAtPosition(CGDataProviderRef dp, void *buffer, off_t position, size_t count);
void OPDataProviderReleaseBytePointer(CGDataProviderRef dp, const void *pointer);
