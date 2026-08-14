# Machine Profiles

Profiles hold configuration that varies by work or personal identity and by host capability.

The profile directories are GitHub-backed templates. The active machine profile is stored locally in the ignored `.local/active-profile` file and must be either `personal` or `work`.

Each profile has `env.sh` for committed non-secret values,
`secrets_template.sh` for blank credential names, and `macos/` for application
configuration. Populated secrets live outside Git at
`~/.config/dotfiles/profiles/<profile>/secrets.sh`; an ignored fallback under
`.local/profiles/<profile>/secrets.sh` is also supported.

Preview a switch with `make PROFILE=work profile-use`. Apply it with `make PROFILE=work APPLY=1 profile-use`; this backs up managed targets, updates live links/copies, and then persists the selector. `make profile-status` shows the selector and live configuration state.

Commands without an explicit `PROFILE` fail when the selector is missing or invalid, preventing an accidental personal/work mix-up.

Host-specific files belong below the matching profile and host directory.

Secrets, histories, caches, logs, sessions, plugin state, and project trust remain outside this tree.
