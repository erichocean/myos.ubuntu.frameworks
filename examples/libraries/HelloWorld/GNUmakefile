GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)

include $(GNUSTEP_MAKEFILES)/common.make

LIBRARY_NAME = libHelloWorld
libHelloWorld_HEADER_FILES = HelloWorld.h
libHelloWorld_HEADER_FILES_INSTALL_DIR = HelloWorld
libHelloWorld_OBJC_FILES = HelloWorld.m

include $(GNUSTEP_MAKEFILES)/library.make
