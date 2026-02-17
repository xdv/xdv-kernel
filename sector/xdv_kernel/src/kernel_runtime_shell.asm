BITS 32
ORG 0x10000

%define VGA_BASE      0xB8000
%define VGA_LIMIT     0xB8FA0
%define ATTR          0x0F
%define LINE_MAX      256
%define NAME_MAX      24
%define CUSTOM_MAX    32

%define CWD_ROOT      0
%define CWD_CORE      1
%define CWD_UTILS     2
%define CWD_SHELL     3
%define CWD_EDX       4
%define CWD_CUSTOM    5

%define ENTRY_DIR     1
%define ENTRY_FILE    2

start:
    cli
    call disable_cursor
    call clear_screen
    call init_state

    mov esi, msg_boot_contract_complete
    call print_line
    mov esi, msg_kernel_handoff
    call print_line
    mov esi, msg_kernel_init
    call print_line
    mov esi, msg_kernel_date
    call print_line
    mov esi, msg_domain_boot
    call print_line
    mov esi, msg_domain_online
    call print_line
    mov esi, msg_kernel_load_runtime
    call print_line
    mov esi, msg_runtime_bridge
    call print_line
    mov esi, msg_kernel_start_runtime
    call print_line
    mov esi, msg_runtime_bootstrap
    call print_line
    mov esi, msg_runtime_handoff
    call print_line
    mov esi, msg_runtime_keyboard
    call print_line
    mov esi, msg_runtime_cmd_buffer
    call print_line
    mov esi, msg_runtime_shell_load
    call print_line
    mov esi, msg_runtime_preload
    call print_line
    mov esi, msg_shell_bridge
    call print_line
    mov esi, msg_shell_launch_units
    call print_line
    mov esi, msg_shell_launch
    call print_line
    mov esi, msg_shell_init
    call print_line
    mov esi, msg_shell_online
    call print_line
    mov esi, msg_shell_prompt_mode
    call print_line
    mov esi, msg_shell_dispatch
    call print_line
    mov esi, msg_shell_command_catalog
    call print_line
    mov esi, msg_shell_loop_ready
    call print_line
    mov esi, msg_kernel_main_loop
    call print_line

shell_loop:
    mov esi, prompt
    call puts
    call read_line
    call parse_line
    call dispatch
    jmp shell_loop

; ------------------------------------------------------------
; Console
; ------------------------------------------------------------

disable_cursor:
    mov dx, 0x3D4
    mov al, 0x0A
    out dx, al
    mov dx, 0x3D5
    in al, dx
    or al, 0x20
    out dx, al
    ret

clear_screen:
    push eax
    push ecx
    push edi
    mov edi, VGA_BASE
    mov ecx, 2000
    mov ax, (ATTR << 8) | 0x20
    rep stosw
    mov dword [cursor], VGA_BASE
    pop edi
    pop ecx
    pop eax
    ret

newline:
    push eax
    push ebx
    push edx
    mov eax, [cursor]
    sub eax, VGA_BASE
    xor edx, edx
    mov ebx, 160
    div ebx
    inc eax
    cmp eax, 25
    jb .set_row
    pop edx
    pop ebx
    pop eax
    call clear_screen
    ret
.set_row:
    imul eax, eax, 160
    add eax, VGA_BASE
    mov [cursor], eax
    pop edx
    pop ebx
    pop eax
    ret

putc:
    cmp al, 13
    je .done
    cmp al, 10
    je .nl
    push eax
    push edi
    mov edi, [cursor]
    mov ah, ATTR
    mov [edi], ax
    add edi, 2
    cmp edi, VGA_LIMIT
    jb .store
    pop edi
    pop eax
    call clear_screen
    ret
.store:
    mov [cursor], edi
    pop edi
    pop eax
    ret
.nl:
    call newline
.done:
    ret

puts:
.loop:
    lodsb
    test al, al
    jz .done
    call putc
    jmp .loop
.done:
    ret

print_line:
    call puts
    call newline
    ret

; print a space-delimited string as one token per line.
; in: ESI -> "token1 token2 token3"
print_space_list:
    push eax
    push esi
.loop:
    mov al, [esi]
    test al, al
    jz .done
    cmp al, ' '
    je .sep
    call putc
    inc esi
    jmp .loop
.sep:
    call newline
.skip:
    inc esi
    cmp byte [esi], ' '
    je .skip
    jmp .loop
.done:
    call newline
    pop esi
    pop eax
    ret

; ------------------------------------------------------------
; Keyboard (US layout, set-1)
; ------------------------------------------------------------

read_key_ascii:
.wait:
    in al, 0x64
    test al, 0x01
    jz .wait
    in al, 0x60
    cmp al, 0xE0
    je .set_ext
    mov bl, al
    mov byte [kb_ext], 0

    test bl, 0x80
    jnz .break

    cmp bl, 0x2A
    je .shift_on
    cmp bl, 0x36
    je .shift_on
    cmp bl, 0x1D
    je .ctrl_on
    cmp bl, 0x38
    je .alt_on
    cmp bl, 0x3A
    je .caps_toggle
    cmp bl, 0x1C
    je .enter
    cmp bl, 0x0E
    je .backspace
    cmp bl, 0x39
    je .space
    cmp bl, 0x0F
    je .tab
    cmp bl, 0x80
    jae .none

    movzx ebx, bl
    mov al, [map_unshift + ebx]
    test al, al
    jz .none

    cmp al, 'a'
    jb .symbol
    cmp al, 'z'
    ja .symbol
    mov ah, [kb_shift]
    xor ah, [kb_caps]
    test ah, 1
    jz .ret
    sub al, 32
    ret

.symbol:
    mov ah, [kb_shift]
    test ah, 1
    jz .ret
    mov al, [map_shift + ebx]
    test al, al
    jz .none
.ret:
    ret

.break:
    and bl, 0x7F
    cmp bl, 0x2A
    je .shift_off
    cmp bl, 0x36
    je .shift_off
    cmp bl, 0x1D
    je .ctrl_off
    cmp bl, 0x38
    je .alt_off
    jmp .none

.set_ext:
    mov byte [kb_ext], 1
    jmp .none
.shift_on:
    mov byte [kb_shift], 1
    jmp .none
.shift_off:
    mov byte [kb_shift], 0
    jmp .none
.ctrl_on:
    mov byte [kb_ctrl], 1
    jmp .none
.ctrl_off:
    mov byte [kb_ctrl], 0
    jmp .none
