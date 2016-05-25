GO_EASY_ON_ME = 1
ARCHS = armv7 arm64
DEBUG = 0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ProactiveSearchEnabler
ProactiveSearchEnabler_FILES = Tweak.xm
ProactiveSearchEnabler_PRIVATE_FRAMEWORKS = Search
ProactiveSearchEnabler_LIBRARIES = MobileGestalt

include $(THEOS_MAKE_PATH)/tweak.mk

