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
    li      a0, 0
    ret
    .size   bf16_sqrt_asm, .-bf16_sqrt_asm
