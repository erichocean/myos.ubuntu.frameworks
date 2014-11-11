#
# Copyright © 2014 myOS Group.
#
# This file is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This file is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# Contributor(s):
# Amr Aboelela <amraboelela@gmail.com>
#

CFLAGS=-DDEBUG -fblocks

ifeq ($(TARGET),NativeActivity)
    LIB_NAME=NAUIKit
    CFLAGS+=-DNA
    LDLIBS+=-lEGL -lGLESv1_CM -lGLESv1_enc -landroid -lCoreFoundation -lFoundation -lNAIOKit -lNAOpenGLES -lNACoreAnimation -lNACoreGraphics -lNACoreText
else
    LIB_NAME=UIKit
    LDLIBS=-landroid -lCoreFoundation -lFoundation -lIOKit -lOpenGLES -lCoreAnimation -lCoreGraphics -lCoreText
endif

OBJECTS = \
    UIApplication.o \
    UIEvent.o \
    UIResponder.o \
    UITouch.o \
    UIGeometry.o \
    UIGraphics.o \
    UIScreen.o \
    UIImage.o \
    UIPhotosAlbum.o \
    UIColor.o \
    UIView.o \
    UIBackgroundTask.o \
    UIGestureRecognizer.o \
	UIWindow.o \
	UIButton.o \
	UIImageView.o \
	UIScreenMode.o \
	UIControl.o \
	UILabel.o \
	UIFont.o \
	UIViewLayoutManager.o \
	UIControlAction.o \
	UIInputController.o \
	UIAction.o \
	UIPanGestureRecognizer.o \
	UIRotationGestureRecognizer.o \
	UITapGestureRecognizer.o \
	UILongPressGestureRecognizer.o \
	UIPinchGestureRecognizer.o \
	UISwipeGestureRecognizer.o \
	UIViewBlockAnimationDelegate.o \
	UIViewAnimationGroup.o \
	UITextField.o \
	UIStringDrawing.o \
    UIViewController.o \
    UINavigationItem.o \
    UINavigationController.o \
    UISplitViewController.o \
    UINavigationBar.o \
    UIToolbar.o \
    UITabBarController.o \
    UIBarButtonItem.o \
    UIToolbarButton.o \
    UITabBar.o \
    UIBarItem.o \
    UIMLApplication.o \
    UIMAApplication.o \
    NSArray+UIKit.o \
    UIPageControl.o \
    UIScrollView.o \
    UIScroller.o \
    UIScrollViewAnimation.o \
    UIScrollViewAnimationScroll.o \
    UIScrollViewAnimationDeceleration.o \
    UIBezierPath.o \
    UIIconControl.o \
    UIApplicationIcon.o \
    UIActivityIndicatorView.o \

include ${MYOS_PATH}/android/sdk/resources/makefile-shared
