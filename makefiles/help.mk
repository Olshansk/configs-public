# Generated `make help`. Keep this include last so sections render in include order.

HELP_TITLE   ?= Workstation Config — Make Targets
HELP_ICON    ?= 🧰
HELP_TAGLINE ?= Profile: PROFILE=$(PROFILE_LABEL) HOST=$(HOST) TOOLS=$(TOOLS)
HELP_WIDTH   ?= 46
HELP_PAD     ?= 24
HELP_VARS    ?=
HELP_SED      = $(if $(HELP_VARS),sed $(foreach v,$(HELP_VARS),-e 's|[$$]($(v))|$($(v))|g'),cat)

##@ ❓ Help

.PHONY: help help-unclassified

help: ## Show categorized help (default)
	@t="$(HELP_TITLE)"; w=$(HELP_WIDTH); p=$$(( w - 6 - $${#t} )); \
		if [ $$p -lt 1 ]; then p=1; fi; \
		bar=$$(printf '═%.0s' $$(seq 1 $$w)); \
		printf "\n$(BOLD)$(CYAN)╔%s╗$(RESET)\n" "$$bar"; \
		printf "$(BOLD)$(CYAN)║$(RESET)  $(BOLD)%s$(RESET)%*s$(HELP_ICON)  $(BOLD)$(CYAN)║$(RESET)\n" "$$t" "$$p" ""; \
		printf "$(BOLD)$(CYAN)╚%s╝$(RESET)\n" "$$bar"
	$(if $(HELP_TAGLINE),@printf "$(DIM)$(HELP_TAGLINE)$(RESET)\n",@true)
	@awk -v pad=$(HELP_PAD) ' \
		FNR == 1 { section = "" } \
		/^##@ / { \
			section = substr($$0, 5); gsub(/[ \t]+$$/, "", section); \
			printf "\n$(BOLD)$(BLUE)═══ %s ═══$(RESET)\n\n", section; next \
		} \
		/^[a-zA-Z0-9_-]+:.*## / && section != "" { \
			name = $$0; sub(/:.*/, "", name); \
			desc = $$0; sub(/^[^:]*:.*## /, "", desc); gsub(/[ \t]+$$/, "", desc); \
			while (match(desc, /`[^`]*`/)) { \
				desc = substr(desc, 1, RSTART - 1) "$(GREEN)" \
					substr(desc, RSTART + 1, RLENGTH - 2) "$(RESET)" \
					substr(desc, RSTART + RLENGTH) \
			} \
			gsub(/\(⚠️[^)]*\)/, "$(YELLOW)&$(RESET)", desc); \
			w = pad - length(name); if (w < 1) w = 1; \
			printf "  $(CYAN)%s$(RESET)%*s%s\n", name, w, "", desc \
		}' $(MAKEFILE_LIST) | $(HELP_SED)
	@printf "\n"

help-unclassified: ## List documented targets with no `##@` section above them
	@printf "\n$(BOLD)$(BLUE)═══ 🔎 Unclassified targets ═══$(RESET)\n\n"
	@awk ' \
		FNR == 1 { section = "" } \
		/^##@ / { section = substr($$0, 5); next } \
		/^[a-zA-Z0-9_-]+:.*## / && section == "" { \
			name = $$0; sub(/:.*/, "", name); found = 1; printf "  $(CYAN)%s$(RESET)\n", name \
		} \
		END { if (!found) printf "  $(DIM)(none — every documented target has a section)$(RESET)\n" } \
		' $(MAKEFILE_LIST)
	@printf "\n"