.alt_on:
    mov byte [kb_alt], 1
    jmp .none
.alt_off:
    mov byte [kb_alt], 0
    jmp .none
.caps_toggle:
    mov al, [kb_caps]
    xor al, 1
    mov [kb_caps], al
    jmp .none
.enter:
    mov al, 10
    ret
.backspace:
    mov al, 8
    ret
.space:
    mov al, ' '
    ret
.tab:
    mov al, ' '
    ret
.none:
    xor al, al
    ret

read_line:
    mov dword [line_len], 0
.next:
    call read_key_ascii
    test al, al
    jz .next
    cmp al, 10
    je .done
    cmp al, 8
    je .backspace

    mov ecx, [line_len]
    cmp ecx, LINE_MAX - 1
    jae .next
    mov [line_buf + ecx], al
    inc ecx
    mov [line_len], ecx
    call putc
    jmp .next

.backspace:
    mov ecx, [line_len]
    test ecx, ecx
    jz .next
    dec ecx
    mov [line_len], ecx
    mov edi, [cursor]
    cmp edi, VGA_BASE
    jbe .next
    sub edi, 2
    mov ax, (ATTR << 8) | 0x20
    mov [edi], ax
    mov [cursor], edi
    jmp .next

.done:
    mov ecx, [line_len]
    mov byte [line_buf + ecx], 0
    call newline
    ret

; ------------------------------------------------------------
; Parsing
; ------------------------------------------------------------

skip_spaces:
    mov al, [esi]
.loop:
    cmp al, ' '
    jne .done
    inc esi
    mov al, [esi]
    jmp .loop
.done:
    ret

parse_line:
    mov esi, line_buf
    call skip_spaces
    mov [cmd_ptr], esi
    mov al, [esi]
    test al, al
    jnz .scan
    mov [arg_ptr], esi
    ret
.scan:
    mov al, [esi]
    test al, al
    jz .end
    cmp al, ' '
    je .split
    inc esi
    jmp .scan
.split:
    mov byte [esi], 0
    inc esi
    call skip_spaces
    mov [arg_ptr], esi
    ret
.end:
    mov [arg_ptr], esi
    ret

arg_to_token:
    mov esi, [arg_ptr]
    call skip_spaces
    mov edi, token_buf
    mov ecx, NAME_MAX - 1
.copy:
    mov al, [esi]
    test al, al
    jz .done
    cmp al, ' '
    je .done
    mov [edi], al
    inc edi
    inc esi
    dec ecx
    jnz .copy
.done:
    mov byte [edi], 0
    ; trim trailing '/' characters while preserving "/" root.
    mov ebx, edi
.trim:
    cmp ebx, token_buf
    jbe .ret
    dec ebx
    cmp byte [ebx], '/'
    jne .ret
    cmp ebx, token_buf
    je .ret
    mov byte [ebx], 0
    jmp .trim
.ret:
    ret

lower_pair:
    cmp al, 'A'
    jb .l1
    cmp al, 'Z'
    ja .l1
    add al, 32
.l1:
    cmp bl, 'A'
    jb .done
    cmp bl, 'Z'
    ja .done
    add bl, 32
.done:
    ret

cmd_equals:
    ; in: ESI=pattern, compares [cmd_ptr]
    mov edi, [cmd_ptr]
.loop:
    mov al, [esi]
    mov bl, [edi]
    call lower_pair
    cmp al, bl
    jne .no
    test al, al
    jz .yes
    inc esi
    inc edi
    jmp .loop
.yes:
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

str_equals_ci:
    ; in: ESI, EDI
.loop:
    mov al, [esi]
    mov bl, [edi]
    call lower_pair
    cmp al, bl
    jne .no
    test al, al
    jz .yes
    inc esi
    inc edi
    jmp .loop
.yes:
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

; ------------------------------------------------------------
; CWD and simple root dynamic entries
; ------------------------------------------------------------

init_state:
    mov byte [cwd_mode], CWD_ROOT
    mov byte [cwd_custom_idx], 0xFF
    xor eax, eax
    mov edi, custom_used
    mov ecx, CUSTOM_MAX
    rep stosb
    ret

resolve_target_mode:
    ; in: ESI path token
    ; out: AL mode, AH custom idx (if mode=CWD_CUSTOM), CF=0 success, CF=1 fail
    mov ah, 0xFF
    mov al, [esi]
    test al, al
    jnz .non_empty
    mov al, [cwd_mode]
    mov ah, [cwd_custom_idx]
    clc
    ret
.non_empty:
    cmp al, '/'
    jne .no_slash
    inc esi
.no_slash:
    mov al, [esi]
    test al, al
    jnz .not_root
    mov al, CWD_ROOT
    mov ah, 0xFF
    clc
    ret
.not_root:
    ; split on first '/' so "xdv-core/src" resolves to "xdv-core".
    mov edi, esi
.seg_scan:
    mov al, [edi]
    test al, al
    jz .seg_ready
    cmp al, '/'
    je .seg_split
    inc edi
    jmp .seg_scan
.seg_split:
    mov byte [edi], 0
.seg_ready:
    ; dot and dotdot
    cmp byte [esi], '.'
    jne .name
    cmp byte [esi + 1], 0
    jne .dotdot
    mov al, [cwd_mode]
    mov ah, [cwd_custom_idx]
    clc
    ret
.dotdot:
    cmp byte [esi + 1], '.'
    jne .name
    cmp byte [esi + 2], 0
    jne .name
    mov al, CWD_ROOT
    mov ah, 0xFF
    clc
    ret

.name:
    mov edi, name_xdv_core
    call str_equals_ci
    test eax, eax
    jz .n1
    mov al, CWD_CORE
    mov ah, 0xFF
    clc
    ret
.n1:
    mov edi, name_xdv_utils
    call str_equals_ci
    test eax, eax
    jz .n2
    mov al, CWD_UTILS
    mov ah, 0xFF
    clc
    ret
.n2:
    mov edi, name_xdv_shell
    call str_equals_ci
    test eax, eax
    jz .n3
    mov al, CWD_SHELL
    mov ah, 0xFF
    clc
    ret
.n3:
    mov edi, name_xdv_edx
    call str_equals_ci
    test eax, eax
    jz .custom
    mov al, CWD_EDX
    mov ah, 0xFF
    clc
    ret

.custom:
    call find_custom_entry
    cmp al, 0xFF
    jne .has_custom
    stc
    ret
