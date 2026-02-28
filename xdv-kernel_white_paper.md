# XDV Kernel White Paper

Version: 0.2.0  
Status: Active Reference Architecture  
Implementation Language: Dust Programming Language (DPL) with bare-metal runtime assembly support  
Primary Target: x64-pc-none (Intel/AMD)

## Abstract

The XDV Kernel is the operating system kernel for XDV OS. It is implemented as a sectorized DPL workspace and linked into `kernel.bin` for boot-time execution in bare-metal and virtualized environments. The kernel provides a production K-domain execution path, hardware-gated Q-domain and Phi-domain interfaces, and a deterministic runtime surface for memory, CPU, driver, scheduling, security, and observability services.

In the current XDV OS boot contract, stage-0 loads `boot.bin`, `boot.bin` locates `/console/kernel.bin` on xdvfs, and transfers control to the kernel entry path.

This document describes the current implemented architecture and runtime behavior of `xdv-kernel`.

## 1. Design Objectives

1. Deliver a DPL-native kernel core for x64 systems.
2. Keep the kernel modular through independently testable sectors.
3. Provide deterministic boot and runtime behavior for VM and hardware bring-up.
4. Expose stable APIs for xdv-runtime, xdv-boot, and xdv-os integration.
5. Preserve forward compatibility for Q-domain and Phi-domain expansion while keeping K-domain operational now.

## 2. Scope and Non-Scope

### 2.1 In Scope

- Kernel startup and boot handoff handling.
- Core runtime bring-up for K-domain execution.
- Sectorized subsystems for CPU, memory, drivers, scheduling, security, and tracing.
- Bare-metal console and keyboard command runtime path used in xdv-os VM validation.

### 2.2 Out of Scope in Current Version

- Hardware-active Q-domain computation.
- Hardware-active Phi-domain computation.
- Full production-grade device microdrivers in all subsystems.
- Journaling/distributed kernel services.

Q-domain and Phi-domain APIs are present and intentionally hardware-gated.

## 3. System Context and Boot Chain

XDV OS boot chain:

1. `xdv-os/src/boot_sector.asm` (stage-0, MBR entry) loads `boot.bin` only.
2. `xdv-boot` executes splash and firmware-origin recognition (MBR/UEFI).
3. `xdv-boot` mounts xdvfs and resolves `xdvfs:/console/kernel.bin`.
4. `xdv-boot` loads `kernel.bin` and performs handoff.
5. `XdvKernel::kernel_start()` initializes kernel/runtime path.

The stage-0 contract is strict: stage-0 does not preload or call the kernel directly.

## 4. Workspace and Sector Architecture

`xdv-kernel` is a workspace manifest (`State.toml`) with 8 in-repo sectors and
5 standalone split dependencies.

1. `xdv_boot` - boot and early initialization contracts.
2. `xdv_memory` - memory manager contracts and allocation primitives.
3. `xdv_cpu` - CPU setup, control register access, and interrupt-state routines.
4. `xdv_drivers` - VGA/keyboard/serial driver contracts.
5. `xdv_kernel` - core kernel entry and runtime handoff sequence.
6. `xdv_qdomain` - quantum domain subsystem (hardware-gated).
7. `xdv_phidomain` - phase-native subsystem (hardware-gated).
8. `xdv_odt` - observability and deterministic trace layer.

Standalone split dependencies consumed via `workspace.sectors`:

- `xdv-dal` - domain abstraction layer and capability contracts.
- `xdv-cds` - cross-domain scheduling contracts.
- `xdv-umf` - unified memory fabric contracts.
- `xdv-hypervisor` - domain virtualization controls.
- `xdv-sdbm` - secure domain boundary manager.

Target profile:

- `x64-pc-none`
- Linker: `ld`
- Linker flags: `-nostdlib`, `-static`

## 5. Kernel Entry and Initialization Sequence

Primary kernel entry path (`xdv-kernel/sector/xdv_kernel/src/kernel.ds`):

1. Emit startup banner.
2. Call `xdv_os_boot_contract()`.
3. Emit loader handoff confirmation.
4. Execute `init_kernel_boot()`.
5. Execute `load_runtime_boot()`.
6. Execute `start_runtime_boot()`.
7. Enter `kernel_main_boot()`.

