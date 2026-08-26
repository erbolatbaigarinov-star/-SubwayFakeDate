ARCHS = arm64
TARGET = iphone:clang:latest:13.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = SubwayFakeDate
SubwayFakeDate_FILES = Tweak.m
SubwayFakeDate_CFLAGS = -fobjc-arc
SubwayFakeDate_FRAMEWORKS = Foundation
SubwayFakeDate_INSTALL_PATH = /usr/lib

include $(THEOS_MAKE_PATH)/library.mk
