# Sector Reference

The kernel workspace is split into sectors under `sector/`.

## Core sectors

- `sector/xdv_boot/src/boot.ds`
  - early boot/kernel bootstrap sector logic.
- `sector/xdv_kernel/src/kernel.ds`
  - kernel top-level start path and runtime initialization.
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

- `sector/xdv_dal/src/dal.ds`
  - domain abstraction layer.
- `sector/xdv_qdomain/src/qdomain.ds`
  - Q-Domain model and hardware-gated interfaces.
- `sector/xdv_phidomain/src/phidomain.ds`
  - Phi-Domain model and hardware-gated interfaces.
- `sector/xdv_cds/src/cds.ds`
  - cross-domain scheduler model.
- `sector/xdv_umf/src/umf.ds`
  - unified memory fabric model.
- `sector/xdv_hypervisor/src/hypervisor.ds`
  - domain hypervisor model.
- `sector/xdv_sdbm/src/sdbm.ds`
  - secure domain boundary management model.
- `sector/xdv_odt/src/odt.ds`
  - observability and deterministic trace model.

## Tests

Each sector includes matching test modules, for example:

- `sector/xdv_kernel/src/kernel_tests.ds`
- `sector/xdv_memory/src/memory_tests.ds`
- `sector/xdv_cpu/src/cpu_tests.ds`

Use `dust check` over each sector `src` directory to validate parser/type
coverage in CI and local workflows.
