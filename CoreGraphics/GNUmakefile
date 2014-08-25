ifeq ($(GNUSTEP_MAKEFILES),)
  GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
  ifeq ($(GNUSTEP_MAKEFILES),)
    $(error You need to set GNUSTEP_MAKEFILES before compiling!)
  endif
endif

include $(GNUSTEP_MAKEFILES)/common.make

LIBRARY_NAME = libCoreGraphics
VERSION=1.0.0

ADDITIONAL_CPPFLAGS += $(shell pkg-config --cflags cairo)
LIBRARIES_DEPEND_UPON += -lcairo
LIBRARIES_DEPEND_UPON += $(shell pkg-config --libs lcms)
LIBRARIES_DEPEND_UPON += -ljpeg -ltiff

$(LIBRARY_NAME)_HEADER_FILES_INSTALL_DIR = CoreGraphics
$(LIBRARY_NAME)_HEADER_FILES = \
        CGAffineTransform.h \
        CGBase.h \
        CGBitmapContext.h \
        CGColor.h \
        CGColorSpace.h \
        CGContext.h \
        CGContext-private.h \
        CGDataConsumer.h \
        CGDataProvider.h \
        CGFont.h \
        CGFont-private.h \
        CGFunction.h \
        CGGeometry.h \
        CGGradient.h \
        CGImage.h \
        CGImageDestination.h \
        CGImageSource.h \
        CGLayer.h \
        CGPath.h \
        CGPattern.h \
        CGPDFArray.h \
        CGPDFContentStream.h \
        CGPDFContext.h \
        CGPDFDictionary.h \
        CGPDFDocument.h \
        CGPDFObject.h \
        CGPDFOperatorTable.h \
        CGPDFPage.h \
        CGPDFScanner.h \
        CGPDFString.h \
        CGPDFStream.h \
        CGPSConverter.h \
        CGShading.h \
        CoreGraphics.h \
        CGEvent.h \
        CGEventType.h \
        CoreGraphics-private.h \
        CairoFontX11-private.h \
        StandardGlyphNames.h \
        CGColorSpace-private.h \
        CGDataProvider-private.h \
        CGImageDestination-private.h \
        CGBitmapContext-private.h \
        CGImageSource-private.h \
        CGColor-private.h \
        CGDataConsumer-private.h \
        CGGradient-private.h \

$(LIBRARY_NAME)_OBJC_FILES = $(wildcard *.m)
$(LIBRARY_NAME)_OBJC_FILES += $(wildcard image/*.m)

include $(GNUSTEP_MAKEFILES)/library.make

