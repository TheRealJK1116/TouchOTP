TARGET := iphone:clang:6.1:6.0
ARCHS = armv7

ZDIRS = $(shell find src/ZXingObjC -type d | awk '{print "-I./" $$0}')

all:
	@echo $(ZDIRS)
