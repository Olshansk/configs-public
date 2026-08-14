##@ Configuration

.PHONY: profile-use profile-status
profile-use: _check-sync-script ## Preview a profile switch; use APPLY=1 to apply it
	@test -n "$(PROFILE)" || { printf "$(RED)🚨 Pass PROFILE=personal or PROFILE=work$(RESET)\n"; exit 2; }
	@PROFILE="$(PROFILE)" APPLY="$(APPLY)" HOST="$(HOST)" TOOLS="$(TOOLS)" DRY_RUN="$(DRY_RUN)" BACKUP_DIR="$(BACKUP_DIR)" AGENT_SKILLS_DIR="$(AGENT_SKILLS_DIR)" $(SYNC_SCRIPT) profile-use

profile-status: _check-sync-script ## Show the active profile selector and managed configuration status
	@PROFILE="$(PROFILE)" HOST="$(HOST)" TOOLS="$(TOOLS)" DRY_RUN="$(DRY_RUN)" BACKUP_DIR="$(BACKUP_DIR)" AGENT_SKILLS_DIR="$(AGENT_SKILLS_DIR)" $(SYNC_SCRIPT) status

.PHONY: setup
setup: _check-sync-script ## Back up managed targets and install canonical configuration
	@PROFILE="$(PROFILE)" HOST="$(HOST)" TOOLS="$(TOOLS)" DRY_RUN="$(DRY_RUN)" BACKUP_DIR="$(BACKUP_DIR)" AGENT_SKILLS_DIR="$(AGENT_SKILLS_DIR)" $(SYNC_SCRIPT) setup

.PHONY: backup
backup: _check-sync-script ## Back up managed live configuration outside the repository
	@PROFILE="$(PROFILE)" HOST="$(HOST)" TOOLS="$(TOOLS)" DRY_RUN="$(DRY_RUN)" BACKUP_DIR="$(BACKUP_DIR)" AGENT_SKILLS_DIR="$(AGENT_SKILLS_DIR)" $(SYNC_SCRIPT) backup

.PHONY: review
review: _check-sync-script ## Review live drift without changing files
	@PROFILE="$(PROFILE)" HOST="$(HOST)" TOOLS="$(TOOLS)" DRY_RUN="$(DRY_RUN)" BACKUP_DIR="$(BACKUP_DIR)" AGENT_SKILLS_DIR="$(AGENT_SKILLS_DIR)" $(SYNC_SCRIPT) review

.PHONY: snapshot
snapshot: _check-sync-script ## Snapshot selected live files into an external staging directory
	@PROFILE="$(PROFILE)" HOST="$(HOST)" TOOLS="$(TOOLS)" DRY_RUN="$(DRY_RUN)" BACKUP_DIR="$(BACKUP_DIR)" AGENT_SKILLS_DIR="$(AGENT_SKILLS_DIR)" $(SYNC_SCRIPT) snapshot

.PHONY: status
status: _check-sync-script ## Show selected profile and managed configuration status
	@PROFILE="$(PROFILE)" HOST="$(HOST)" TOOLS="$(TOOLS)" DRY_RUN="$(DRY_RUN)" BACKUP_DIR="$(BACKUP_DIR)" AGENT_SKILLS_DIR="$(AGENT_SKILLS_DIR)" $(SYNC_SCRIPT) status

.PHONY: validate
validate: _check-sync-script ## Run shell/configuration checks and scan tracked/unignored files for literal secrets
	@bash -n "$(SYNC_SCRIPT)" "$(CONFIGS_DIR)/config-manifest.sh"
	@"$(CONFIGS_DIR)/scripts/check-secrets.sh"
	@"$(CONFIGS_DIR)/scripts/validate-config.sh"
	@printf "$(GREEN)✅ Configuration validation passed$(RESET)\n"

.PHONY: public-audit
public-audit: ## Audit the public tree and Git history for private data
	@"$(CONFIGS_DIR)/scripts/public-audit.sh"

.PHONY: secrets-check secrets-init secrets-status
secrets-check: ## Scan tracked and unignored configuration for literal secrets
	@"$(CONFIGS_DIR)/scripts/check-secrets.sh"
secrets-init: ## Create the selected profile's off-repo secrets file with mode 600
	@PROFILE="$(PROFILE)" "$(CONFIGS_DIR)/scripts/secrets-profile.sh" init
