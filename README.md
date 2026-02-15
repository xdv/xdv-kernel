# XDV Kernel v0.2

A Cross-Domain Virtualizer operating system kernel for x86-64, written entirely in the Dust Programming Language (DPL).

## Overview

XDV v0.2 is a multi-domain operating system kernel that supports three computational domains:

- **K-Domain (Classical)**: Traditional von Neumann computing on x64 (FULL SUPPORT)
- **Q-Domain (Quantum)**: Hardware-gated quantum services (returns ERR_DOMAIN_NOT_AVAILABLE when unavailable)
- **Φ-Domain (Phase-Native)**: Hardware-gated phase services (returns ERR_DOMAIN_NOT_AVAILABLE when unavailable)

The kernel runs on classical x86-64 hardware with full K-Domain functionality.

## Dependencies

- **dustlib**: Core types (Result, Option, Str)
- **dustlib_k**: Memory allocation, threading, I/O operations

## Kernel Sectors

The kernel is organized into 13 sectors:

| Sector | Purpose | Status |
|--------|---------|--------|
| `xdv_boot` | Boot and early initialization | ✅ |
| `xdv_memory` | Physical and virtual memory management | ✅ |
| `xdv_cpu` | CPU management, interrupts, exceptions | ✅ |
| `xdv_drivers` | Device drivers (VGA, keyboard, storage, network) | ✅ |
| `xdv_kernel` | Core kernel functionality and main loop | ✅ |
| `xdv_dal` | Domain Abstraction Layer - unified domain interfaces | ✅ |
| `xdv_qdomain` | Quantum domain subsystem (hardware-gated) | ✅ |
| `xdv_phidomain` | Phase-Native domain subsystem (hardware-gated) | ✅ |
| `xdv_cds` | Cross-Domain Scheduler | ✅ |
| `xdv_umf` | Unified Memory Fabric | ✅ |
| `xdv_hypervisor` | Domain Hypervisor | ✅ |
| `xdv_sdbm` | Secure Domain Boundary Manager | ✅ |
| `xdv_odt` | Observability & Deterministic Trace Layer | ✅ |

## Directory Structure

```
xdv-kernel/
├── State.toml
├── README.md
├── LICENSE
├── sector/
│   ├── xdv_boot/           # Boot sector
│   │   ├── boot.ds
│   │   └── boot_tests.ds
│   ├── xdv_memory/        # Memory management
│   │   ├── memory.ds
│   │   └── memory_tests.ds
│   ├── xdv_cpu/          # CPU management
│   │   ├── cpu.ds
│   │   └── cpu_tests.ds
│   ├── xdv_drivers/     # Device drivers
│   │   ├── drivers.ds
│   │   └── drivers_tests.ds
│   ├── xdv_kernel/      # Core kernel
│   │   ├── kernel.ds
│   │   └── kernel_tests.ds
│   ├── xdv_dal/         # Domain Abstraction Layer
│   │   ├── dal.ds
│   │   └── dal_tests.ds
│   ├── xdv_qdomain/     # Quantum domain (hardware-gated)
│   │   ├── qdomain.ds
│   │   └── qdomain_tests.ds
│   ├── xdv_phidomain/   # Phase-native domain (hardware-gated)
│   │   ├── phidomain.ds
│   │   └── phidomain_tests.ds
│   ├── xdv_cds/         # Cross-Domain Scheduler
│   │   ├── cds.ds
│   │   └── cds_tests.ds
│   ├── xdv_umf/         # Unified Memory Fabric
│   │   ├── umf.ds
│   │   └── umf_tests.ds
│   ├── xdv_hypervisor/  # Domain Hypervisor
│   │   ├── hypervisor.ds
│   │   └── hypervisor_tests.ds
│   ├── xdv_sdbm/        # Secure Domain Boundary Manager
│   │   ├── sdbm.ds
│   │   └── sdbm_tests.ds
│   └── xdv_odt/         # Observability & Trace
│       ├── odt.ds
│       └── odt_tests.ds
```

## Domain Support

### K-Domain (Classical) - FULL
Traditional computing on x86-64 architecture with full kernel support:
- Process scheduling and management
- Virtual memory with page tables
- Device I/O
- System calls

### Q-Domain (Quantum) - HARDWARE GATED
Operations return ERR_DOMAIN_NOT_AVAILABLE (100) when quantum hardware is not detected.
- Check availability: `q_available()` returns 0

### Φ-Domain (Phase-Native) - HARDWARE GATED
Operations return ERR_DOMAIN_NOT_AVAILABLE (100) when phase-native hardware is not detected.
- Check availability: `phi_available()` returns 0

## Building

```bash
# Check all kernel sectors
dust check sector/xdv_boot/src
dust check sector/xdv_memory/src
dust check sector/xdv_cpu/src
dust check sector/xdv_drivers/src
dust check sector/xdv_kernel/src
dust check sector/xdv_dal/src
dust check sector/xdv_qdomain/src
dust check sector/xdv_phidomain/src
dust check sector/xdv_cds/src
dust check sector/xdv_umf/src
dust check sector/xdv_hypervisor/src
dust check sector/xdv_sdbm/src
dust check sector/xdv_odt/src
```

## CI/CD

The kernel uses GitHub Actions for continuous integration:

```yaml
# .github/workflows/ci.yml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Clone dust compiler
        run: git clone --depth 1 https://github.com/dustlang/dust.git ../dust
      - name: Build Dust compiler
        run: cd ../dust && cargo build --workspace
      - name: Check all kernel sectors
        run: |
          for sector in xdv_boot xdv_memory xdv_cpu xdv_drivers xdv_kernel xdv_dal xdv_qdomain xdv_phidomain xdv_cds xdv_umf xdv_hypervisor xdv_sdbm xdv_odt; do
            dust check "sector/$sector/src"
          done
```

## Features

### Memory Management
- Physical memory allocator (buddy system)
- Virtual memory with page tables
- Domain-specific memory protections
- Unified Memory Fabric

### Cross-Domain Scheduling
- Unified scheduler for K, Q, and Φ domains
- Priority-based and round-robin scheduling
- Coherence-aware scheduling

### Security
- Capability-based access control
- Domain isolation enforcement
- Cross-domain message validation

### Observability
- Domain-specific telemetry collection
- System health monitoring
- Deterministic tracing

## Related Components

- [xdv-boot](../xdv-boot) - Bootloader
- [xdv-xdvfs](../xdv-xdvfs) - Native file system

## Documentation

- [Specification](./spec/XDV-Kernel-v0.2-Specification.md) - Full kernel specification

## License

Copyright © 2026 Dust LLC - See LICENSE file
