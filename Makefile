CONFIGS_DIR := $(CURDIR)

.DEFAULT_GOAL := help

include $(CONFIGS_DIR)/makefiles/common.mk
include $(CONFIGS_DIR)/makefiles/config.mk
include $(CONFIGS_DIR)/makefiles/help.mk
