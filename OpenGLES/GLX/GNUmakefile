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

LIBRARY_NAME = libOpenGLES
VERSION = 1.0.0

ADDITIONAL_CPPFLAGS += $(shell pkg-config --cflags cairo)
#LIBRARIES_DEPEND_UPON += -lGL -lEGL -lGLU -lIOKit
LIBRARIES_DEPEND_UPON += -lGL -lIOKit

${LIBRARY_NAME}_HEADER_FILES_INSTALL_DIR = OpenGLES
${LIBRARY_NAME}_HEADER_FILES = EAGL.h EAGLDrawable.h EAGLTexture.h

${LIBRARY_NAME}_OBJC_FILES = \
	EAGL.m \
	EAGLDrawable.m \
	EAGLTexture.m \

include $(GNUSTEP_MAKEFILES)/library.make