Key integration calls:

- `xdv_os_boot_contract()` from `xdv-os` contract forge.
- `init()` and `start_userspace()` from xdv-runtime bridge.

Boot identity and status in current implementation:

- Kernel version constant: `2`.
- Build date constant: `20260212`.
- Boot banner indicates K-domain online on x64 Intel/AMD.

## 6. Runtime Path and Userspace Bridge

Kernel runtime bridge semantics:

- `load_runtime_boot()` loads xdv-runtime.
- `start_runtime_boot()` starts userspace bootstrap.
- Runtime path emits bridge readiness and handoff status.

xdv-runtime bridge then drives:

- runtime init healthcheck,
- shell bootstrap,
- preload package exposure (`xdv-os`, `xdv-core`/`xdv-runtime-utils`, `xdv-edx`, `xdv-shell`).

## 7. Bare-Metal Console and Command Runtime Path

For xdv-os bare-metal profile, `xdv-kernel/sector/xdv_kernel/src/kernel_runtime_shell.asm` provides an integrated runtime shell loop with direct VGA and keyboard interaction.

### 7.1 Console I/O Model

- VGA text buffer base: `0xB8000`.
- Screen size model: 80x25.
- Cursor and newline logic with clear-screen rollover.
- Prompt: `#:`.

### 7.2 Keyboard Model

- PS/2 controller polling (`0x64` status, `0x60` scancode).
- US keyboard layout via set-1 translation tables.
- Shift/Caps/Ctrl/Alt tracking.
- Input editing with backspace support.

### 7.3 Command Buffer Model

- Line buffer length: `256` bytes (`LINE_MAX`).
- Token name length: `24` bytes (`NAME_MAX`).
- Command parsing into command and argument tokens.

### 7.4 Dispatcher Surface

Shell commands include:

- `cd ls cat mkdir rm echo ps help exit edx pwd`

Runtime utility command families also exposed in this path:

- xdv-core style commands: `console init io memory process scheduler strings runtime-admin sysmon service log storage security recovery cli`
- xdvfs-utils style commands: `probe partition mkfs fsck dir file mount space perm`

The assembly runtime path reports live metrics such as boot ticks, command count, keyboard state, scheduler state, recovery runs, and simple storage profile values.

## 8. K-Domain, Q-Domain, and Phi-Domain Model

### 8.1 K-Domain

K-domain is the active execution domain in current builds. Core services (boot, memory, cpu, drivers, runtime handoff, shell path) execute in this domain.

### 8.2 Q-Domain

`xdv_qdomain` exports quantum subsystem APIs but returns `Q_ERROR_NOT_AVAILABLE (100)` when hardware is unavailable. Validation and argument checks are implemented for register/qubit/gate inputs.

### 8.3 Phi-Domain

`xdv_phidomain` exports phase subsystem APIs but returns `PHI_ERROR_NOT_AVAILABLE (100)` when hardware is unavailable. Input validation for phase/coherence operations is implemented.

## 9. Memory Architecture

Memory contracts are split across `xdv_memory` and `xdv_umf`.

### 9.1 xdv_memory

Key constants:

- Page size: `4096`
- Kernel pages profile: `65536`
- Kernel heap base: `16777216`

Primary operations:

- `memory_init()`, `init_buddy_allocator()`, `init_kernel_heap()`
- `alloc_physical_page()`, `free_physical_page()`
- `vmalloc()`, `vmfree()`, `mprotect()`

### 9.2 xdv_umf (Unified Memory Fabric)

UMF provides domain-aware memory contracts and protection flags:

- read/write/exec protections,
- qstate/phistate tags,
- coherence and no-clone flags,
- shared memory pool semantics.

Q/Phi memory allocation calls return unavailable markers until hardware support is present.

## 10. CPU and Driver Model

### 10.1 CPU Sector

`xdv_cpu` includes:

- GDT/IDT/TSS setup contracts,
- interrupt enable/disable routines,
- control register read/write APIs,
- stack and instruction pointer boot values.

### 10.2 Driver Sector

