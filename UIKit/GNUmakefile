#
#  Copyright (C) 2012. All rights reserved.
#
#

ifeq ($(GNUSTEP_MAKEFILES),)
  GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
  ifeq ($(GNUSTEP_MAKEFILES),)
    $(error You need to set GNUSTEP_MAKEFILES before compiling!)
  endif
endif

include $(GNUSTEP_MAKEFILES)/common.make

LIBRARY_NAME = libUIKit
VERSION=1.0.0

ADDITIONAL_CPPFLAGS += $(shell pkg-config --cflags cairo)
ADDITIONAL_OBJCFLAGS += -fblocks
LIBRARIES_DEPEND_UPON += -lcairo  -lIOKit -lCoreText -lCoreFoundation -lCoreAnimation

${LIBRARY_NAME}_HEADER_FILES_INSTALL_DIR = UIKit
${LIBRARY_NAME}_HEADER_FILES = \
        UIView.h \
	UIImage.h \
	UIWindow.h \
	UIKit.h \
	UIScreen.h \
	UIGeometry.h \
	UIGraphics.h \
	UIEvent.h \
	UIResponder.h \
	UIColor.h \
	UITouch.h \
	UIApplication.h \
	UIInterface.h \
	UIImageView.h \
	UIScrollView.h \
	UITableView.h \
	UITableViewCell.h \
	UIFont.h \
	UILabel.h \
	UIStringDrawing.h \
	UIDevice.h \
	UIAccessibility.h \
	UIAccessibilityElement.h \
	UIControl.h \
	UIButton.h \
	UIBezierPath.h \
	UIViewController.h \
	UIScreenMode.h \
	UIActionSheet.h \
	UIAlertView.h \
	UIButton.h \
	UIBezierPath.h \
	UIScreenMode.h \
	UIActionSheet.h \
	UIAlertView.h \
	UITextField.h \
	UINavigationItem.h \
	UINavigationController.h \
	UIBarItem.h \
	UIBarButtonItem.h \
	UIPasteboard.h \
	UITextInputTraits.h \
	UIWebView.h \
	UIToolbar.h \
	UITabBar.h \
	UITabBarItem.h \
	UISegmentedControl.h \
	UIActivityIndicatorView.h \
	UIPopoverController.h \
	UINavigationBar.h \
	UITextView.h \
	UIDataDetectors.h \
	UITableViewController.h \
	UISearchBar.h \
	UISearchDisplayController.h \
	UIImagePickerController.h \
	UINibLoading.h \
	UIGestureRecognizer.h \
	UITapGestureRecognizer.h \
	UILongPressGestureRecognizer.h \
	UISplitViewController.h \
	UITabBarController.h \
	UISwitch.h \
	UISlider.h \
	UIAcceleration.h \
	UIAccelerometer.h \
	UIMenuController.h \
	UIMenuItem.h \
	UIPageControl.h \
	UIProgressView.h \
	UIPickerView.h \
	UIPanGestureRecognizer.h \
	UIPinchGestureRecognizer.h \
	UIRotationGestureRecognizer.h \
	UISwipeGestureRecognizer.h \
	UIGestureRecognizerSubclass.h \
	UIDatePicker.h \
	UIPhotosAlbum.h \
	UIControlAction.h \
	UIInputController.h \
	UIBackgroundTask.h \
	UIAction.h \

${LIBRARY_NAME}_OBJC_FILES = \
	UIView.m \
	UIImage.m \
	UIWindow.m \
	UIButton.m \
	UIScreen.m \
	UIImageView.m \
	UIColor.m \
	UIGraphics.m \
	UIGeometry.m \
	UIScreenMode.m \
	UIControl.m \
	UIApplication.m \
	UIEvent.m \
	UILabel.m \
	UITouch.m \
	UIResponder.m \
	UIFont.m \
	UIViewLayoutManager.m \
	UIPhotosAlbum.m \
	UIControlAction.m \
	UIInputController.m \
	UIBackgroundTask.m \
	UIAction.m \
	UIGestureRecognizer.m \
	UIPanGestureRecognizer.m \
	UIRotationGestureRecognizer.m \
	UITapGestureRecognizer.m \
	UILongPressGestureRecognizer.m \
	UIPinchGestureRecognizer.m \
	UISwipeGestureRecognizer.m \
	UIViewBlockAnimationDelegate.m \
	UIViewAnimationGroup.m \
	UITextField.m \
	UIStringDrawing.m \
	#UITextView.m \
	#UIScrollView.m \

include $(GNUSTEP_MAKEFILES)/library.make

