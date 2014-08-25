/* main.m: Main Body of Calculator.app

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Nicola Pero <n.pero@mi.flashnet.it>
   Date: 1999
   
   This file is part of GNUstep.
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA. */
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "CalcBrain.h"
#include "CalcFace.h"

int main (void)
{ 
  CalcBrain *brain;
  CalcFace *face;
  NSAutoreleasePool *pool;
  NSApplication *app;
  NSMenu *mainMenu;
  NSMenu *menu;
  NSMenuItem *menuItem;

  pool = [NSAutoreleasePool new];
  app = [NSApplication sharedApplication];
  [app setApplicationIconImage: [NSImage imageNamed: 
					   @"Calculator.app.tiff"]];
  mainMenu = AUTORELEASE ([NSMenu new]);
  // Info
  [mainMenu addItemWithTitle: @"Info..." 
	    action: @selector (orderFrontStandardInfoPanel:) 
	    keyEquivalent: @""];
  // Edit SubMenu
  menuItem = [mainMenu addItemWithTitle: @"Edit" 	
		       action: NULL 
		       keyEquivalent: @""];
  menu = AUTORELEASE ([NSMenu new]);
  [mainMenu setSubmenu: menu forItem: menuItem];
  /*
  [menu addItemWithTitle: @"Cut" 
	action: @selector (cut:) 
	keyEquivalent: @"x"];
  */
  [menu addItemWithTitle: @"Copy" 
	action: @selector (copy:) 
	keyEquivalent: @"c"];
  /* 
  [menu addItemWithTitle: @"Paste" 
	action: @selector (paste:) 
	keyEquivalent: @"v"];
  */
  [menu addItemWithTitle: @"SelectAll" 
	action: @selector (selectAll:) 
	keyEquivalent: @"a"];

  [mainMenu addItemWithTitle: @"Hide" 
	action: @selector (hide:) 
	keyEquivalent: @"h"];  
  [mainMenu addItemWithTitle: @"Quit" 
	    action: @selector (terminate:)
	    keyEquivalent: @"q"];	
  
  [app setMainMenu: mainMenu];
  
  brain = [CalcBrain new];
  face = [CalcFace new]; 
  [brain setFace: face];
  [face setBrain: brain];
  [app setDelegate: face];
  
  [app run];
  return 0;
}