.has_custom:
    mov bl, al
    mov al, [custom_type + ebx]
    cmp al, ENTRY_DIR
    jne .fail
    mov al, CWD_CUSTOM
    mov ah, bl
    clc
    ret
.fail:
    stc
    ret

find_custom_entry:
    ; in: ESI name
    ; out: AL idx or 0xFF
    xor ebx, ebx
.scan:
    cmp ebx, CUSTOM_MAX
    jae .fail
    cmp byte [custom_used + ebx], 1
    jne .next
    mov edi, custom_names
    imul eax, ebx, NAME_MAX
    add edi, eax
    push esi
    call str_equals_ci
    pop esi
    test eax, eax
    jnz .hit
.next:
    inc ebx
    jmp .scan
.hit:
    mov al, bl
    ret
.fail:
    mov al, 0xFF
    ret

create_custom_entry:
    ; in: ESI name token, BL type
    ; out: AL idx or 0xFF
    call find_custom_entry
    cmp al, 0xFF
    je .find_slot
    mov al, 0xFE
    ret
.find_slot:
    xor ebx, ebx
.scan:
    cmp ebx, CUSTOM_MAX
    jae .full
    cmp byte [custom_used + ebx], 0
    je .slot
    inc ebx
    jmp .scan
.slot:
    mov byte [custom_used + ebx], 1
    mov al, [create_type_tmp]
    mov byte [custom_type + ebx], al
    mov edi, custom_names
    imul eax, ebx, NAME_MAX
    add edi, eax
    mov ecx, NAME_MAX
    xor eax, eax
    rep stosb
    mov edi, custom_names
    imul eax, ebx, NAME_MAX
    add edi, eax
    mov ecx, NAME_MAX - 1
    mov esi, [create_name_ptr]
.copy:
    mov al, [esi]
    mov [edi], al
    test al, al
    jz .done
    inc esi
    inc edi
    dec ecx
    jnz .copy
.done:
    mov byte [edi], 0
    mov al, bl
    ret
.full:
    mov al, 0xFF
    ret

delete_custom_entry:
    ; in: AL idx
    movzx ebx, al
    mov byte [custom_used + ebx], 0
    ret

; ------------------------------------------------------------
; Commands
; ------------------------------------------------------------

dispatch:
    mov esi, [cmd_ptr]
    mov al, [esi]
    test al, al
    jz .ret
    call capture_runtime_sample

    mov esi, cmd_help
    call cmd_equals
    test eax, eax
    jnz do_help
    mov esi, cmd_ls
    call cmd_equals
    test eax, eax
    jnz do_ls
    mov esi, cmd_cd
    call cmd_equals
    test eax, eax
    jnz do_cd
    mov esi, cmd_pwd
    call cmd_equals
    test eax, eax
    jnz do_pwd
    mov esi, cmd_cat
    call cmd_equals
    test eax, eax
    jnz do_cat
    mov esi, cmd_mkdir
    call cmd_equals
    test eax, eax
    jnz do_mkdir
    mov esi, cmd_rm
    call cmd_equals
    test eax, eax
    jnz do_rm
    mov esi, cmd_echo
    call cmd_equals
    test eax, eax
    jnz do_echo
    mov esi, cmd_ps
    call cmd_equals
    test eax, eax
    jnz do_ps
    mov esi, cmd_exit
    call cmd_equals
    test eax, eax
    jnz do_exit
    mov esi, cmd_edx
    call cmd_equals
    test eax, eax
    jnz do_edx

    ; xdv-core
    mov esi, cmd_console
    call cmd_equals
    test eax, eax
    jnz core_console
    mov esi, cmd_init
    call cmd_equals
    test eax, eax
    jnz core_init
    mov esi, cmd_io
    call cmd_equals
    test eax, eax
    jnz core_io
    mov esi, cmd_memory
    call cmd_equals
    test eax, eax
    jnz core_memory
    mov esi, cmd_process
    call cmd_equals
    test eax, eax
    jnz core_process
    mov esi, cmd_scheduler
    call cmd_equals
    test eax, eax
    jnz core_scheduler
    mov esi, cmd_strings
    call cmd_equals
    test eax, eax
    jnz core_strings
    mov esi, cmd_runtime_admin
    call cmd_equals
    test eax, eax
    jnz core_runtime_admin
    mov esi, cmd_runtime_admin2
    call cmd_equals
    test eax, eax
    jnz core_runtime_admin
    mov esi, cmd_sysmon
    call cmd_equals
    test eax, eax
    jnz core_sysmon
    mov esi, cmd_service
    call cmd_equals
    test eax, eax
    jnz core_service
    mov esi, cmd_log
    call cmd_equals
    test eax, eax
    jnz core_log
    mov esi, cmd_storage
    call cmd_equals
    test eax, eax
    jnz core_storage
    mov esi, cmd_security
    call cmd_equals
    test eax, eax
    jnz core_security
    mov esi, cmd_recovery
    call cmd_equals
    test eax, eax
    jnz core_recovery
    mov esi, cmd_cli
    call cmd_equals
    test eax, eax
    jnz core_cli

    ; xdv-xdvfs-utils
    mov esi, cmd_probe
    call cmd_equals
    test eax, eax
    jnz utils_probe
    mov esi, cmd_partition
    call cmd_equals
    test eax, eax
    jnz utils_partition
    mov esi, cmd_mkfs
    call cmd_equals
    test eax, eax
    jnz utils_mkfs
    mov esi, cmd_fsck
    call cmd_equals
    test eax, eax
    jnz utils_fsck
    mov esi, cmd_dir
    call cmd_equals
    test eax, eax
    jnz do_ls
    mov esi, cmd_file
    call cmd_equals
    test eax, eax
    jnz utils_file
    mov esi, cmd_mount
    call cmd_equals
    test eax, eax
    jnz utils_mount
    mov esi, cmd_space
    call cmd_equals
    test eax, eax
    jnz utils_space
    mov esi, cmd_perm
    call cmd_equals
    test eax, eax
    jnz utils_perm

    mov esi, msg_not_found
    call print_line
    ret
.ret:
    ret

do_help:
    mov esi, msg_help_shell
    call print_line
    mov esi, msg_help_core
    call print_line
    mov esi, msg_help_utils
    call print_line
    ret

do_pwd:
    mov al, [cwd_mode]
    cmp al, CWD_ROOT
    je .root
    cmp al, CWD_CORE
    je .core
    cmp al, CWD_UTILS
    je .utils
    cmp al, CWD_SHELL
    je .shell
    cmp al, CWD_EDX
    je .edx
    ; custom
    mov esi, path_root
    call puts
    mov al, '/'
    call putc
    movzx ebx, byte [cwd_custom_idx]
    mov edi, custom_names
    imul eax, ebx, NAME_MAX
    add edi, eax
    mov esi, edi
    call print_line
    ret
