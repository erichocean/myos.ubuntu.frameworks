GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)

include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = HelloWorldTest
HelloWorldTest_OBJC_FILES = main.m

include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
