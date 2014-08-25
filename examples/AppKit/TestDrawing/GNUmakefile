ifeq ($(GNUSTEP_MAKEFILES),)
  GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
  ifeq ($(GNUSTEP_MAKEFILES),)
    $(error You need to set GNUSTEP_MAKEFILES before compiling!)
  endif
endif

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = TestDrawing

$(APP_NAME)_OBJC_FILES = $(wildcard *.m)

$(APP_NAME)_MAIN_MODEL_FILE = MainMenu.gorm
$(APP_NAME)_RESOURCE_FILES = MainMenu.gorm

include $(GNUSTEP_MAKEFILES)/application.make

