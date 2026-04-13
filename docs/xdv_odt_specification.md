# XDV Kernel: xdv_odt Sector Specification

## Document Version: 1.0  
**Author**: Senior Developer, XDV Kernel Team  
**Last Updated**: 2026-04-13

---

## Overview

The **xdv_odt** sector (Object Descriptor Table) is the kernel's **runtime type information and capability management system** for in-memory objects during boot and initialization phases.

---

## Purpose & Rationale

### Core Function

The xdv_odt sector provides:
- **Object type introspection** for kernel objects during boot
- **Runtime safety guarantees** via typed object descriptors
- **Capability-link association** for resource objects
- **Boot-time sanity checks** via descriptor validation

### Why ODT?

**Requirements During Boot:**
- Multi-sector initialization needs to share object references safely
- Runtime depends on type information being correct
- Capabilities stored with objects for boot-time delegation

### Key Benefits

1. **Type Safety**: Objects carry descriptor tables with type info
2. **Capability Association**: Every object descriptor links to capability
3. **Boot Validation**: Descriptors validated before runtime handoff
4. **Sector Independence**: Each sector can validate its own objects

---

## Architecture

### DataStructures

#### ObjectDescriptor
```rust
struct ObjectDescriptor {
    magic: u32,              // 0x4f445422 ("ODT\x22")
    obj_type: u32,         // Type tag (memory, process, capability, etc.)
    size: u64,             // Object size
    owner: u32,            // Owning sector/task
    capability_id: u64,    // Associated capability
    valid_from: u64,       // Valid start cycle
    valid_until: u64,      // Valid end cycle (or 0 for unlimited)
    checksum: u32,         // CRC32 of descriptor
 }
```

#### ObjectTable
 ```rust
 struct ObjectTable {
     count: u32,
     capacity: u32,
     descriptors: [ObjectDescriptor; MAX_DESCRIPTORS],
 }
```

### ODT Operations

#### Core API
```rust
/// Create descriptor for object
proc K::odt_create_descriptor(obj_addr: u64, obj_type: u32, 
                              size: u64) -> ObjectDescriptor;

/// Validate descriptor before use
proc K::odt_validate_descriptor(desc: &ObjectDescriptor) -> bool;

/// Find descriptor by address or capability ID
proc K::odt_find_by_addr(addr: u64) -> Option<&ObjectDescriptor>;
proc K::odt_find_by_cap(cap_id: u64) -> Option<&ObjectDescriptor>;

/// Invalidate descriptor (for cleanup)
proc K::odt_invalidate_descriptor(desc: &mut ObjectDescriptor);

/// Take snapshot for debugging
proc K::odt_snapshot() -> ObjectTable;
```

#### Object Types
- `TYPE_MEMORY` (0x01) - Memory buffers
- `TYPE_PROCESS` (0x02) - Process handles
- `TYPE_CAPABILITY` (0x03) - Capability tokens
- `TYPE_CONTRACT` (0x04) - Resource contracts
- `TYPE_SECTOR` (0x05) - Sector descriptors
- `TYPE_BUFFER` (0x06) - Data buffers
- `TYPE_STREAM` (0x07) - I/O streams

---

## Usage Patterns

### Boot Sequence

```rust
// In CPU sector initialization
proc xdv_cpu::init() -> u32 {
    // Describe CPU objects
    let cpu_desc = K::odt_create_descriptor(
        cpu_struct_addr,
        TYPE_SECTOR,
        sizeof(cpu_struct)
    );
    
    // Validate before use
    if !K::odt_validate_descriptor(&cpu_desc) {
        return ERR_INVALID_CPU_DESCRIPTOR;
    }
    
    // Store in ODT
    K::odt_add_descriptor(cpu_desc)?;
    
    ERR_OK
}
```

### Runtime Handoff

```rust
// During runtime bootstrap
proc xdv_kernel::load_runtime_boot() -> u32 {
    // Validate all ODT descriptors before handoff
    for desc in odt_snapshot().descriptors.iter() {
        if !K::odt_validate_descriptor(desc) {
            // Panic: corrupted ODT during boot
            return ERR_CORRUPT_ODT_VIA_BOOT;
        }
    }
    
    // Only proceed if all descriptors valid
    K::handoff_to_runtime(&descriptors)?;
}
```

### Capability Delegation

```rust
// When delegating capability to process
proc xdv_kernel::delegate_capability(cap: Capability, pid: u32) -> u32 {
    // Find the object descriptor for the capability
    let desc_opt = K::odt_find_by_cap(cap.id());
    
    match desc_opt {
        Some(desc) => {
            // Validate: owner must be current task
            if K::get_current_pid() != desc.owner {
                return_ERR_CAPABILITY_VIOLATION;
            }
        }
        None => {
            return ERR_NO_CAPABILITY_DESCRIPTOR;
        }
    }
}
```

---

## Validation Rules

### Descriptor Validation (K::odt_validate_descriptor)

**Checks Performed:**

