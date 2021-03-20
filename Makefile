ARCHS = arm64 arm64e
TARGET = iphone:clang:13.6:13.0
INSTALL_TARGET_PROCESSES = SpringBoard

PREFIX = "$(THEOS)/toolchain/XcodeDefault-11.5.xctoolchain/usr/bin/"

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = iconcert
iconcert_FILES = $(wildcard *.xm *.m)
iconcert_EXTRA_FRAMEWORKS = libhdev
iconcert_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += pref

include $(THEOS_MAKE_PATH)/aggregate.mk

clean::
	rm -rf .theos packages
