# BFloat16 routines: hand-written RV32I.
#
# uint16_t bf16_from_f32_asm(uint32_t f32bits)   a0 -> a0
# uint16_t bf16_mul_asm(uint16_t a, uint16_t b)  a0, a1 -> a0
# uint16_t bf16_sqrt_asm(uint16_t a)             a0 -> a0
#
# RV32I and Zicsr only: no mul, div, rem, no floating point, no compressed
# instructions. Tests: tests/tbf16.c.

    .text

    .globl  bf16_from_f32_asm
    .type   bf16_from_f32_asm, @function
    .align  2
bf16_from_f32_asm:
    li      t2, 0x7F800000
    and     t1, t2, a0
    beq     t2, t1, bf16_input_inf
    srli    t0, a0, 16
    andi    t0, t0, 1
    li      t1, 0x7FFF
    add     t0, t0, t1
    add     a0, a0, t0
bf16_input_inf:
    srli    a0, a0, 16  
    ret
    .size   bf16_from_f32_asm, .-bf16_from_f32_asm

    .globl  bf16_mul_asm
    .type   bf16_mul_asm, @function
    .align  2
bf16_mul_asm:
    xor     a2, a0, a1
    li      t0, 0x8000
    and     a2, a2, t0 # result_sign
    li      t0, 0x7F80 # BF16_EXP
    and     a3, a0, t0 # a_exp
    and     a4, a1, t0 # b_exp
    andi    a5, a0, 0x7F # a_mant
    andi    a6, a1, 0x7F # b_mant

    ori     t6, t0, 0x7F
    and     t1, a0, t6   # a_is_zero
    and     t2, a1, t6   # b_is_zero

bf16_mul_asm_check_a_INF:
    bne     a3, t0, bf16_mul_asm_check_b_INF
    beq     a5, x0, bf16_mul_asm_check_b_is_zero
    ret
bf16_mul_asm_check_b_is_zero:
    bne     t2, x0, bf16_mul_asm_INF
bf16_mul_asm_ret_NaN:
    li      a0, 0x7FC0
    ret
bf16_mul_asm_check_b_INF:
    bne     a4, t0, bf16_mul_asm_check_any_zero
    beq     a6, x0, bf16_mul_asm_check_a_is_zero
    addi    a0, a1, 0
    ret
bf16_mul_asm_check_a_is_zero:
    beq     t1, x0, bf16_mul_asm_ret_NaN
    j       bf16_mul_asm_INF

bf16_mul_asm_check_any_zero:
    bne     t1, x0, bf16_mul_asm_check_any_zero_check_b
bf16_mul_asm_ret_zero:
    addi    a0, a2, 0
    ret
bf16_mul_asm_check_any_zero_check_b:
    beq     t2, x0, bf16_mul_asm_ret_zero

    # t1 ~ t6 is free
    add     a7, a3, a4 # result_exp
    srli    a7, a7, 7
    addi    a7, a7, -127
    
    addi    t1, x0, 0x80 # BF16_ONE

bf16_mul_asm_check_a_denormal:
    bne     a3, x0, bf16_mul_asm_check_b_denormal
    addi    a7, a7, 1
bf16_mul_asm_check_a_denormal_loop:
    addi    a7, a7, -1
    slli    a5, a5, 1
    blt     a5, t1, bf16_mul_asm_check_a_denormal_loop
    andi    a5, a5, 0x7F
bf16_mul_asm_check_b_denormal:
    bne     a4, x0, bf16_mul_asm_denormal_check_end
    addi    a7, a7, 1
bf16_mul_asm_check_b_denormal_loop:
    addi    a7, a7, -1
    slli    a6, a6, 1
    blt     a6, t1, bf16_mul_asm_check_b_denormal_loop
    andi    a6, a6, 0x7F
bf16_mul_asm_denormal_check_end:

    # a3, a4 is free
    add     a3, a5, a6 # sig
    addi    a3, a3, 0x80
    addi    a4, x0, 0

bf16_mul_asm_mul_loop:
    andi    t2, a6, 1
    beq     t2, x0, bf16_mul_asm_mul_loop_continue
    add     a4, a4, a5
bf16_mul_asm_mul_loop_continue:
    slli    a5, a5, 1
    srli    a6, a6, 1
    bne     a6, x0, bf16_mul_asm_mul_loop

    srli    a4, a4, 7
    add     a3, a3, a4

    andi    t2, a3, 0x100
    beq     t2, x0, bf16_mul_asm_check_result_INF
    addi    a7, a7, 1
    srli    a3, a3, 1
