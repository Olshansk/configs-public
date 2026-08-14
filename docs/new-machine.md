# New Machine Setup <!-- omit in toc -->

This guide covers the complete workstation bootstrap: prerequisites, reproducible
applications, managed configuration, and the manual steps that cannot be safely
automated.

## Table of Contents <!-- omit in toc -->

- [Before Cloning](#before-cloning)
- [Quick Start](#quick-start)
- [What Gets Installed](#what-gets-installed)
- [What Remains Manual](#what-remains-manual)
- [Profiles and Boundaries](#profiles-and-boundaries)
- [History and CLI Discovery](#history-and-cli-discovery)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

## Before Cloning

On a new Mac, install the Apple command-line tools and Homebrew first:

```bash
xcode-select --install
```

Install Homebrew from [brew.sh](https://brew.sh/), then clone:

- This repository at `~/workspace/configs-public`.
- The separately public `olshansk/agent-skills` repository at `~/workspace/agent-skills`.

The second repository owns the shared agent instructions and skills referenced by
the personal configuration.

## Quick Start

From this repository, run the guided setup for the intended profile:

```bash
cd ~/workspace/configs-public
make PROFILE=personal onboard
```

Use `PROFILE=work` on an employer-managed machine. Onboarding reviews the current
state and asks before installing Homebrew packages, applying configuration,
creating a secrets file, enabling startup items, or running validation.

Preview the complete workflow without prompts or changes:

```bash
DRY_RUN=1 PROFILE=personal make onboard
```

If you decline a guided prompt, complete the relevant steps explicitly:

```bash
make PROFILE=personal brew-install
make PROFILE=personal APPLY=1 profile-use
make PROFILE=personal secrets-init
make PROFILE=personal apps-review
make PROFILE=personal validate
```

The explicit commands are a fallback. A successful interactive onboarding run may
already perform the installation and profile application steps.

## What Gets Installed

The merged `Brewfile.base` plus the selected profile Brewfile is the source of
truth for reproducible Homebrew installation.

### Base applications and tools

- Applications: 1Password, Ghostty, iTerm2, Ice, VS Code, Claude Code, Codex,
  and Kitty.
- Shell and search tools: Atuin, `fd`, `fzf`, `gh`, `jq`, `ripgrep`, `scrt`,
  `tree`, `wget`, and the Zsh syntax/highlighting plugins.
- Development and utility tools: `bat`, Bash, `btop`, Ghostscript, `htmlq`,
  `iredis`, Mermaid CLI, `pyenv`, `pytest`, Redis, `render`, and `stripe`.

### Profile-specific applications

- Personal: Nightfall.
- Work: only employer-approved additions declared in `Brewfile.work`.

The desired CLI inventory in [`apps/cli-tools.json`](../apps/cli-tools.json)
must remain consistent with the Brewfiles. Run the read-only review with:

```bash
make PROFILE=personal apps-review
```

Homebrew itself is a bootstrap prerequisite and is not installed by the
Brewfiles.

### Optional ecosystems

The shell configuration contains integrations for tools that are not part of the
default workstation install, including Node/nvm, Go, Rust, Docker Desktop,
Google Cloud and Kubernetes, Supabase, minikube, LM Studio, Hishtory, and
OpenClaw. Install and configure these only when the corresponding workflow is
needed or the selected work profile declares them.

## What Remains Manual

Onboarding reports these items but does not automate them:

- Install manual CLI tools listed in [`apps/cli-tools.json`](../apps/cli-tools.json),
  such as `agentsview`, Python, `uv`, Docker, `cursor-agent`, and `port-kill`.
- Sign in to 1Password, GitHub CLI, Codex, Claude, Gemini, cloud providers, and
  other licensed applications.
- Restore VS Code extensions and configure iTerm2 manually; native application state remains local.
- Enter profile secrets from the correct password-manager vault:
  `~/.config/dotfiles/profiles/<profile>/secrets.sh`.
- Grant Accessibility, Input Monitoring, Screen Recording, and Full Disk Access
  only to trusted applications in System Settings.
- Review and enable declared startup items when appropriate.

See [`apps/manual.md`](../apps/manual.md) for the maintained manual checklist.

## Profiles and Boundaries

Portable, non-secret configuration lives in this repository. Shared declarations
live in base files, while `profiles/personal/` and `profiles/work/` hold explicit
machine-context differences. The active profile selector is local state in
`.local/active-profile` and is ignored by Git.

Secret values live outside the repository at
`~/.config/dotfiles/profiles/<profile>/secrets.sh`. The matching committed
`secrets_template.sh` defines expected variable names without values. Only the
active profile is loaded, and valid secret files must be owned by the current
user with mode `600` or `400`.

The work profile excludes personal AI preferences, agent instructions, memories,
iTerm state, credentials, and history. Keep employer-managed configuration in an
employer-approved source rather than adding it to the personal profile.

Histories, caches, logs, sessions, local CLI reports, project trust databases,
licenses, and application databases stay local. They are not configuration and
must not be copied between work and personal machines by onboarding.

## History and CLI Discovery

Native Zsh history remains the underlying per-machine shell history. Hishtory is
bound to `Ctrl-R` for intentional cross-machine sync; its server and account are
a third-party trust boundary. Atuin is bound to `Ctrl-N` for local search and
analytics and should keep `auto_sync = false`, especially on work machines.

Onboarding never copies native Zsh, Atuin, or Hishtory state. Do not connect a
work history source to a personal sync account unless employer policy explicitly
allows it.

CLI discovery reads local history and writes ignored aggregate reports under
`.local/`. Reports contain command names and counts, not arguments, working
directories, or complete command text. `make cli-review` is decision support
only; inventory and manifest changes remain manual.

## Verification

After setup, inspect the profile and managed links:

```bash
make PROFILE=personal profile-status
```

Review applications and run the complete repository checks:

```bash
make PROFILE=personal apps-review
make PROFILE=personal validate
```

The final state should have no unresolved managed tools, a valid profile secrets
file, clean managed links/copies, and only intentional manual follow-up items.

## Troubleshooting

List current commands:

```bash
make help
```

Re-run onboarding read-only for one profile:

```bash
DRY_RUN=1 PROFILE=work make onboard
```

Review only Homebrew packages and casks:

```bash
make PROFILE=personal brew-review
```

If Homebrew is missing, install it from [brew.sh](https://brew.sh/) and rerun
onboarding. If a manual tool is missing, install it according to its approved
source and rerun `make PROFILE=personal apps-review`.
