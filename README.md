# Portable macOS Configuration

Portable shell configuration, profile-aware onboarding, application inventory,
and reproducible workstation setup for macOS.

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
