#
# Copyright (c) 2013. All rights reserved.
#

ifeq ($(GNUSTEP_MAKEFILES),)
  GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
  ifeq ($(GNUSTEP_MAKEFILES),)
    $(error You need to set GNUSTEP_MAKEFILES before compiling!)
  endif
endif

include $(GNUSTEP_MAKEFILES)/common.make

LIBRARY_NAME = libIOKit
VERSION = 1.0.0

ADDITIONAL_CPPFLAGS += $(shell pkg-config --cflags cairo)

${LIBRARY_NAME}_HEADER_FILES_INSTALL_DIR = IOKit
${LIBRARY_NAME}_HEADER_FILES = IOKit.h IOWindow.h IOEvent.h IOFont.h

${LIBRARY_NAME}_OBJC_FILES = \
	IOWindow.m \
	IOEvent.m \
	IOFont.m \
	opal-x11.m \

include $(GNUSTEP_MAKEFILES)/library.make
