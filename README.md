# Portable macOS Configuration

Portable shell configuration, profile-aware onboarding, application inventory,
and reproducible workstation setup for macOS.

## TL;DR

This repository is a safe, review-first foundation for setting up a new Mac;
it is not a complete image of an existing laptop.

```bash
DRY_RUN=1 PROFILE=personal make onboard
```

Review the proposed Homebrew packages, managed links, secrets boundary, history
boundary, and startup items before applying anything. The normal setup installs
the declared baseline, links portable shell/Ghostty configuration, and leaves
sign-ins, editor extensions, native app state, permissions, and unlisted apps
for explicit follow-up.

## What this repository captures

| # | Category | Source of truth | What it includes | What remains outside the repo |
|---:|---|---|---|---|
| 1 | Main apps | [`Brewfile.base`](Brewfile.base), [`Brewfile.personal`](Brewfile.personal), [`Brewfile.work`](Brewfile.work) | Homebrew formulas and casks such as 1Password, Ghostty, iTerm2, Ice, Kitty, VS Code, Claude Code, Codex, and Nightfall | Apps installed outside these manifests, licenses, sign-ins, application databases, and macOS permissions. Examples on the current laptop include Slack, Microsoft Office, Chrome, Docker, Figma, Notion, Todoist, Zoom, Spotify, Alfred, Raycast, Obsidian, and Spectacle. |
| 2 | CLI apps | [`apps/cli-tools.json`](apps/cli-tools.json), plus the Brewfiles | Managed tools such as `git`, `gh`, `jq`, `rg`, `fzf`, `uv`, `pyenv`, `redis-cli`, and `stripe`, with manual tools explicitly marked | Local CLI state, credentials, shell history, project environments, and optional tools not declared in the inventory |
| 3 | Shell and portable configs | [`.zshrc`](.zshrc), [`zshrc.d/`](zshrc.d), [`.bashrc`](.bashrc), [`.profile`](.profile), and [`profiles/`](profiles) | Portable shell behavior, profile environment templates, secret templates, and profile-specific Ghostty configuration | Secret values, histories, caches, logs, sessions, local databases, and machine-specific paths |
| 4 | Terminal and editor configs | [`config-manifest.sh`](config-manifest.sh), [`apps/manual.md`](apps/manual.md) | Ghostty is linked by the manifest; iTerm2 and VS Code are documented for manual restoration | iTerm2 profiles/native state, VS Code settings and extensions, and other editor application state |
| 5 | AI and agent configuration | Separate public [`agent-skills`](https://github.com/olshansk/agent-skills) repository plus the agent links in [`config-manifest.sh`](config-manifest.sh) | Shared agent instructions and skills for personal setup | AI runtime settings, histories, sessions, project trust, plugin state, and account sign-ins |

## Quick start

Clone this repository and the separately public agent-skills repository:

```bash
git clone git@github.com:olshansk/configs-public.git ~/workspace/configs-public
git clone git@github.com:olshansk/agent-skills.git ~/workspace/agent-skills
```

Review the intended profile without making changes:

```bash
cd ~/workspace/configs-public
DRY_RUN=1 PROFILE=personal make onboard
```

Run validation:

```bash
make test
make validate
make public-audit
```

## Boundaries

This repository contains portable declarations and templates. Credentials live
outside Git in profile-scoped files with restricted permissions. Histories,
logs, caches, sessions, application databases, project trust lists, and local
AI runtime state remain machine-local.

The application inventory and onboarding workflow are read-first and opt-in.
They review Homebrew, manual tools, managed configuration, profile secrets,
history boundaries, startup items, and validation before proposing changes.

AI examples are generic reference files. They are not copied into live AI
configuration automatically and contain no personal project paths or account
state.

## Documentation

- [New-machine setup](docs/new-machine.md)
- [Machine profiles](profiles/README.md)
- [Manual applications](apps/manual.md)
