TARGET := iphone:clang:6.1:6.0
ARCHS = armv7
GO_EASY_ON_ME = 1

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = TouchOTP
TouchOTP_FILES = main.m $(wildcard src/*.m)
TouchOTP_FRAMEWORKS = UIKit CoreGraphics Foundation Security
TouchOTP_CFLAGS = -fobjc-arc -I./src

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "su mobile -c uicache"