.root:
    mov esi, path_root
    call print_line
    ret
.core:
    mov esi, path_core
    call print_line
    ret
.utils:
    mov esi, path_utils
    call print_line
    ret
.shell:
    mov esi, path_shell
    call print_line
    ret
.edx:
    mov esi, path_edx
    call print_line
    ret

do_cd:
    call arg_to_token
    mov esi, token_buf
    call resolve_target_mode
    jc .nf
    mov [cwd_mode], al
    mov [cwd_custom_idx], ah
    mov esi, msg_ok
    call print_line
    ret
.nf:
    mov esi, msg_not_found
    call print_line
    ret

do_ls:
    call arg_to_token
    mov esi, token_buf
    mov al, [esi]
    test al, al
    jz .use_cwd
    call resolve_target_mode
    jc .nf
    mov [tmp_mode], al
    mov [tmp_custom_idx], ah
    jmp .list
.use_cwd:
    mov al, [cwd_mode]
    mov ah, [cwd_custom_idx]
    mov [tmp_mode], al
    mov [tmp_custom_idx], ah
.list:
    mov al, [tmp_mode]
    cmp al, CWD_ROOT
    je .root
    cmp al, CWD_CORE
    je .core
    cmp al, CWD_UTILS
    je .utils
    cmp al, CWD_SHELL
    je .shell
    cmp al, CWD_EDX
    je .edx
    mov esi, msg_empty
    call print_line
    ret

.root:
    mov esi, name_xdv_core
    call puts
    mov al, '/'
    call putc
    call newline
    mov esi, name_xdv_utils
    call puts
    mov al, '/'
    call putc
    call newline
    mov esi, name_xdv_shell
    call puts
    mov al, '/'
    call putc
    call newline
    mov esi, name_xdv_edx
    call puts
    mov al, '/'
    call putc
    call newline
    xor ebx, ebx
.custom_scan:
    cmp ebx, CUSTOM_MAX
    jae .done
    cmp byte [custom_used + ebx], 1
    jne .next
    mov edi, custom_names
    imul eax, ebx, NAME_MAX
    add edi, eax
    mov esi, edi
    call puts
    cmp byte [custom_type + ebx], ENTRY_DIR
    jne .nl
    mov al, '/'
    call putc
.nl:
    call newline
.next:
    inc ebx
    jmp .custom_scan
.done:
    ret
.nf:
    mov esi, msg_not_found
    call print_line
    ret

.core:
    mov esi, msg_core_cmds
    call print_space_list
    ret
.utils:
    mov esi, msg_utils_cmds
    call print_space_list
    ret
.shell:
    mov esi, name_readme
    call print_line
    mov esi, name_commands
    call print_line
    ret
.edx:
    mov esi, name_readme
    call print_line
    ret

do_cat:
    call arg_to_token
    mov esi, token_buf
    mov al, [esi]
    test al, al
    jnz .has_arg
    mov esi, msg_usage_cat
    call print_line
    ret
.has_arg:
    ; absolute paths for built-in preload files.
    cmp byte [esi], '/'
    jne .rel
    mov edi, path_shell_readme
    call str_equals_ci
    test eax, eax
    jz .abs_shell_cmds
    mov esi, msg_shell_readme
    call print_line
    ret
.abs_shell_cmds:
    mov esi, token_buf
    mov edi, path_shell_commands
    call str_equals_ci
    test eax, eax
    jz .abs_edx_readme
    mov esi, msg_shell_commands
    call print_line
    ret
.abs_edx_readme:
    mov esi, token_buf
    mov edi, path_edx_readme
    call str_equals_ci
    test eax, eax
    jz .abs_custom_root
    mov esi, msg_edx_readme
    call print_line
    ret
.abs_custom_root:
    ; support cat /<root-file> for dynamic files.
    mov esi, token_buf
    inc esi
    mov al, [esi]
    test al, al
    jz .nf
.abs_scan:
    mov al, [esi]
    test al, al
    jz .abs_lookup
    cmp al, '/'
    je .nf
    inc esi
    jmp .abs_scan
.abs_lookup:
    mov esi, token_buf
    inc esi
    call find_custom_entry
    cmp al, 0xFF
    jne .cf
    jmp .nf

.rel:
    mov al, [cwd_mode]
    cmp al, CWD_SHELL
    jne .not_shell
    mov edi, name_readme
    call str_equals_ci
    test eax, eax
    jz .shell_cmds
    mov esi, msg_shell_readme
    call print_line
    ret
.shell_cmds:
    mov esi, token_buf
    mov edi, name_commands
    call str_equals_ci
    test eax, eax
    jz .nf
    mov esi, msg_shell_commands
    call print_line
    ret

.not_shell:
    mov al, [cwd_mode]
    cmp al, CWD_EDX
    jne .root_custom
    mov edi, name_readme
    call str_equals_ci
    test eax, eax
    jz .nf
    mov esi, msg_edx_readme
    call print_line
    ret

.root_custom:
    mov al, [cwd_mode]
    cmp al, CWD_ROOT
    jne .nf
    mov esi, token_buf
    call find_custom_entry
    cmp al, 0xFF
    jne .cf
    jmp .nf
.cf:
    movzx ebx, al
    cmp byte [custom_type + ebx], ENTRY_FILE
    jne .not_file
    mov esi, msg_empty_file
    call print_line
    ret

.not_file:
    mov esi, msg_not_file
    call print_line
    ret
.nf:
    mov esi, msg_not_found
    call print_line
    ret

do_mkdir:
    mov al, [cwd_mode]
    cmp al, CWD_ROOT
    je .root
    mov esi, msg_root_only
    call print_line
    ret
.root:
    call arg_to_token
    mov esi, token_buf
    mov al, [esi]
    test al, al
    jnz .mk
    mov esi, msg_usage_mkdir
    call print_line
    ret
.mk:
    mov [create_name_ptr], esi
    mov byte [create_type_tmp], ENTRY_DIR
    mov bl, ENTRY_DIR
    call create_custom_entry
    cmp al, 0xFF
    je .full
    cmp al, 0xFE
    je .exists
    mov esi, msg_ok
    call print_line
    ret
.exists:
    mov esi, msg_exists
    call print_line
    ret
