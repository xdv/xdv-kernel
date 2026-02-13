# XDV Kernel v0.2

A Cross-Domain Virtualizer operating system kernel for x86-64, written entirely in the Dust Programming Language (DPL).

## Overview

XDV v0.2 is a revolutionary multi-domain operating system kernel that supports three computational domains:

- **K-Domain (Classical)**: Traditional von Neumann computing on x64
- **Q-Domain (Quantum)**: Quantum computing simulation and management
- **Φ-Domain (Phase-Native)**: Phase-based computation for novel computing paradigms

XDV demonstrates the power of Dust for systems programming by implementing a complete kernel with:

- **Cross-Domain Scheduler**: Unified scheduling across K, Q, and Φ domains
- **Unified Memory Fabric**: Domain-aware memory management with quantum and phase-state support
- **Secure Domain Boundary Manager**: Capability-based security across domains
- **Hypervisor**: Virtual machine management for all three domain types
- **Full Memory Management**: Physical and virtual memory with domain-specific protections

## Design Principles

### Constraint-First
All operations respect DPL's constraint model. The kernel never performs undefined operations.

### Determinism
Kernel subsystems are deterministic wherever possible. Concurrency primitives use seeded schedulers to allow reproducible execution.

### Safety
Relies on Dust's type system and effects to prevent memory corruption, race conditions, and undefined behavior.

### Cross-Domain Security
The Secure Domain Boundary Manager (SDBM) enforces strict isolation between K, Q, and Φ domains using capability-based security.

## Kernel Sectors

The kernel is organized into 13 sectors:

| Sector | Purpose |
|--------|---------|
| `xdv_boot` | Boot and early initialization |
| `xdv_memory` | Physical and virtual memory management |
| `xdv_cpu` | CPU management, interrupts, exceptions |
| `xdv_drivers` | Device drivers (VGA, keyboard, storage, network) |
| `xdv_kernel` | Core kernel functionality and main loop |
| `xdv_dal` | Domain Abstraction Layer - unified domain interfaces |
| `xdv_qdomain` | Quantum domain subsystem |
| `xdv_phidomain` | Phase-Native domain subsystem |
| `xdv_cds` | Cross-Domain Scheduler |
| `xdv_umf` | Unified Memory Fabric |
| `xdv_hypervisor` | Domain Hypervisor |
| `xdv_sdbm` | Secure Domain Boundary Manager |
| `xdv_odt` | Observability & Deterministic Trace Layer |

## Building

### Prerequisites

- DPL v0.2 compiler (dust)
- QEMU (for testing)
- x86-64 assembly toolchain

### Build Commands

```bash
# Build the kernel
dust build

# Run in QEMU
dust run

# Check syntax
dust check
```

## Architecture

```
XDV Kernel v0.2
├── xdv_boot/           # Boot sector - Multiboot2, GDT, IDT, paging
├── xdv_memory/         # Memory management - Buddy allocator, page tables
├── xdv_cpu/            # CPU management - Interrupts, exceptions, timer
├── xdv_drivers/        # Device drivers - VGA, keyboard, storage, network
├── xdv_kernel/         # Core kernel - Initialization, main loop
├── xdv_dal/            # Domain Abstraction Layer
├── xdv_qdomain/        # Quantum domain - Qubits, gates, coherence
├── xdv_phidomain/      # Phase-Native domain - Phase states, transforms
├── xdv_cds/            # Cross-Domain Scheduler - Unified scheduling
├── xdv_umf/            # Unified Memory Fabric - Domain-aware memory
├── xdv_hypervisor/     # Hypervisor - VM management
├── xdv_sdbm/           # Secure Domain Boundary - Capabilities
└── xdv_odt/            # Observability - Telemetry, tracing
```

## Domain Support

### K-Domain (Classical)
Traditional computing on x86-64 architecture with full kernel support:
- Process scheduling and management
- Virtual memory with page tables
- Device I/O
- System calls

### Q-Domain (Quantum)
Quantum computing simulation and management:
- Quantum register allocation
- Gate operations (Hadamard, CNOT, Pauli, etc.)
- Coherence window management
- Measurement operations

### Φ-Domain (Phase-Native)
Phase-based computation subsystem:
- Phase state allocation
- Phase transforms (Shift, Interference, Amplitude)
- Coherence window management
- Phase validation

## Features

### Memory Management
- Physical memory allocator (buddy system)
- Virtual memory with page tables
- Domain-specific memory protections
- Unified Memory Fabric for cross-domain memory operations
- Quantum state memory protection
- Phase coherence memory management

### Cross-Domain Scheduling
- Unified scheduler for K, Q, and Φ domains
- Priority-based and round-robin scheduling
- Coherence-aware quantum job scheduling
- Real-time phase window scheduling

### Security
- Capability-based access control
- Domain isolation enforcement
- Cross-domain message validation
- Nonce generation for security

### Observability
- Domain-specific telemetry collection
- Quantum diagnostics (fidelity, decoherence events)
- Phase diagnostics (coherence events)
- System health monitoring
- Deterministic tracing

## Testing

```bash
# Check all kernel files compile
dust check sector/*/src/*.ds

# Boot test in QEMU
qemu-system-x86_64 -kernel build/xdv.bin
```

## Documentation

- [Specification](./spec/XDV-Kernel-v0.2-Specification.md) - Full kernel specification
- [Changelog](./CHANGELOG.md) - Version history

## Contributing

Contributions are welcome! Please ensure:

1. Determinism is preserved where possible
2. Safety properties are maintained
3. Domain separation is respected
4. Tests pass before submitting

## License

Copyright © 2026 Dust LLC - See LICENSE file
