# XDV Kernel

Version: 0.2.x  
Language: Dust Programming Language (DPL)

The XDV kernel is the x64 kernel component for XDV OS. It provides the
K-Domain runtime and defines hardware-gated Q-Domain and Phi-Domain service
surfaces.

## Runtime Paths

The repository currently contains two kernel runtime entry profiles:

- `sector/xdv_kernel/src/kernel.ds`  
  Dust kernel entry (`kernel_start`) and core runtime boot sequence.
- `sector/xdv_kernel/src/kernel_runtime_shell.asm`  
  bare-metal runtime shell profile (US keyboard layout, command buffer,
  dispatcher, and console command execution path used in VM bring-up flows).

## Domain Model

- `K-Domain`: classical x64 execution path (active on supported hardware).
- `Q-Domain`: hardware-gated quantum domain interfaces.
- `Phi-Domain`: hardware-gated phase-native interfaces.

When Q/Phi hardware is not present, domain probes and operations are expected
to report domain-not-available behavior.

## Sectors

The workspace defines 8 in-repo sectors:

- `xdv_boot`
- `xdv_memory`
- `xdv_cpu`
- `xdv_drivers`
- `xdv_kernel`
- `xdv_qdomain`
- `xdv_phidomain`
- `xdv_odt`

Each sector contains `src/*.ds` and sector tests (`*_tests.ds`).

The workspace also consumes 5 standalone split projects through
`[workspace.sectors]` dependencies:

- `../xdv-dal`
- `../xdv-cds`
- `../xdv-umf`
- `../xdv-hypervisor`
- `../xdv-sdbm`

## Build and Validation

Validate all sector source directories:

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

- `xdv-boot` is responsible for loading `kernel.bin` and transferring control.
- `xdv-os` image build composes `boot.bin` + `kernel.bin` into the xdvfs image.
- kernel runtime output should be validated in VirtualBox against the expected
  boot contract chain.

## Documentation

- `docs/README.md`
- `docs/boot_runtime_flow.md`
- `docs/sector_reference.md`
- `spec/XDV-Kernel-v0.2-Specification.md`
- `xdv-kernel_white_paper.md`
- `CHANGELOG.md`

## Related Projects

- [xdv-os](../xdv-os)
- [xdv-boot](../xdv-boot)
- [xdv-runtime](../xdv-runtime)
- [xdv-xdvfs](../xdv-xdvfs)
- [xdv-dal](../xdv-dal)
- [xdv-cds](../xdv-cds)
- [xdv-umf](../xdv-umf)
- [xdv-hypervisor](../xdv-hypervisor)
- [xdv-sdbm](../xdv-sdbm)

## License

Copyright (c) 2026 Dust LLC. See `LICENSE`.
