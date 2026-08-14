# Public configuration repository

This repository contains portable configuration and onboarding logic only.

- Keep credentials in ignored, profile-scoped files.
- Never add shell history, logs, sessions, caches, project trust lists, or
  machine-specific application state.
- Run `make test`, `make validate`, and `make public-audit` before publishing.
- Agent instructions and skills are owned by the public `olshansk/agent-skills`
  repository and are linked only when that repository is present locally.
