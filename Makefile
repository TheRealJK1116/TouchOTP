TARGET := iphone:clang:6.1:6.0
ARCHS = armv7
GO_EASY_ON_ME = 1

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = TouchOTP
TouchOTP_FILES = main.m $(wildcard src/*.m) $(wildcard src/aes-gcm/*.c) $(wildcard src/ZXingObjC/*.m) $(wildcard src/ZXingObjC/**/*.m) $(wildcard src/ZXingObjC/**/**/*.m) $(wildcard src/ZXingObjC/**/**/**/*.m) $(wildcard src/ZXingObjC/**/**/**/**/*.m)
TouchOTP_FRAMEWORKS = UIKit CoreGraphics Foundation Security CoreVideo AVFoundation CoreMedia ImageIO CoreImage QuartzCore
TouchOTP_RESOURCE_FILES = icon.png
TouchOTP_CFLAGS = -fobjc-arc -fno-threadsafe-statics -I./src -I./src/aes-gcm $(shell find src/ZXingObjC -type d | awk '{print "-I./" $$0}')

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "su mobile -c uicache"
