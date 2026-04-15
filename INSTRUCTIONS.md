# XDV Kernel - Dust v0.2 Conversion Instructions

## Problem
The kernel files were implemented using Rust-like syntax instead of proper Dust Programming Language v0.2 syntax.

## Dust v0.2 Syntax Required (from dustlang/dustlang specification)

### File Structure
```
forge ModuleName {
    // Constants
    const NAME: Type = value;
    
    // Shapes (structs in Dust)
    shape TypeName {
        field1: Type1;
        field2: Type2;
    }
    
    // Procedures (functions)
    proc K::function_name(K[ParamType] param) -> K[ReturnType] {
        // Body with Dust operations
    }
}
```

### Required Files to Convert/Rewrite

1. **hex.ds** - Hex encoding utilities
2. **console.ds** - Console I/O 
3. **handle.ds** - Resource/domain ID types
4. **errors.ds** - Error types
5. **capability.ds** - Capability system
6. **memory.ds** - Memory management
7. **tracing/tracing.ds** - Tracing/logging
8. **lib.ds** - Module declarations
9. **init/main.ds** - Main kernel initialization 
10. **boot/boot.ds** - Boot integration

### Dust Types to Use
- `K[String]` for strings
- `K[u64]`, `K[u32]`, etc. for integers
- `K[Ptr[u8]]` for byte pointers
- `K[Bool]` for booleans
- `K[Unit]` for unit/void

### Special Dust Operations
- `unsafe_load_u8(ptr)`, `unsafe_store_u8(ptr, value)` for memory
- `emit "Message {variable}"` for output
- String interpolation within emit
- Return implicit (last expression)

### Examples in /home/marlon/dust.llc/code/dustlang/dust/examples/K/
Look at these files for proper syntax examples.

### Next Steps
1. Create forge wrappers for each module
2. Convert structs to shapes  
3. Convert functions to procedures
4. Update all type annotations to Dust format
5. Test with dustc compiler
6. Integration with xdv-boot and xdv-shell

The kernel directory is ready for proper Dust v0.2 implementation.