`xdv_drivers` includes:

- VGA initialization and text output contracts,
- keyboard init/read contracts,
- serial init and I/O contracts.

These routines provide deterministic return/status behavior for boot/runtime sequencing.

## 11. Cross-Domain Control Plane

### 11.1 DAL (Domain Abstraction Layer)

`xdv-dal` defines:

- domain IDs (`K=0`, `Q=1`, `PHI=2`),
- capability masks for compute, memory, IO, scheduling, transfer, telemetry,
- transfer contract creation and validation,
- domain initialization/status typing helpers.

### 11.2 CDS (Cross-Domain Scheduler)

`xdv-cds` provides:

- policy identifiers (round-robin, priority, EDF, coherence-aware, domain-fair),
- scheduler init and tick orchestration,
- task and domain job contract surfaces,
- scheduler statistics.

In current implementation, K-domain scheduling paths are active; Q/Phi scheduling returns no-work style statuses.

## 12. Virtualization, Security, and Observability

### 12.1 Hypervisor Sector

`xdv-hypervisor` provides VM lifecycle contracts:

- create/configure/start/pause/resume/destroy,
- vCPU/vQPU/vPhiPU configuration,
- memory and isolation checks,
- stats retrieval.

### 12.2 SDBM Sector

`xdv-sdbm` provides security boundary contracts:

- capability creation/verification,
- permission checks,
- cross-domain message validation,
- audit logging,
- nonce/signature utilities.

### 12.3 ODT Sector

`xdv_odt` provides observability contracts:

- trace event logging,
- domain transition logging,
- K/Q/Phi telemetry collection,
- health and stats queries,
- trace export and buffer management.

## 13. Status and Error Semantics

The kernel uses explicit integral status codes across sectors.

Common patterns:

- `0` for success (`STATUS_OK`).
- Domain unavailability paths use code `100` in Q/Phi-related sectors.
- Validation errors use non-zero deterministic codes specific to each sector.

This contract-first status model is used instead of implicit exception-style control flow.

## 14. Build and Artifact Model in xdv-os

Within xdv-os image build:

1. `boot.bin` is linked from xdv-boot object set via `dustlink`.
2. `kernel.bin` is linked from xdv-kernel + xdv-runtime + xdv-xdvfs object sets via `dustlink`.
3. Stage-0 (`boot_sector.asm`) loads only `boot.bin`.
4. `boot.bin` loads `/console/kernel.bin` from xdvfs and performs final handoff.

This enforces separation between stage-0, boot runtime, and kernel runtime responsibilities.

## 15. Validation and Testing

Each sector includes a paired `*_tests.ds` module in the workspace. Test coverage is organized per subsystem so that boot, memory, cpu, drivers, domain layers, scheduler, security, and observability contracts can be checked independently.

Minimum workspace validation pattern:

- `dust check` against each sector `src` path.

## 16. Current Limitations

1. Q-domain and Phi-domain hardware paths are intentionally unavailable in current runtime builds.
2. Several subsystems expose stable contracts with deterministic placeholder behavior pending deeper hardware backend implementation.
3. Kernel runtime shell path is currently provided via assembly for bare-metal validation profile.

These limitations are explicit design-stage constraints, not undefined behavior.

## 17. Roadmap Direction

1. Replace deterministic placeholder internals with hardware-backed implementations while preserving API contracts.
2. Expand kernel-level scheduling and memory enforcement depth across K/Q/Phi domains.
3. Increase capability policy richness in SDBM and stronger trace correlation in ODT.
4. Continue reducing boot-path coupling by keeping stage-0 minimal and boot/runtime responsibilities strict.
5. Maintain GCC-style object/link compatibility in the build pipeline through dust compiler object outputs and dustlink linkage.

## Conclusion

The XDV Kernel provides a modular DPL-native kernel foundation with a working K-domain boot/runtime path, explicit cross-domain abstractions, and deterministic subsystem contracts. Integrated with xdv-boot, xdv-runtime, and xdv-xdvfs, it forms the `kernel.bin` execution core of XDV OS while preserving clear extension points for future Q-domain and Phi-domain hardware enablement.
