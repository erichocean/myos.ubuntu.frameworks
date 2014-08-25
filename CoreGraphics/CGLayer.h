/** <title>CGLayer</title>
 
 <abstract>C Interface to graphics drawing library</abstract>
 
 Copyright <copy>(C) 2009 Free Software Foundation, Inc.</copy>

 Author: Eric Wasylishen
 Date: Dec 2009
  
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

/* Data Types */

@class CGLayer;
typedef CGLayer* CGLayerRef;

#import "CGBase.h"
#import "CGContext.h"

/* Functions */

CGLayerRef CGLayerCreateWithContext(
  CGContextRef referenceCtxt,
  CGSize size,
  CFDictionaryRef auxInfo
);

CGLayerRef CGLayerRetain(CGLayerRef layer);

void CGLayerRelease(CGLayerRef layer);

CGSize CGLayerGetSize(CGLayerRef layer);

CGContextRef CGLayerGetContext(CGLayerRef layer);

void CGContextDrawLayerInRect(
  CGContextRef destCtxt,
  CGRect rect,
  CGLayerRef layer
);

void CGContextDrawLayerAtPoint(
  CGContextRef destCtxt,
  CGPoint point,
  CGLayerRef layer
);

CFTypeID CGLayerGetTypeID();