.full:
    mov esi, msg_table_full
    call print_line
    ret

do_rm:
    mov al, [cwd_mode]
    cmp al, CWD_ROOT
    je .root
    mov esi, msg_root_only
    call print_line
    ret
.root:
    call arg_to_token
    mov esi, token_buf
    mov al, [esi]
    test al, al
    jnz .go
    mov esi, msg_usage_rm
    call print_line
    ret
.go:
    call find_custom_entry
    cmp al, 0xFF
    jne .hit
    mov esi, msg_not_found
    call print_line
    ret
.hit:
    call delete_custom_entry
    mov esi, msg_ok
    call print_line
    ret

do_echo:
    mov esi, [arg_ptr]
    mov al, [esi]
    test al, al
    jnz .print
    call newline
    ret
.print:
    call print_line
    ret

do_ps:
    mov esi, msg_ps
    call print_line
    ret

do_exit:
    mov esi, msg_exit
    call print_line
    ret

do_edx:
    mov al, [cwd_mode]
    cmp al, CWD_ROOT
    je .root
    mov esi, msg_edx_scope
    call print_line
    ret
.root:
    call arg_to_token
    mov esi, token_buf
    mov al, [esi]
    test al, al
    jnz .open
    mov esi, msg_usage_edx
    call print_line
    ret
.open:
    call find_custom_entry
    cmp al, 0xFF
    jne .show
    mov [create_name_ptr], esi
    mov byte [create_type_tmp], ENTRY_FILE
    mov bl, ENTRY_FILE
    call create_custom_entry
.show:
    mov esi, msg_edx_open
    call puts
    mov esi, token_buf
    call print_line
    ret

; xdv-core runtime helpers
str_len:
    xor eax, eax
.loop:
    cmp byte [esi + eax], 0
    je .done
    inc eax
    jmp .loop
.done:
    ret

print_u32:
    push ebx
    push ecx
    push edx
    cmp eax, 0
    jne .convert
    mov al, '0'
    call putc
    jmp .done
.convert:
    xor ecx, ecx
    mov ebx, 10
.push_digits:
    xor edx, edx
    div ebx
    add dl, '0'
    push edx
    inc ecx
    test eax, eax
    jnz .push_digits
.emit_digits:
    pop eax
    call putc
    dec ecx
    jnz .emit_digits
.done:
    pop edx
    pop ecx
    pop ebx
    ret

print_label_u32:
    push eax
    call puts
    pop eax
    call print_u32
    call newline
    ret

count_custom_entries:
    push ebx
    xor eax, eax
    xor ebx, ebx
.scan:
    cmp ebx, CUSTOM_MAX
    jae .done
    cmp byte [custom_used + ebx], 1
    jne .next
    inc eax
.next:
    inc ebx
    jmp .scan
.done:
    pop ebx
    ret

count_custom_dirs:
    push ebx
    xor eax, eax
    xor ebx, ebx
.scan:
    cmp ebx, CUSTOM_MAX
    jae .done
    cmp byte [custom_used + ebx], 1
    jne .next
    cmp byte [custom_type + ebx], ENTRY_DIR
    jne .next
    inc eax
.next:
    inc ebx
    jmp .scan
.done:
    pop ebx
    ret

count_custom_files:
    push ebx
    xor eax, eax
    xor ebx, ebx
.scan:
    cmp ebx, CUSTOM_MAX
    jae .done
    cmp byte [custom_used + ebx], 1
    jne .next
    cmp byte [custom_type + ebx], ENTRY_FILE
    jne .next
    inc eax
.next:
    inc ebx
    jmp .scan
.done:
    pop ebx
    ret

get_cursor_row_col:
    push ecx
    push edx
    mov eax, [cursor]
    sub eax, VGA_BASE
    xor edx, edx
    mov ecx, 160
    div ecx
    mov ebx, edx
    shr ebx, 1
    pop edx
    pop ecx
    ret

capture_runtime_sample:
    inc dword [runtime_ticks]
    inc dword [commands_executed]

    mov esi, [cmd_ptr]
    mov edi, last_cmd_buf
    mov ecx, NAME_MAX - 1
.copy_cmd:
    mov al, [esi]
    mov [edi], al
    test al, al
    jz .copy_done
    inc esi
    inc edi
    dec ecx
    jnz .copy_cmd
    mov byte [edi], 0
.copy_done:
    mov esi, last_cmd_buf
    call str_len
    mov [last_cmd_len], eax

    mov esi, [arg_ptr]
    call str_len
    mov [last_arg_len], eax
    ret

; xdv-core
core_console:
    mov esi, msg_core_console
    call print_line

    call get_cursor_row_col
    push ebx
    mov esi, msg_metric_cursor_row
    call puts
    call print_u32
    mov al, ' '
    call putc
    mov esi, msg_metric_cursor_col
    call puts
    pop eax
    call print_u32
    call newline

    movzx eax, byte [kb_shift]
    mov esi, msg_metric_kb_shift
    call print_label_u32
    movzx eax, byte [kb_caps]
    mov esi, msg_metric_kb_caps
    call print_label_u32
    ret

core_init:
    mov esi, msg_core_init
    call print_line
    mov eax, [runtime_ticks]
    mov esi, msg_metric_boot_ticks
    call print_label_u32
    mov eax, [commands_executed]
    mov esi, msg_metric_commands
    call print_label_u32
    ret

core_io:
    mov esi, msg_core_io
    call print_line
    mov esi, msg_metric_last_cmd
    call puts
    mov esi, last_cmd_buf
    call print_line
    mov eax, [last_arg_len]
    mov esi, msg_metric_last_arg_len
    call print_label_u32
    call count_custom_files
    mov esi, msg_metric_io_file_entries
    call print_label_u32
    ret

core_memory:
    mov esi, msg_core_memory
    call print_line
    mov eax, [line_len]
    mov esi, msg_metric_line_len
    call print_label_u32
    call count_custom_entries
    mov [metric_tmp], eax
    mov esi, msg_metric_heap_used
    call print_label_u32
    mov eax, CUSTOM_MAX
    sub eax, [metric_tmp]
    mov esi, msg_metric_heap_free
    call print_label_u32
    ret

core_process:
    mov esi, msg_core_process
    call print_line
    mov eax, 1
    mov esi, msg_metric_pid
    call print_label_u32
    mov eax, [commands_executed]
    mov esi, msg_metric_context_switches
    call print_label_u32
    ret

