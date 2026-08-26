ARCHS = arm64
TARGET = iphone:clang:latest:13.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SubwayFakeDate
SubwayFakeDate_FILES = Tweak.xm
SubwayFakeDate_CFLAGS = -fobjc-arc
SubwayFakeDate_FRAMEWORKS = Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
