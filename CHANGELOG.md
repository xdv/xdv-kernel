# Changelog - XDV Kernel

All notable changes to the XDV Kernel are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.2] - 2026-02-28

### Changed

- Cut over `xdv_dal`, `xdv_cds`, `xdv_umf`, `xdv_hypervisor`, and `xdv_sdbm`
  from in-repo sectors to standalone dependency projects:
  - `../xdv-dal`
  - `../xdv-cds`
  - `../xdv-umf`
  - `../xdv-hypervisor`
  - `../xdv-sdbm`
- Updated `State.toml` to remove local sector registration for those components
  and consume them via `[workspace.sectors]`.
- Updated kernel docs and validation commands to use standalone split project
  source paths.
- Retired duplicate legacy files under `xdv-kernel/sector/xdv_*` split sectors
  as tombstone placeholders pending filesystem-level directory cleanup.

## [0.2.1] - 2026-02-20

### Added

- Added `docs/` documentation set:
  - `docs/README.md`
  - `docs/boot_runtime_flow.md`
  - `docs/sector_reference.md`

### Changed

- Refreshed `README.md` to align with current repository behavior:
  - clarified kernel runtime entry profiles (`kernel.ds` and `kernel_runtime_shell.asm`),
  - clarified integration contract with `xdv-boot` and `xdv-os`,
  - updated documentation and related-project references.

## [0.2.0] - 2026-02-12 (DPL v0.2)

### Added

- **DPL v0.2 Compliance**: Full v0.2 support

#### Boot Subsystem (xdv_boot)
- Multiboot2 header and boot protocol support
- Early CPU initialization (GDT, IDT setup)
- Paging initialization and management
- Memory map detection and parsing
- Basic hardware detection

#### Memory Management (xdv_memory)
- Physical memory allocator (buddy system)
- Virtual memory manager with page tables
- Page table operations (map, unmap)
- Memory protection (NX, read/write/execute)
- Kernel heap allocation

#### CPU Management (xdv_cpu)
- Global Descriptor Table (GDT) setup
- Interrupt Descriptor Table (IDT) management
- Exception handling (page fault, divide error, etc.)
- Timer management and scheduling interrupts
- CPU-local storage

#### Device Drivers (xdv_drivers)
- VGA text mode display driver
- PS/2 keyboard driver
- Serial port driver (UART)
- AHCI storage driver
- Basic network driver framework

#### Process Management (xdv_process)
- Process control block (PCB) structure
- Round-robin scheduler
- Thread creation and management
- Basic inter-process communication
- System call interface

#### Core Kernel (xdv_kernel)
- Kernel initialization sequence
- Main kernel loop
- Kernel configuration system
- Kernel utilities and helpers

### Changed

- Complete kernel architecture designed
- Sector-based modular structure
- Standardized error handling
- Kernel coding standards established

### Fixed

- Boot protocol compatibility
- Memory management edge cases
- Interrupt handling correctness

## [0.1.0] - 2026-02-12

### Added

- Initial XDV kernel project structure
- Basic documentation and specifications

### Known Issues

- No implementation in v0.1 - requires DPL v0.2 compiler

---

Copyright © 2026 Dust LLC
