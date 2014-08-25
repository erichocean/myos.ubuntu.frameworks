
#
#   Copyright (C) 2012. All rights reserved.
#

ifeq ($(GNUSTEP_MAKEFILES),)
  GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
  ifeq ($(GNUSTEP_MAKEFILES),)
    $(error You need to set GNUSTEP_MAKEFILES before compiling!)
  endif
endif

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = BigApple
ADDITIONAL_OBJCFLAGS = -fblocks -DDEBUG
#ADDITIONAL_LIB_DIRS = -L/usr/local/lib
ADDITIONAL_OBJC_LIBS = -lUIKit -lCoreGraphics
BigApple_HEADERS = BigAppleDelegate.h
BigApple_OBJC_FILES = main.m BigAppleDelegate.m
#BigApple_RESOURCE_FILES = 
#BigApple_OBJC_PRECOMPILED_HEADERS = BigApple_Prefix.pch
BigApple_PCH_FILE = BigApple_Prefix.pch
#BigApple_MAIN_MODEL_FILE = MainMenu.xib
include $(GNUSTEP_MAKEFILES)/application.make

