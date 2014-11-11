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

LIB_NAME=CoreText
CFLAGS=-DDEBUG
LDLIBS= -lCoreFoundation -lFoundation

ifeq ($(TARGET),NativeActivity)
    LIB_NAME=NACoreText
    CFLAGS+=-DNA
    LDLIBS+=-lNACoreGraphics
else
    LIB_NAME=CoreText
    LDLIBS+=-lCoreGraphics
endif

OBJECTS = \
	CTFontCollection.o \
	CTFontDescriptor.o \
	CTFont.o \
	CTFontTraits.o \
	CTFrame.o \
	CTFramesetter.o \
	CTGlyphInfo.o \
	CTLine.o \
	CTNSFontconfigFontDescriptor.o \
	CTNSFontDescriptor.o \
	CTNSFont.o \
	CTParagraphStyle.o \
	CTRun.o \
	CTStringAttributes.o \
	CTTextTab.o \
	CTTypesetter.o \
	OPSimpleLayoutEngine.o \

include ${MYOS_PATH}/android/sdk/resources/makefile-shared
