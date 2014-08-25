
ifeq ($(GNUSTEP_MAKEFILES),)
  GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
  ifeq ($(GNUSTEP_MAKEFILES),)
    $(error You need to set GNUSTEP_MAKEFILES before compiling!)
  endif
endif

include $(GNUSTEP_MAKEFILES)/common.make

LIBRARY_NAME = libCoreFoundation
VERSION=1.0.0
${LIBRARY_NAME}_LIBRARIES_DEPEND_UPON += `icu-config --ldflags-libsonly`
#LIBRARIES_DEPEND_UPON += lprocps 
${LIBRARY_NAME}_NEEDS_GUI = NO
ADDITIONAL_CFLAGS = -DBUILDING_SELF -DMAC_OS_X_VERSION_MAX_ALLOWED=100700
ADDITIONAL_CXXFLAGS = -DBUILDING_SELF -DMAC_OS_X_VERSION_MAX_ALLOWED=100700
ADDITIONAL_OBJCFLAGS = -DBUILDING_SELF -DMAC_OS_X_VERSION_MAX_ALLOWED=100700


ifeq ($(GNUSTEP_TARGET_OS), mingw32)
  ADDITIONAL_LDFLAGS = -L/mingw/bin
endif

${LIBRARY_NAME}_HEADER_FILES_INSTALL_DIR = CoreFoundation
${LIBRARY_NAME}_HEADER_FILES = \
	CoreFoundation.h \
	CFArray.h \
	CFAttributedString.h \
	CFBag.h \
	CFBase.h \
	CFBinaryHeap.h \
	CFBitVector.h \
	CFBundle.h \
	CFByteOrder.h \
	CFCalendar.h \
	CFCharacterSet.h \
	CFData.h \
	CFDate.h \
	CFDateFormatter.h \
	CFDictionary.h \
	CFError.h \
	CFLocale.h \
	CFNumber.h \
	CFNumberFormatter.h \
	CFRunLoop.h \
	CFRuntime.h \
	CFSet.h \
	CFSocket.h \
	CFString.h \
	CFStringEncodingExt.h \
	CFTimeZone.h \
	CFTree.h \
	CFURL.h \
	CFURLAccess.h \
	CFUUID.h \
	CFXMLNode.h \
	CFXMLParser.h \
#	CFAttributedString.h \

${LIBRARY_NAME}_OBJC_FILES = \
	CFBundle.m \

${LIBRARY_NAME}_C_FILES = \
	CFArray.c \
	CFAttributedString.c \
	CFBag.c \
	CFBase.c \
	CFBinaryHeap.c \
	CFBitVector.c \
	CFCalendar.c \
	CFCharacterSet.c \
	CFData.c \
	CFDate.c \
	CFDateFormatter.c \
	CFDictionary.c \
	CFError.c \
	CFLocale.c \
	CFNumber.c \
	CFNumberFormatter.c \
	CFRuntime.c \
	CFRunLoop.c \
	CFSet.c \
	CFSocket.c \
	CFString.c \
	CFStringEncoding.c \
	CFStringFormat.c \
	CFStringUtilities.c \
	CFTimeZone.c \
	CFTree.c \
	CFURL.c \
	CFURLAccess.c \
	CFUUID.c \
	CFXMLNode.c \
	CFXMLParser.c \
	GSHashTable.c \
#	CFAttributedString.c \

include $(GNUSTEP_MAKEFILES)/library.make
