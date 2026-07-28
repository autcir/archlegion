## What this changes

<!-- One or two sentences. Why, not just what. -->

## Hardware tested on

<!-- Model, CPU, GPU, kernel. If you did not apply this to a real machine, say
     so plainly — that is useful to a reviewer, not a disqualifier. -->

- Model:
- Kernel:
- Applied and verified on real hardware: yes / no

## Checks

- [ ] `bash -n` passes on every script I touched
- [ ] `shellcheck -S warning` is clean
- [ ] New scripts are executable (`chmod +x`)
- [ ] Scripts are idempotent — running twice is safe
- [ ] No secrets, keys, or `.env` files committed
- [ ] Docs updated if behaviour or file layout changed

## Risk to the reader's machine

<!-- Does this touch undervolt, fan control, firmware, kernel modules, or boot?
     If a user runs this and it goes wrong, what happens, and how do they
     recover? Write "none" if it is documentation only. -->
