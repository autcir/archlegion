# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-07-28

First tagged release. Automated Arch Linux installation and configuration for
the Lenovo Legion Y520, oriented towards DevOps and development work.

### Added

- `archinstall/` profiles and `scripts/` for a full unattended setup
- NVIDIA Optimus GPU switching, security hardening, container tooling
- Documentation under `docs/`
- CI (`.github/workflows/ci.yml`): shellcheck, `bash -n` parsing,
  executable-bit enforcement, and a private-key scan
- `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, issue and PR
  templates, `.editorconfig`, `.shellcheckrc`, Dependabot

### Fixed

- `scripts/lib/utils.sh`: `package_exists()` combined `&>/dev/null` with a
  second `2>/dev/null`, leaving two redirections competing for stderr
- `config/dotfiles/picom/a.sh` had no shebang

[1.0.0]: https://github.com/ciroautuori/archlegion/releases/tag/v1.0.0
