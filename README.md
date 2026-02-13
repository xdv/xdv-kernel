# XDV Kernel

A minimal yet functional operating-system kernel for x86-64, written entirely in the Dust Programming Language (DPL).

## Overview

XDV demonstrates the viability of Dust for systems programming by implementing a complete kernel with:

- **Process Scheduling**: Round-robin scheduler with deterministic execution
- **Virtual Memory Management**: Full page table implementation with protection
- **Device Drivers**: VGA display, keyboard, serial, storage, and network
- **System Call Interface**: Clean syscall ABI for user programs

## Design Principles

### Determinism
Kernel subsystems are deterministic wherever possible. Concurrency primitives use seeded schedulers to allow reproducible execution.

### Safety
Relies on Dust's type system and effects to prevent memory corruption, race conditions, and undefined behavior.

### Modularity
Kernel subsystems are separated into crates (sectors):
- `xdv_boot` - Boot and early initialization
- `xdv_memory` - Memory management
- `xdv_cpu` - CPU and interrupt handling
- `xdv_drivers` - Device drivers
- `xdv_kernel` - Core kernel

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

# Run tests
dust test
```

## Architecture

```
XDV Kernel
├── xdv_boot/           # Boot sector - Multiboot2, GDT, IDT
├── xdv_memory/         # Memory management - Buddy allocator, page tables
├── xdv_cpu/            # CPU management - Interrupts, exceptions
├── xdv_drivers/       # Device drivers - VGA, keyboard, storage
└── xdv_kernel/        # Core kernel - Initialization, syscalls
```

## Features

### Memory Management
- Physical memory allocator (buddy system)
- Virtual memory with page tables
- Memory protection (NX, R/W/X)
- Kernel heap allocation

### Process Scheduling
- Round-robin scheduler
- Process control blocks (PCB)
- Thread creation and management
- Deterministic scheduling with seeded randoms

### Device Drivers
- VGA text mode display
- PS/2 keyboard input
- Serial port (UART) communication
- AHCI storage driver
- Network driver framework

### System Calls
- Process management (fork, exec, exit)
- Memory allocation (brk, mmap)
- File operations (open, read, write, close)
- Inter-process communication

## Testing

```bash
# Run unit tests
cargo test

# Run integration tests
cargo test --integration

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
3. Modules remain decoupled
4. Tests pass before submitting

## License

Copyright © 2026 Dust LLC - See LICENSE file
