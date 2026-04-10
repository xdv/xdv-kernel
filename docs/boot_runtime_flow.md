# Boot and Runtime Flow

This document describes the current kernel runtime flow used in XDV OS bring-up
with explicit contract assertions.

## Boot Contract Boundary

1. `xdv-os` stage0 loads `boot.bin`.
2. `xdv-boot` locates and loads `kernel.bin`.
3. `xdv-boot` transfers control to kernel entry.
4. `xdv-kernel` starts runtime path.

`xdv-kernel` treats loader handoff as complete and validates contracts before
runtime activation.

## Kernel Entry Profiles

## Dust entry (`kernel.ds`)

- File: `sector/xdv_kernel/src/kernel.ds`
- Primary routine: `kernel_start()`
- Assertion order:
  1. boot contract status/version assertion,
  2. split dependency interface-version assertions,
  3. runtime bridge version assertion,
  4. runtime init/start assertions.
- Runtime order:
  1. kernel init banner,
  2. runtime bridge load,
  3. userspace start,
  4. main loop entry.

## Bare-metal shell profile (`kernel_runtime_shell.asm`)

- File: `sector/xdv_kernel/src/kernel_runtime_shell.asm`
- Provides:
  - VGA console output path,
  - PS/2 keyboard input (US layout, set-1 mapping),
  - command line buffer parsing,
  - shell command dispatch for xdv-shell, xdv-runtime-utils, and xdv-xdvfs-utils
    bring-up command sets,
  - runtime status/metrics output used during VM validation.

## Split Dependency Interface Assertions

`kernel.ds` asserts version triplets for:

- `xdv_dal_interface_version_*`
- `xdv_cds_interface_version_*`
- `xdv_umf_interface_version_*`
- `xdv_hypervisor_interface_version_*`
- `xdv_sdbm_interface_version_*`

Expected interface triplet in this milestone: `0.1.0`.

## Runtime Signals

Kernel/runtime log stream includes:

- boot contract assertion results,
- split dependency interface assertion results,
- runtime bridge assertion result,
- runtime bridge/userspace startup status,
- kernel main-loop entry.

## Validation

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

For integrated boot validation, run the `xdv-os` image build and VM profile.