# Sector Reference

The kernel workspace is split into **core sectors only** under `sector/`.

## Core sectors

- `sector/xdv_boot/src/boot.ds`
  - early boot/kernel bootstrap sector logic.
- `sector/xdv_kernel/src/kernel.ds`
  - kernel top-level start path and runtime/interface assertions.
- `sector/xdv_kernel/src/kernel_runtime_shell.asm`
  - bare-metal runtime shell command/input path.

## Platform/runtime sectors

- `sector/xdv_memory/src/memory.ds`
  - memory model interfaces.
- `sector/xdv_cpu/src/cpu.ds`
  - CPU/interrupt model interfaces.
- `sector/xdv_drivers/src/drivers.ds`
  - core driver abstraction and bring-up interfaces.

## Cross-domain sectors

- `sector/xdv_qdomain/src/qdomain.ds`
  - Q-Domain model and hardware-gated interfaces.
- `sector/xdv_phidomain/src/phidomain.ds`
  - Phi-Domain model and hardware-gated interfaces.
- `sector/xdv_odt/src/odt.ds`
  - observability and deterministic trace model.

## Split dependencies (external, versioned interfaces)

The following subsystems are consumed as standalone projects and validated by
versioned interface functions:

- `../xdv-dal/src/dal.ds`
  - `xdv_dal_interface_version_major/minor/patch`
- `../xdv-cds/src/cds.ds`
  - `xdv_cds_interface_version_major/minor/patch`
- `../xdv-umf/src/umf.ds`
  - `xdv_umf_interface_version_major/minor/patch`
- `../xdv-hypervisor/src/hypervisor.ds`
  - `xdv_hypervisor_interface_version_major/minor/patch`
- `../xdv-sdbm/src/sdbm.ds`
  - `xdv_sdbm_interface_version_major/minor/patch`

Expected version triplet in this milestone: `0.1.0`.

## Tests

Each core sector includes matching test modules, for example:

- `sector/xdv_kernel/src/kernel_tests.ds`
- `sector/xdv_memory/src/memory_tests.ds`
- `sector/xdv_cpu/src/cpu_tests.ds`

Use `dust check` over each sector `src` directory plus split dependency `src`
paths to validate parser/type coverage in CI and local workflows.