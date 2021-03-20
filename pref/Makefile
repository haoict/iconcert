ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = ICCPref
ICCPref_FILES = $(wildcard *.m)
ICCPref_INSTALL_PATH = /Library/PreferenceBundles
ICCPref_PRIVATE_FRAMEWORKS = Preferences
ICCPref_EXTRA_FRAMEWORKS = libhdev
ICCPref_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/ICCPref.plist$(ECHO_END)
