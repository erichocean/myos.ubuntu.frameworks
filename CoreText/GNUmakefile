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

LIBRARY_NAME = libCoreText

VERSION=1.0.0

ADDITIONAL_OBJCFLAGS += -Wall -g -O0 -std=gnu99
ADDITIONAL_CPPFLAGS += $(shell pkg-config --cflags cairo)
ADDITIONAL_CPPFLAGS += $(shell pkg-config --cflags lcms)

ifneq ($(GNUSTEP_TARGET_OS), mingw32)
    ADDITIONAL_CPPFLAGS += $(shell pkg-config --cflags freetype2)
else
    ADDITIONAL_CPPFLAGS += -D__MINGW__
endif

${LIBRARY_NAME}_HEADER_FILES_INSTALL_DIR = CoreText
${LIBRARY_NAME}_HEADER_FILES = \
	CoreText.h \
	CTFont.h \
	CTFontCollection.h \
	CTFontDescriptor.h \
	CTFontManager.h \
	CTFontManagerErrors.h \
	CTFontTraits.h \
	CTFrame.h \
	CTFramesetter.h \
	CTGlyphInfo.h \
	CTLine.h \
	CTParagraphStyle.h \
	CTRun.h \
	CTStringAttributes.h \
	CTTextTab.h \
	CTTypesetter.h \

${LIBRARY_NAME}_OBJC_FILES = \
	CTFontCollection.m \
	CTFontDescriptor.m \
	CTFont.m \
	CTFontTraits.m \
	CTFrame.m \
	CTFramesetter.m \
	CTGlyphInfo.m \
	CTLine.m \
	CTNSFontconfigFontDescriptor.m \
	CTNSFontDescriptor.m \
	CTNSFont.m \
	CTParagraphStyle.m \
	CTRun.m \
	CTStringAttributes.m \
	CTTextTab.m \
	CTTypesetter.m \
	OPSimpleLayoutEngine.m \

include $(GNUSTEP_MAKEFILES)/library.make