core_scheduler:
    mov esi, msg_core_scheduler
    call print_line
    call arg_to_token
    mov esi, token_buf
    mov al, [esi]
    test al, al
    jz .report
    mov edi, arg_start
    call str_equals_ci
    test eax, eax
    jz .check_stop
    mov byte [scheduler_running], 1
    jmp .report
.check_stop:
    mov esi, token_buf
    mov edi, arg_stop
    call str_equals_ci
    test eax, eax
    jz .check_tick
    mov byte [scheduler_running], 0
    jmp .report
.check_tick:
    mov esi, token_buf
    mov edi, arg_tick
    call str_equals_ci
    test eax, eax
    jz .report
    inc dword [runtime_ticks]
.report:
    movzx eax, byte [scheduler_running]
    mov esi, msg_metric_scheduler_running
    call print_label_u32
    mov eax, [runtime_ticks]
    mov esi, msg_metric_scheduler_ticks
    call print_label_u32
    ret

core_strings:
    mov esi, msg_core_strings
    call print_line
    mov eax, [last_cmd_len]
    mov esi, msg_metric_last_cmd_len
    call print_label_u32
    mov eax, [last_arg_len]
    mov esi, msg_metric_last_arg_len
    call print_label_u32
    ret

core_runtime_admin:
    mov esi, msg_core_runtime_admin
    call print_line
    call get_cursor_row_col
    mov ecx, eax
    mov edx, ebx
    mov eax, 1
    cmp ecx, 25
    jae .console_done
    cmp edx, 80
    jae .console_done
    xor eax, eax
.console_done:
    mov esi, msg_metric_console_status
    call print_label_u32
    movzx eax, byte [scheduler_running]
    mov esi, msg_metric_scheduler_running
    call print_label_u32
    call count_custom_entries
    mov esi, msg_metric_resource_entries
    call print_label_u32
    ret

core_sysmon:
    mov esi, msg_core_sysmon
    call print_line
    mov eax, [runtime_ticks]
    mov esi, msg_metric_uptime_ticks
    call print_label_u32
    mov eax, [commands_executed]
    mov esi, msg_metric_commands
    call print_label_u32
    movzx eax, byte [kb_shift]
    mov esi, msg_metric_kb_shift
    call print_label_u32
    movzx eax, byte [kb_ctrl]
    mov esi, msg_metric_kb_ctrl
    call print_label_u32
    ret

core_service:
    mov esi, msg_core_service
    call print_line
    call count_custom_dirs
    mov esi, msg_metric_service_slots
    call print_label_u32
    movzx eax, byte [scheduler_running]
    mov esi, msg_metric_scheduler_running
    call print_label_u32
    ret

core_log:
    mov esi, msg_core_log
    call print_line
    mov eax, [commands_executed]
    mov esi, msg_metric_log_entries
    call print_label_u32
    mov esi, msg_metric_last_cmd
    call puts
    mov esi, last_cmd_buf
    call print_line
    ret

core_storage:
    mov esi, msg_core_storage
    call print_line
    mov eax, 2048
    mov esi, msg_metric_xdvfs_part_lba
    call print_label_u32
    mov eax, 32
    mov esi, msg_metric_xdvfs_kernel_lba
    call print_label_u32
    call count_custom_files
    mov [metric_tmp], eax
    call count_custom_dirs
    mov esi, msg_metric_storage_dirs
    call print_label_u32
    mov eax, [metric_tmp]
    mov esi, msg_metric_storage_files
    call print_label_u32
    ret

core_security:
    mov esi, msg_core_security
    call print_line
    call arg_to_token
    mov esi, token_buf
    mov al, [esi]
    test al, al
    jz .report
    mov edi, arg_lockdown
    call str_equals_ci
    test eax, eax
    jz .check_restore
    mov byte [security_lockdown], 1
    jmp .report
.check_restore:
    mov esi, token_buf
    mov edi, arg_restore
    call str_equals_ci
    test eax, eax
    jz .report
    mov byte [security_lockdown], 0
.report:
    movzx eax, byte [security_lockdown]
    mov esi, msg_metric_lockdown
    call print_label_u32
    movzx eax, byte [kb_ctrl]
    mov esi, msg_metric_kb_ctrl
    call print_label_u32
    movzx eax, byte [kb_alt]
    mov esi, msg_metric_kb_alt
    call print_label_u32
    ret

core_recovery:
    inc dword [recovery_runs]
    mov esi, msg_core_recovery
    call print_line
    mov eax, [recovery_runs]
    mov esi, msg_metric_recovery_runs
    call print_label_u32
    call count_custom_entries
    mov esi, msg_metric_resource_entries
    call print_label_u32
    movzx eax, byte [security_lockdown]
    mov esi, msg_metric_lockdown
    call print_label_u32
    ret

core_cli:
    mov esi, msg_core_cli
    call print_line
    call arg_to_token
    mov esi, token_buf
    mov al, [esi]
    test al, al
    jz .show
    mov edi, arg_minimum
    call str_equals_ci
    test eax, eax
    jz .check_admin
    mov byte [cli_profile], 1
    jmp .show
.check_admin:
    mov esi, token_buf
    mov edi, arg_admin
    call str_equals_ci
    test eax, eax
    jz .check_recovery
    mov byte [cli_profile], 2
    jmp .show
.check_recovery:
    mov esi, token_buf
    mov edi, arg_recovery
    call str_equals_ci
    test eax, eax
    jz .check_all
    mov byte [cli_profile], 3
    jmp .show
.check_all:
    mov esi, token_buf
    mov edi, arg_all
    call str_equals_ci
    test eax, eax
    jz .show
    mov byte [cli_profile], 4
.show:
    movzx eax, byte [cli_profile]
    mov esi, msg_metric_cli_profile
    call print_label_u32
    mov eax, [commands_executed]
    mov esi, msg_metric_commands
    call print_label_u32
    ret

; xdv-xdvfs-utils
utils_probe:        mov esi, msg_utils_probe
    jmp print_line
utils_partition:    mov esi, msg_utils_partition
    jmp print_line
utils_mkfs:         mov esi, msg_utils_mkfs
    jmp print_line
utils_fsck:         mov esi, msg_utils_fsck
    jmp print_line
utils_file:
    mov al, [cwd_mode]
    cmp al, CWD_ROOT
    je .root
    mov esi, msg_root_only
    call print_line
    ret
.root:
    call arg_to_token
    mov esi, token_buf
    mov al, [esi]
    test al, al
    jnz .mk
    mov esi, msg_usage_file
    call print_line
    ret
