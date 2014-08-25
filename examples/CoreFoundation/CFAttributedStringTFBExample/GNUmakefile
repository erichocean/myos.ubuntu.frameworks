GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = CFAttributedStringTFBExample
ADDITIONAL_TOOL_LIBS = -lCoreFoundation
CFAttributedStringTFBExample_OBJC_FILES = main.m

include $(GNUSTEP_MAKEFILES)/application.make
