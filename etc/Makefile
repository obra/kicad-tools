MAKEFILE_PATH := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))

# By default, we assume the board is the first thing we find 
# in the same directory as the Makefile whose name ends in .pro
# This matches what one would usually find with KiCad

BOARD = $(shell  ls $(MAKEFILE_PATH)/*.pro | xargs -IXXX -n 1 basename XXX .pro | head -n 1)

-include /opt/kicad-tools/etc/rules.mk

dummy:
	.PHONY
