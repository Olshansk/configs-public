SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

RESET := \033[0m
BOLD := \033[1m
CYAN := \033[36m
BLUE := \033[34m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m

ifeq ($(NO_COLOR),1)
RESET :=
BOLD :=
CYAN :=
BLUE :=
GREEN :=
YELLOW :=
RED :=
endif

PROFILE ?=
HOST ?= $(shell scutil --get LocalHostName 2>/dev/null || hostname -s)
TOOLS ?= all
DRY_RUN ?= 0
BACKUP_DIR ?=
AGENT_SKILLS_DIR ?= $(HOME)/workspace/agent-skills

PROFILE_LABEL := $(if $(PROFILE),$(PROFILE),selector)

SYNC_SCRIPT := $(CONFIGS_DIR)/scripts/config-sync.sh

.PHONY: _check-sync-script
_check-sync-script:
	@test -x "$(SYNC_SCRIPT)" || { \
		printf "$(RED)🚨 Missing executable: %s$(RESET)\n" "$(SYNC_SCRIPT)"; \
		exit 1; \
	}

.PHONY: _sync
_sync: _check-sync-script
	@PROFILE="$(PROFILE)" HOST="$(HOST)" TOOLS="$(TOOLS)" DRY_RUN="$(DRY_RUN)" BACKUP_DIR="$(BACKUP_DIR)" AGENT_SKILLS_DIR="$(AGENT_SKILLS_DIR)" $(SYNC_SCRIPT)
