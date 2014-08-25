GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = CFDictionaryTFBExample
ADDITIONAL_TOOL_LIBS = -lCoreFoundation
CFDictionaryTFBExample_OBJC_FILES = main.m

include $(GNUSTEP_MAKEFILES)/application.make
