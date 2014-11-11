#
# Copyright © 2014 myOS Group.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# Contributor(s):
# Amr Aboelela <amraboelela@gmail.com>
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