secrets-status: ## Check the selected profile's secret-file location and permissions
	@PROFILE="$(PROFILE)" "$(CONFIGS_DIR)/scripts/secrets-profile.sh" status

##@ Validation
.PHONY: test
test: _check-sync-script ## Run focused configuration validation tests
	@"$(CONFIGS_DIR)/scripts/test-config-validation.sh"
	@"$(CONFIGS_DIR)/scripts/test-profile-management.sh"
	@"$(CONFIGS_DIR)/scripts/test-profile-secrets.sh"
	@"$(CONFIGS_DIR)/scripts/test-apps.sh"
	@"$(CONFIGS_DIR)/scripts/test-onboard.sh"
	@"$(CONFIGS_DIR)/scripts/test-public-audit.sh"

.PHONY: codex-profile
codex-profile: _check-sync-script ## Install the managed Codex profile without changing local runtime state
	@PROFILE="$(PROFILE)" HOST="$(HOST)" TOOLS="codex-profile" DRY_RUN="$(DRY_RUN)" BACKUP_DIR="$(BACKUP_DIR)" AGENT_SKILLS_DIR="$(AGENT_SKILLS_DIR)" $(SYNC_SCRIPT) setup

##@ Onboarding
.PHONY: onboard onboarding
onboard: _check-sync-script ## Run the guided new-machine setup for the selected profile
	@PROFILE="$(PROFILE)" HOST="$(HOST)" DRY_RUN="$(DRY_RUN)" BACKUP_DIR="$(BACKUP_DIR)" AGENT_SKILLS_DIR="$(AGENT_SKILLS_DIR)" "$(CONFIGS_DIR)/scripts/onboard.sh"
onboarding: onboard

##@ Applications
.PHONY: brew-review apps-review brew-install apps-install brew-snapshot
brew-review: ## Review Homebrew packages and casks for the selected profile
	@PROFILE="$(PROFILE)" BACKUP_DIR="$(BACKUP_DIR)" "$(CONFIGS_DIR)/scripts/brew.sh" review
apps-review: ## Review managed and manual application inventory
	@PROFILE="$(PROFILE)" "$(CONFIGS_DIR)/scripts/apps.sh" review
brew-install: ## Install the selected profile's Homebrew packages and casks
	@PROFILE="$(PROFILE)" BACKUP_DIR="$(BACKUP_DIR)" "$(CONFIGS_DIR)/scripts/brew.sh" install
apps-install: brew-install
brew-snapshot: ## Export installed Homebrew state outside the repository
	@PROFILE="$(PROFILE)" BACKUP_DIR="$(BACKUP_DIR)" "$(CONFIGS_DIR)/scripts/brew.sh" snapshot

##@ History
.PHONY: history-status
history-status: ## Show native zsh, Atuin, and Hishtory state and hotkeys
	@"$(CONFIGS_DIR)/scripts/history-status.sh"

##@ CLI Inventory
.PHONY: cli-discovery cli-review
cli-discovery: ## Extract recent local CLI usage into a local JSON report
	@PROFILE="$(PROFILE)" LIMIT="$(LIMIT)" HISTORY_SOURCE="$(HISTORY_SOURCE)" "$(CONFIGS_DIR)/scripts/cli-discovery.sh"
cli-review: ## Show a ranked CLI add/keep/remove decision table
	@PROFILE="$(PROFILE)" LIMIT="$(LIMIT)" HISTORY_SOURCE="$(HISTORY_SOURCE)" "$(CONFIGS_DIR)/scripts/cli-review.sh"

##@ Startup
.PHONY: startup-review startup-enable startup-disable
startup-review: ## Review profile login items and LaunchAgents without changing macOS state
	@PROFILE="$(PROFILE)" "$(CONFIGS_DIR)/scripts/startup.sh" review
startup-enable: ## Enable the selected profile's declared login items and LaunchAgents
	@PROFILE="$(PROFILE)" "$(CONFIGS_DIR)/scripts/startup.sh" enable
startup-disable: ## Disable one declared startup item; pass NAME=...
	@PROFILE="$(PROFILE)" NAME="$(NAME)" "$(CONFIGS_DIR)/scripts/startup.sh" disable
