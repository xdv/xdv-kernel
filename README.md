# XDV Kernel

Version: 0.2.x  
Language: Dust Programming Language (DPL)

`xdv-kernel` is the x64 kernel component for XDV OS and aligns to
XDV-010 (kernel architecture) and XDV-080 (reference implementation) goals.

## Scope

- Keep **core sectors only** inside `xdv-kernel/sector`.
- Consume split dependencies (`xdv-dal`, `xdv-cds`, `xdv-umf`,
  `xdv-hypervisor`, `xdv-sdbm`) via stable versioned interfaces.
- Stabilize kernel boot/runtime entry contracts with explicit assertions.

## Runtime Paths

The repository contains two kernel runtime entry profiles:

- `sector/xdv_kernel/src/kernel.ds`  
  Dust kernel entry (`kernel_start`) and contract assertions.
- `sector/xdv_kernel/src/kernel_runtime_shell.asm`  
  bare-metal runtime shell profile (US keyboard layout, command buffer,
  dispatcher, and console command execution path used in VM bring-up flows).

## Core Sectors

`xdv-kernel/sector` contains 8 core sectors:

- `xdv_boot`
- `xdv_memory`
- `xdv_cpu`
- `xdv_drivers`
- `xdv_kernel`
- `xdv_qdomain`
- `xdv_phidomain`
- `xdv_odt`

No split dependency implementation sectors are retained in-repo.

## Split Dependencies (Versioned Interfaces)

Consumed through `State.toml [workspace.sectors]`:

- `../xdv-dal` (`0.1.0`)
- `../xdv-cds` (`0.1.0`)
- `../xdv-umf` (`0.1.0`)
- `../xdv-hypervisor` (`0.1.0`)
- `../xdv-sdbm` (`0.1.0`)

`kernel.ds` asserts interface triplets for all split dependencies during boot.

## Kernel Entry Contract Assertions

`sector/xdv_kernel/src/kernel.ds` now asserts:

1. `xdv_os_boot_contract()` status and version.
2. split dependency interface versions (`0.1.0`).
3. `runtime_bridge_version()` compatibility.
4. runtime init/start success before main-loop entry.

## Build and Validation

```bash
dust check sector/xdv_boot/src
dust check sector/xdv_memory/src
dust check sector/xdv_cpu/src
dust check sector/xdv_drivers/src
dust check sector/xdv_kernel/src
dust check sector/xdv_qdomain/src
dust check sector/xdv_phidomain/src
dust check sector/xdv_odt/src
dust check ../xdv-dal/src
dust check ../xdv-cds/src
dust check ../xdv-umf/src
dust check ../xdv-hypervisor/src
dust check ../xdv-sdbm/src
```

## Integration Notes

- `xdv-boot` loads `kernel.bin` and transfers control.
- `xdv-os` composes `boot.bin + kernel.bin + xdvfs` image artifacts.
- kernel assertions are intended to fail-fast on contract/interface drift.

## Documentation

- `docs/README.md`
- `docs/boot_runtime_flow.md`
- `docs/sector_reference.md`
- `spec/XDV-Kernel-v0.2-Specification.md`
- `xdv-kernel_white_paper.md`
- `CHANGELOG.md`