.mk:
    mov [create_name_ptr], esi
    mov byte [create_type_tmp], ENTRY_FILE
    mov bl, ENTRY_FILE
    call create_custom_entry
    cmp al, 0xFF
    je .full
    cmp al, 0xFE
    je .exists
    mov esi, msg_ok
    call print_line
    ret
.exists:
    mov esi, msg_exists
    call print_line
    ret
.full:
    mov esi, msg_table_full
    call print_line
    ret

utils_mount:        mov esi, msg_utils_mount
    jmp print_line
utils_space:        mov esi, msg_utils_space
    jmp print_line
utils_perm:         mov esi, msg_utils_perm
    jmp print_line

; ------------------------------------------------------------
; Data
; ------------------------------------------------------------

cursor           dd VGA_BASE
line_len         dd 0
line_buf         times LINE_MAX db 0
cmd_ptr          dd line_buf
arg_ptr          dd line_buf
token_buf        times NAME_MAX db 0
tmp_mode         db 0
tmp_custom_idx   db 0xFF

cwd_mode         db CWD_ROOT
cwd_custom_idx   db 0xFF

custom_used      times CUSTOM_MAX db 0
custom_type      times CUSTOM_MAX db 0
custom_names     times (CUSTOM_MAX * NAME_MAX) db 0
create_name_ptr  dd token_buf
create_type_tmp  db 0

runtime_ticks    dd 0
commands_executed dd 0
last_cmd_len     dd 0
last_arg_len     dd 0
recovery_runs    dd 0
metric_tmp       dd 0

scheduler_running db 1
security_lockdown db 0
cli_profile      db 1

last_cmd_buf     times NAME_MAX db 0

kb_shift         db 0
kb_caps          db 0
kb_ctrl          db 0
kb_alt           db 0
kb_ext           db 0

map_unshift:
    db 0,27,'1','2','3','4','5','6','7','8','9','0','-','=',8,9
    db 'q','w','e','r','t','y','u','i','o','p','[',']',10,0,'a','s'
    db 'd','f','g','h','j','k','l',0x3B,0x27,0x60,0,0x5C,'z','x','c','v'
    db 'b','n','m',0x2C,0x2E,0x2F,0,'*',0,' ',0,0,0,0,0,0
    db 0,0,0,0,0,0,0,'7','8','9','-','4','5','6','+','1'
    db '2','3','0','.',0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

map_shift:
    db 0,27,'!','@','#','$','%','^','&','*','(',')','_','+',8,9
    db 'Q','W','E','R','T','Y','U','I','O','P','{','}',10,0,'A','S'
    db 'D','F','G','H','J','K','L',0x3A,0x22,0x7E,0,0x7C,'Z','X','C','V'
    db 'B','N','M',0x3C,0x3E,0x3F,0,'*',0,' ',0,0,0,0,0,0
    db 0,0,0,0,0,0,0,'7','8','9','-','4','5','6','+','1'
    db '2','3','0','.',0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

prompt           db '#:',0
path_root        db '/',0
path_core        db '/xdv-core',0
path_utils       db '/xdv-xdvfs-utils',0
path_shell       db '/xdv-shell',0
path_edx         db '/xdv-edx',0

cmd_help         db 'help',0
cmd_ls           db 'ls',0
cmd_cd           db 'cd',0
cmd_pwd          db 'pwd',0
cmd_cat          db 'cat',0
cmd_mkdir        db 'mkdir',0
cmd_rm           db 'rm',0
cmd_echo         db 'echo',0
cmd_ps           db 'ps',0
cmd_exit         db 'exit',0
cmd_edx          db 'edx',0

cmd_console      db 'console',0
cmd_init         db 'init',0
cmd_io           db 'io',0
cmd_memory       db 'memory',0
cmd_process      db 'process',0
cmd_scheduler    db 'scheduler',0
cmd_strings      db 'strings',0
cmd_runtime_admin db 'runtime-admin',0
cmd_runtime_admin2 db 'runtime_admin',0
cmd_sysmon       db 'sysmon',0
cmd_service      db 'service',0
cmd_log          db 'log',0
cmd_storage      db 'storage',0
cmd_security     db 'security',0
cmd_recovery     db 'recovery',0
cmd_cli          db 'cli',0

cmd_probe        db 'probe',0
cmd_partition    db 'partition',0
cmd_mkfs         db 'mkfs',0
cmd_fsck         db 'fsck',0
cmd_dir          db 'dir',0
cmd_file         db 'file',0
cmd_mount        db 'mount',0
cmd_space        db 'space',0
cmd_perm         db 'perm',0

arg_start        db 'start',0
arg_stop         db 'stop',0
arg_tick         db 'tick',0
arg_lockdown     db 'lockdown',0
arg_restore      db 'restore',0
arg_minimum      db 'minimum',0
arg_admin        db 'admin',0
arg_recovery     db 'recovery',0
arg_all          db 'all',0

name_xdv_core    db 'xdv-core',0
name_xdv_utils   db 'xdv-xdvfs-utils',0
name_xdv_shell   db 'xdv-shell',0
name_xdv_edx     db 'xdv-edx',0
name_readme      db 'README.txt',0
name_commands    db 'COMMANDS.txt',0

msg_boot_contract_complete db 'xdv-os: boot contract complete',0
msg_kernel_handoff         db 'XDV Kernel: received loader handoff',0
msg_kernel_init            db 'Initializing XDV Kernel v0.2.0',0
msg_kernel_date            db 'Build date: 2026-02-12',0
msg_domain_boot            db 'Booting on K-Domain (x64/Intel/AMD)',0
msg_domain_online          db 'K-Domain (x64): ONLINE',0
msg_kernel_load_runtime    db 'XDV Kernel: loading xdv-runtime',0
msg_kernel_start_runtime   db 'XDV Kernel: starting xdv-runtime',0
msg_kernel_main_loop       db 'Entering kernel main loop',0
msg_runtime_bridge         db 'xdv-runtime bridge online',0
msg_runtime_bootstrap      db 'xdv-runtime userspace bootstrap ready',0
msg_runtime_handoff        db 'xdv-runtime: received xdv-kernel userspace handoff',0
msg_runtime_keyboard       db 'xdv-runtime: keyboard driver online (US layout)',0
msg_runtime_cmd_buffer     db 'xdv-runtime: command buffer dispatcher ready',0
msg_runtime_shell_load     db 'xdv-runtime: loading xdv-shell from xdvfs preload',0
msg_runtime_preload        db 'xdv-runtime: preload packages xdv-os xdv-core xdv-edx xdv-shell',0
msg_shell_bridge           db 'xdv-shell bridge online',0
msg_shell_launch_units     db 'xdv-shell: launch units linked',0
msg_shell_launch           db 'xdv-shell launch path active',0
msg_shell_init             db 'xdv-shell: initializing',0
msg_shell_online           db 'XDV Shell online',0
msg_shell_prompt_mode      db 'Prompt mode: #:',0
msg_shell_dispatch         db 'xdv-shell: command dispatcher ready',0
msg_shell_command_catalog  db 'Available commands: cd ls cat mkdir rm echo ps help exit edx',0
msg_shell_loop_ready       db 'xdv-shell: interactive loop ready',0

