# Contributing to archlegion

Thanks for helping improve archlegion.

## Before You Start

This repo targets a **specific machine**: the Lenovo Legion Y520 (i7-7700HQ +
GTX 1050 Ti, NVIDIA Optimus) on Arch Linux, set up for DevOps and development
work.

Contributions that add support for other models are welcome, but keep them
additive — do not change the documented defaults for the reference hardware.
Optimus/GPU-switching behaviour in particular is hardware-specific, and a
configuration that works on one chipset can leave another without a display.

## Ground Rules for Scripts

Almost everything here runs as root. Accordingly:

- Start every script with `#!/usr/bin/env bash` and `set -euo pipefail`.
- Quote every expansion. `"$var"`, not `$var`.
- Make scripts executable (`chmod +x`) — CI enforces this.
- Be idempotent. Running a script twice should be safe and produce the same
  result.
- Never `curl | sh` from an unpinned source.
- Back up any file you overwrite (the existing scripts use `.bak-loq`).
- Prefer failing loudly over doing something surprising to someone's machine.

## Testing Your Change

CI runs four checks; all of them work locally.

```bash
# Syntax — must parse
git ls-files '*.sh' | while read -r f; do bash -n "$f" || echo "FAIL $f"; done

# Lint — CI gates at severity `warning`
shellcheck -S warning $(git ls-files '*.sh')

# Executable bits
git ls-files '*.sh' | while read -r f; do [ -x "$f" ] || echo "NOT EXEC $f"; done
```

Beyond that, state in your PR **what you actually ran and on what hardware**. A
config change that was never applied to a real machine should say so — that is
useful information, not a disqualifier.

## Secrets

Never commit credentials, keys, or `.env` files. Templates belong in
`*.example` files, which `.gitignore` deliberately preserves. See
[SECURITY.md](SECURITY.md) and [docs/](docs/).

## Commits and PRs

- Use [Conventional Commits](https://www.conventionalcommits.org/): `feat:`,
  `fix:`, `docs:`, `chore:`.
- One logical change per PR.
- Explain the *why* in the description, and note any risk to the reader's
  hardware.