1. **Magic validation** (bytes 0x4f445422)
2. **Type field bounds** (`TYPE_MIN` - `TYPE_MAX`)
3. **Size reasonableness** (non-zero, within sector limits)
4. **Owner validity** (PID exists and is initialized)
5. **Capability association** (referential integrity)
6. **Temporality** (`valid_from` ≤ cycle ≤ `valid_until` or `valid_until` == 0)
7. **Checksum verification** (CRC32(descriptor fields))

### Invariants Maintained

1. **No duplicate addresses** in same ODT table
2. **Capability IDs unique** per descriptor
3. **Owner PID** must have initialized state
4. **Address ranges** cannot overlap
5. **Lifecycle tracking** captures create/destroy cycles

### Boot-Time Policies

**Before Runtime Handoff:**
- ALL descriptors locked so runtime can't modify boot-time state
- All references valid (not dangling)
- All checksums recalculated
- ODT integrity verified

**Runtime:**
- ODT cannot be modified (architecturally locked)
- Runtime gets snapshot(s) for introspection
- Only new descriptors can be added (not modify boot ones)

---

## Performance Characteristics

### ODT Size

- Maximum tracked objects: `MAX_DESCRIPTORS = 16,384`
- Memory footprint: ~1MB per ODT instance
- Descriptor size: 64 bytes per object
- Search complexity: O(n) linear per sector (acceptable for boot + small tables)

### Boot Overhead

- Full ODT scan: ~1000 CPU cycles (twice during boot)
- Descriptor validate: ~50 cycles
- Add descriptor: ~25 cycles
- ODT snapshot: ~5000 cycles

### Runtime Impact

- Handoff to runtime: negligible overhead (linear pass, rarely accessed)
- ODT immutable after handoff
- Runtime introspection: O(1) lookup by capability ID (hash based)

---

## Security Considerations

### Attack Vectors Addressed

1. **Descriptor Corruption:** Checksum validation detects tampering
2. **Fake Capabilities:** Capabilities must have valid descriptors
3. **Use-After-Free:** Descriptors remember cycle validity
4. **Confused Deputy:** Owner field tracks delegation authority
5. **Time Travel:** Temporal fields prevent using outdated descriptors

### Security Policies

- **Boot descriptors locked** - runtime cannot modify
- **Owner-only update** - only object owner can mark invalid
- **Check before use** - all use requires validate_descriptors()
- **Snapshot isolation** - runtime gets copy, can't corrupt

---

## Implementation Notes

### Sector Integration

ODT is **always linked** sector-to-sector during boot:

1. **boot sector** creates initial ODT
2. Each sector init copies its descriptors to ODT
3. **kernel sector** validates full ODT before runtime handoff
4. **runtime** receives validated snapshot

### Synchronization

No locks needed during boot (single-threaded boot phase).
After handoff to runtime:
- Runtime can read (immutable ODT)
- ODT can append new descriptors (append-only)
- Cannot modify boot descriptors (immutability enforced)

---

## Known Limitations

1. **Linear lookup** - O(n) on sector validation (acceptable for boot)
2. **Fixed size** - MAX_DESCRIPTORS limit (adjustable via build config)
3. **No compression** - all values stored raw in descriptor
4. **Boot-only** - no runtime modifications after handoff

---

## Example Boot Sequence with ODT

```rust
proc xdv_boot::boot() -> u32 {
    // Initialize empty ODT
    K::odt_init();
    
    // Create descriptors for boot objects  
    let boot_desc = K::odt_create_descriptor(
        boot_struct,
        TYPE_SECTOR,
        sizeof(boot_struct)
    );
    K::odt_add(boot_desc);
    
    // Load next sector
    let cpu_desc = K::odt_create_descriptor(
        cpu_struct,
        TYPE_SECTOR,
        sizeof(cpu_struct)
    );
    K::odt_add(cpu_desc);
    
    // ... continue for all sectors
    
    // Validate all before handoff
    if !K::odt_validate_all() {
        return ERR_ODT_CORRUPT;
    }
    
    // Lock ODT (mark immutable)
    K::odt_lock();
    
    // Handoff to runtime
    K::handoff_to_runtime(K::odt_snapshot())?;
}
```

---

## Future Enhancements

Potential extensions for future development:
- [ ] Runtime ODT modularity (per-subsystem ODTs)
- [ ] ODT serialization for crash dumps
- [ ] Remote ODT introspection
- [ ] Cryptographically signed descriptors
- [ ] Hardware ODT verification

---

## Testing

ODT validation covered by:
- `test_odt_descriptor_validation()` - validates single descriptor
- `test_odt_overlap_detection()` - checks range overlap logic
- `test_odt_boot_integrity()` - validates ODT before boot handoff
- `test_odt_temporal_validation()` - checks time-based validity

---

## Summary

**xdv_odt** is the kernel's **object descriptor and type information system** for boot-time safety and runtime introspection. It validates objects, tracks their types and capabilities, and prevents security violations through descriptor validation.

**Critical Core Level Sector**
- **Purpose**: Type safety & capability tracking
- **Size**: 11K (largest utility sector)
- **Critical**: Contract enforcement uses ODT
- **Immutable**: Boot-time locked for safety

---

**Questions?** Contact Senior Developer or xdv-kernel-team@dust.local
