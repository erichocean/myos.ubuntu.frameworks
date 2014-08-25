
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

APP_NAME = Layers
ADDITIONAL_OBJCFLAGS = -fblocks -DDEBUG
ADDITIONAL_OBJC_LIBS = -lCoreFoundation -lUIKit -lCoreGraphics -lCoreAnimation

${APP_NAME}_HEADERS = AppDelegate.h Layers.h BlueView.h SmileyFaceView.h
${APP_NAME}_OBJC_FILES = main.m AppDelegate.m Layers.m BlueView.m SmileyFaceView.m

include $(GNUSTEP_MAKEFILES)/application.make

