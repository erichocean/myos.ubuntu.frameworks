/** <title>GSThemeOpenSavePanels</title>

   <abstract>Methods for themes using open and save panels.</abstract>

   Copyright (C) 2008 Free Software Foundation, Inc.

   Author: Gregory Casamento <greg.casamento@gmail.com>
   Date: 2010
   
   This file is part of the GNU Objective C User interface library.

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

#import "AppKit/NSOpenPanel.h"
#import "AppKit/NSSavePanel.h"
#import "GNUstepGUI/GSTheme.h"

@implementation GSTheme (OpenSavePanels)
/**
 * This method returns the open panel class needed by the
 * native environment.
 */ 
- (Class) openPanelClass
{
  return [NSOpenPanel class];
}

/**
 * This method returns the open panel class needed by the
 * native environment.
 */ 
- (Class) savePanelClass
{
  return [NSSavePanel class];
}
@end
