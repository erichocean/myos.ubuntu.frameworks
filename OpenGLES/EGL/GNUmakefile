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

LIBRARY_NAME = libOpenGLES
VERSION = 1.0.0

ADDITIONAL_CPPFLAGS += $(shell pkg-config --cflags cairo)
LIBRARIES_DEPEND_UPON += -lGL -lEGL -lIOKit

${LIBRARY_NAME}_HEADER_FILES_INSTALL_DIR = OpenGLES
${LIBRARY_NAME}_HEADER_FILES = EAGL.h EAGLDrawable.h EAGLTexture.h

${LIBRARY_NAME}_OBJC_FILES = \
	EAGL.m \
	EAGLDrawable.m \
	EAGLTexture.m \

include $(GNUSTEP_MAKEFILES)/library.make
