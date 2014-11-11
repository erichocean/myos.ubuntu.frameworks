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

LIBRARY_NAME = libCoreAnimation
VERSION=1.0.0

ADDITIONAL_OBJCFLAGS = -DDEBUG
ADDITIONAL_CPPFLAGS += $(shell pkg-config --cflags cairo)

LIBRARIES_DEPEND_UPON += -lcairo -lOpenGLES
LIBRARIES_DEPEND_UPON += $(shell pkg-config --libs lcms)
LIBRARIES_DEPEND_UPON += -ljpeg -ltiff

${LIBRARY_NAME}_HEADER_FILES_INSTALL_DIR = CoreAnimation
${LIBRARY_NAME}_HEADER_FILES = \
        CAAnimation.h \
        CAGradientLayer.h \
        CAReplicatorLayer.h \
        CATiledLayer.h \
        CAValueFunction.h \
        CABase.h \
        CALayer.h \
        CALayerObserver.h \
        CAAction.h \
        CAScrollLayer.h \
        CATransaction.h \
        CARenderer.h \
        CoreAnimation.h \
        CADisplayLink.h \
        CAMediaTiming.h \
        CAShapeLayer.h \
        CATransform3D.h \
        CAEAGLLayer.h \
        CAMediaTimingFunction.h \
        CATextLayer.h \
        CATransformLayer.h \
        CAAnimation-private.h \
        CALayer+CFunctions.h \
        CARenderer-private.h \
        CoreAnimation-private.h \
        CAGradientLayer-private.h \
        CAMediaTimingFunction-private.h \
        CATransaction-private.h \
        CABackingStore.h \

${LIBRARY_NAME}_OBJC_FILES = $(wildcard *.m) 

include $(GNUSTEP_MAKEFILES)/library.make
