# Boot and Runtime Flow

This document describes the current kernel runtime flow used in XDV OS bring-up.

## Boot Contract Boundary

1. `xdv-os` stage0 loads `boot.bin`.
2. `xdv-boot` locates and loads `kernel.bin`.
3. `xdv-boot` transfers control to kernel entry.
4. `xdv-kernel` starts runtime path.

`xdv-kernel` assumes loader handoff is complete and begins kernel/runtime
initialization from its entry profile.

## Kernel Entry Profiles

## Dust entry (`kernel.ds`)

- File: `sector/xdv_kernel/src/kernel.ds`
- Primary routine: `kernel_start()`
- High-level steps:
  1. print boot/banner messages,
  2. apply boot contract initialization hooks,
  3. load runtime bridge,
  4. start userspace bootstrap,
  5. enter kernel main loop.

## Bare-metal shell profile (`kernel_runtime_shell.asm`)

- File: `sector/xdv_kernel/src/kernel_runtime_shell.asm`
- Provides:
  - VGA console output path,
  - PS/2 keyboard input (US layout, set-1 mapping),
  - command line buffer parsing,
  - shell command dispatch for xdv-shell, xdv-core, and xdv-xdvfs-utils
    bring-up command sets,
  - runtime status/metrics output used during VM validation.

## Runtime Signals

The kernel/runtime log stream includes:

- loader handoff confirmation,
- kernel initialization banner and build date,
- runtime bridge and userspace bootstrap status,
- shell bridge/dispatcher status when shell path is active.

## Validation

Recommended checks:

```bash
dust check sector/xdv_kernel/src
dust check sector/xdv_memory/src
dust check sector/xdv_cpu/src
dust check ../xdv-dal/src
dust check ../xdv-cds/src
dust check ../xdv-umf/src
dust check ../xdv-hypervisor/src
dust check ../xdv-sdbm/src
```

and integration boot validation through the `xdv-os` build and VM run path.