bf16_mul_asm_check_result_INF:
    addi    t2, x0, 0xFF
    blt     a7, t2, bf16_mul_asm_check_result_denormal
bf16_mul_asm_INF:
    li      a0, 0x7F80
    or      a0, a0, a2
    ret
bf16_mul_asm_check_result_denormal:
    addi    a0, a2, 0
    blt     x0, a7, bf16_mul_asm_return_normal
    addi    t2, x0, -6
    blt     t2, a7, bf16_mul_asm_return_denormal
    ret
bf16_mul_asm_return_denormal:
    andi    a3, a3, 0x7F
    addi    a7, a7, -1  # (result_exp - 1)
    sub     a7, x0, a7 # (1 - result_exp)
    srl     a3, a3, a7
    or      a0, a3, a0
    ret
bf16_mul_asm_return_normal:
    andi    a3, a3, 0x7F
    slli    a7, a7, 7
    or      a0, a0, a3
    or      a0, a0, a7
    ret
    .size   bf16_mul_asm, .-bf16_mul_asm

    .globl  bf16_sqrt_asm
    .type   bf16_sqrt_asm, @function
    .align  2
bf16_sqrt_asm:
    li      t0, 0x7F80
    and     t0, t0, a0
    srli    a1, t0, 7  # exp
    andi    a2, a0, 0x7F # frac
    addi    t1, x0, 0xFF
    li      t2, 0x8000
    and     t3, a0, t2
    beq     t3, t2, bf16_sqrt_negative
    beq     a1, t1, bf16_sqrt_INF
    beq     a1, x0, bf16_sqrt_zero

sqrt_normal_value:
    andi    t6, a1, 1
    beq     t6, x0, sqrt_use_odd
    la      t6, sqrt_even_asm
    j       sqrt_return
sqrt_use_odd:
    la      t6, sqrt_odd_asm
sqrt_return:
    add     t6, t6, a2
    lbu     a0, 0(t6)
    addi    a1, a1, 127
    srli    a1, a1, 1
    slli    a1, a1, 7
    or      a0, a0, a1
bf16_sqrt_INF:
    ret
bf16_sqrt_zero:
    addi    a0, x0, 0
    ret
bf16_sqrt_negative:
    beq     a2, x0, bf16_sqrt_check_zero
    beq     a1, t1, bf16_sqrt_INF
bf16_sqrt_check_zero:
    ori     t0, t0, 0x7F
    and     t0, t0, a0
    beq     t0, x0, bf16_sqrt_zero
    li      a0, 0x7FC0
    ret
    .size   bf16_sqrt_asm, .-bf16_sqrt_asm

    .section .rodata
sqrt_even_asm:
    .byte   0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7
    .byte   8, 8, 9, 9, 10, 10, 11, 11, 11, 12, 12, 13, 13, 14, 14, 15
    .byte   15, 15, 16, 16, 17, 17, 18, 18, 19, 19, 19, 20, 20, 21, 21, 22
    .byte   22, 22, 23, 23, 24, 24, 25, 25, 25, 26, 26, 27, 27, 27, 28, 28
    .byte   29, 29, 29, 30, 30, 31, 31, 31, 32, 32, 33, 33, 33, 34, 34, 35
    .byte   35, 35, 36, 36, 37, 37, 37, 38, 38, 39, 39, 39, 40, 40, 40, 41
    .byte   41, 42, 42, 42, 43, 43, 43, 44, 44, 45, 45, 45, 46, 46, 46, 47
    .byte   47, 47, 48, 48, 49, 49, 49, 50, 50, 50, 51, 51, 51, 52, 52, 53

sqrt_odd_asm:
    .byte   53, 54, 54, 55, 56, 56, 57, 58, 58, 59, 60, 60, 61, 62, 62, 63
    .byte   64, 64, 65, 66, 66, 67, 68, 68, 69, 70, 70, 71, 72, 72, 73, 74
    .byte   74, 75, 75, 76, 77, 77, 78, 79, 79, 80, 80, 81, 82, 82, 83, 83
    .byte   84, 85, 85, 86, 86, 87, 88, 88, 89, 89, 90, 91, 91, 92, 92, 93
    .byte   93, 94, 95, 95, 96, 96, 97, 97, 98, 99, 99, 100, 100, 101, 101, 102
    .byte   103, 103, 104, 104, 105, 105, 106, 106, 107, 107, 108, 109, 109, 110, 110, 111
    .byte   111, 112, 112, 113, 113, 114, 114, 115, 115, 116, 117, 117, 118, 118, 119, 119
    .byte   120, 120, 121, 121, 122, 122, 123, 123, 124, 124, 125, 125, 126, 126, 127, 127
    .text
