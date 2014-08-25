
#
#   Copyright (C) 2013. All rights reserved.
#

ifeq ($(GNUSTEP_MAKEFILES),)
  GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
  ifeq ($(GNUSTEP_MAKEFILES),)
    $(error You need to set GNUSTEP_MAKEFILES before compiling!)
  endif
endif

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = RedRectangle
ADDITIONAL_OBJCFLAGS = -fblocks -DDEBUG
ADDITIONAL_OBJC_LIBS = -lgnustep-corebase -lopal -lQuartzCore -lCoreImage
RedRectangle_HEADERS = RRAppDelegate.h RRSolidView.h
RedRectangle_OBJC_FILES = main.m RRAppDelegate.m RRSolidView.m
include $(GNUSTEP_MAKEFILES)/application.make

