# Manual Applications

Homebrew manifests cover reproducible packages and casks. Some tools and
application state still need manual installation, licensing, sign-in, or macOS
privacy permissions.

The desired CLI inventory lives in cli-tools.json. Discovery may suggest a
manual CLI, but it never installs or removes anything automatically.

## Manual CLI tools

These tools are intentionally report-only. Install them from an approved source,
then rerun `make PROFILE=<profile> apps-review`:

- `agentsview` at `~/.local/bin/agentsview`.
- Python 3 at `/usr/local/bin/python3`.
- `uv`, `uvx`, `pip`, and `pip3` under `~/.local/bin/`.
- Docker, usually supplied by Docker Desktop.
- `cursor-agent` and `port-kill` under `~/.local/bin/`.

## Application state and permissions

- **Spectacle:** no current Homebrew cask was found on this machine. Install it
  manually if required, or evaluate a maintained replacement such as Rectangle.
- **1Password:** sign in after installation; do not put vault data in this repo.
- **AI and cloud tools:** sign in to GitHub CLI, Codex, Claude, Gemini, and any
  cloud provider required by the selected workflow.
- **VS Code:** restore extensions and settings separately; application state
  remains local to the machine.
- **iTerm2:** configure profiles from iTerm2's UI if desired. Native application
  state is reviewed, not copied into this repository or overwritten automatically.
- **Secrets:** create the selected profile's secrets file with
  `make PROFILE=<profile> secrets-init`, then enter values from the correct
  password-manager vault. Never copy values between profiles.
- **macOS permissions:** Accessibility, Input Monitoring, Screen Recording, and
  Full Disk Access are granted manually in System Settings.