msg_ok           db 'ok',0
msg_not_found    db 'not found',0
msg_not_file     db 'not a file',0
msg_exists       db 'already exists',0
msg_empty        db '(empty)',0
msg_empty_file   db '(empty file)',0
msg_table_full   db 'table full',0
msg_root_only    db 'operation supported at / only in this build',0
msg_usage_cat    db 'usage: cat <name>',0
msg_usage_mkdir  db 'usage: mkdir <name>',0
msg_usage_rm     db 'usage: rm <name>',0
msg_usage_file   db 'usage: file <name>',0
msg_usage_edx    db 'usage: edx <name>',0
msg_ps           db 'pid 1 kernel_main running',0
msg_exit         db 'exit: shutdown not enabled in bare-metal mode',0
msg_edx_scope    db 'edx path support is root-local in this build',0
msg_edx_open     db 'edx: opened ',0

msg_help_shell   db 'shell: cd ls cat mkdir rm echo ps help exit edx pwd',0
msg_help_core    db 'xdv-core: console init io memory process scheduler strings runtime-admin sysmon service log storage security recovery cli',0
msg_help_utils   db 'xdv-xdvfs-utils: probe partition mkfs fsck dir file mount space perm',0

msg_shell_readme   db 'xdv-shell command layer',0
msg_shell_commands db 'commands: cd ls cat mkdir rm echo ps help exit edx pwd',0
msg_edx_readme     db 'edx editor module',0
msg_core_cmds      db 'console init io memory process scheduler strings runtime-admin sysmon service log storage security recovery cli',0
msg_utils_cmds     db 'probe partition mkfs fsck dir file mount space perm',0

msg_core_console       db 'xdv-core.console: status clear theme cursor key write',0
msg_core_init          db 'xdv-core.init: status bootstrap spawn-shell wait reap shutdown reload',0
msg_core_io            db 'xdv-core.io: open-read open-write open-append read write close',0
msg_core_memory        db 'xdv-core.memory: diag alloc zero-alloc free copy set',0
msg_core_process       db 'xdv-core.process: current-pid spawn spawn-stack join kill sleep yield',0
msg_core_scheduler     db 'xdv-core.scheduler: status start stop add remove priority tick',0
msg_core_strings       db 'xdv-core.strings: len compare find concat substring upper lower',0
msg_core_runtime_admin db 'xdv-core.runtime-admin: minimum-set admin-set full-cycle',0
msg_core_sysmon        db 'xdv-core.sysmon: snapshot runtime-health io-sample storage-sample',0
msg_core_service       db 'xdv-core.service: status start start-priority stop restart reload',0
msg_core_log           db 'xdv-core.log: status open write read close emit-console',0
msg_core_storage       db 'xdv-core.storage: status partition mkfs fsck mount unmount df dir touch',0
msg_core_security      db 'xdv-core.security: status chmod chown chgrp lockdown restore',0
msg_core_recovery      db 'xdv-core.recovery: diagnostics safe-mode repair reload-runtime',0
msg_core_cli           db 'xdv-core.cli: minimum admin recovery all profile',0

msg_metric_cursor_row         db 'cursor-row=',0
msg_metric_cursor_col         db 'cursor-col=',0
msg_metric_kb_shift           db 'kb-shift=',0
msg_metric_kb_caps            db 'kb-caps=',0
msg_metric_kb_ctrl            db 'kb-ctrl=',0
msg_metric_kb_alt             db 'kb-alt=',0
msg_metric_boot_ticks         db 'boot-ticks=',0
msg_metric_uptime_ticks       db 'uptime-ticks=',0
msg_metric_commands           db 'commands=',0
msg_metric_last_cmd           db 'last-cmd=',0
msg_metric_last_cmd_len       db 'last-cmd-len=',0
msg_metric_last_arg_len       db 'last-arg-len=',0
msg_metric_io_file_entries    db 'io-file-entries=',0
msg_metric_line_len           db 'line-len=',0
msg_metric_heap_used          db 'heap-used-slots=',0
msg_metric_heap_free          db 'heap-free-slots=',0
msg_metric_pid                db 'pid=',0
msg_metric_context_switches   db 'context-switches=',0
msg_metric_scheduler_running  db 'scheduler-running=',0
msg_metric_scheduler_ticks    db 'scheduler-ticks=',0
msg_metric_console_status     db 'console-status=',0
msg_metric_resource_entries   db 'resource-entries=',0
msg_metric_service_slots      db 'service-slots=',0
msg_metric_log_entries        db 'log-entries=',0
msg_metric_xdvfs_part_lba     db 'xdvfs-partition-lba=',0
msg_metric_xdvfs_kernel_lba   db 'xdv-kernel-rel-lba=',0
msg_metric_storage_dirs       db 'storage-dir-entries=',0
msg_metric_storage_files      db 'storage-file-entries=',0
msg_metric_lockdown           db 'lockdown=',0
msg_metric_recovery_runs      db 'recovery-runs=',0
msg_metric_cli_profile        db 'cli-profile=',0

msg_utils_probe       db 'xdvfs-utils.probe: operational',0
msg_utils_partition   db 'xdvfs-utils.partition: operational',0
msg_utils_mkfs        db 'xdvfs-utils.mkfs: operational',0
msg_utils_fsck        db 'xdvfs-utils.fsck: operational',0
msg_utils_mount       db 'xdvfs-utils.mount: operational',0
msg_utils_space       db 'xdvfs-utils.space: operational',0
msg_utils_perm        db 'xdvfs-utils.perm: operational',0

path_shell_readme     db '/xdv-shell/README.txt',0
path_shell_commands   db '/xdv-shell/COMMANDS.txt',0
path_edx_readme       db '/xdv-edx/README.txt',0
