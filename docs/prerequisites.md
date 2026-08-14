# Prerequisites

Tools that must be installed manually before running any script in `modules/`. The scripts assume these are already on `PATH` and do not install them for you.

## Checklist

- [ ] **A package manager** for your OS
  - macOS: [Homebrew](https://brew.sh) (`brew`)
  - Linux: your distro's package manager (`apt-get`, `dnf`, `yum`, `pacman`, or `apk`)
  - Windows: [winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/) or [Chocolatey](https://chocolatey.org/) (`choco`)
- [ ] **GitHub CLI** (`gh`) — install via your package manager, e.g. `brew install gh` (macOS) or `sudo apt install gh` (Debian/Ubuntu), then authenticate with `gh auth login`
- [ ] `git`
- [ ] `curl`

## Verify

```bash
command -v brew || command -v apt-get || command -v dnf || command -v pacman || command -v apk
gh --version
git --version
curl --version
```

See `README.md` → Prerequisites for OS-specific install commands for `neovim`, `tmux`, and `git`.
