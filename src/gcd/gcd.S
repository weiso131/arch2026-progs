# gcd_u32_asm: binary GCD, hand-written RV32I.
#
# uint32_t gcd_u32_asm(uint32_t a, uint32_t b)   a in a0, b in a1, result in a0
#
# RV32I and Zicsr only: no mul, div, rem, no floating point, no compressed
# instructions. Tests: tests/tgcd.c.

    .text

    .globl  gcd_u32_asm
    .type   gcd_u32_asm, @function
    .align  2
gcd_u32_asm:
    addi    t0, x0, 0
gcd_u32_even_loop:
    beq     a0, x0, gcd_u32_return
    beq     a1, x0, gcd_u32_return
    or      t1, a0, a1
    andi    t1, t1, 1
    bne     t1, x0, gcd_check_both_already_odd
    srli    a0, a0, 1
    srli    a1, a1, 1
    addi    t0, t0, 1
    j       gcd_u32_even_loop
gcd_check_both_already_odd:
    andi    t1, a1, 1
    beq     t1, x0, gcd_u32_gcd_check_b_zero
    andi    t1, a0, 1
    bne     t1, x0, gcd_u32_gcd_loop_all_odd
gcd_u32_gcd_loop:
    beq     a0, x0, gcd_u32_return
gcd_u32_gcd_check_b_zero:
    beq     a1, x0, gcd_u32_return
    andi    t1, a1, 1
    beq     t1, x0, gcd_u32_gcd_loop_b_loop
gcd_u32_gcd_loop_a_loop:
    srli    a0, a0, 1
    andi    t1, a0, 1
    beq     t1, x0, gcd_u32_gcd_loop_a_loop
    j       gcd_u32_gcd_loop_all_odd
gcd_u32_gcd_loop_b_loop:
    srli    a1, a1, 1
    andi    t1, a1, 1
    beq     t1, x0, gcd_u32_gcd_loop_b_loop

gcd_u32_gcd_loop_all_odd:
    bgeu     a1, a0, gcd_u32_gcd_b_is_bigger
    sub     a0, a0, a1
    j       gcd_u32_gcd_loop_a_loop  # a != b -> a become even and a != 0
gcd_u32_gcd_b_is_bigger:
    sub     a1, a1, a0
    j       gcd_u32_gcd_check_b_zero # b = b - a, a != 0, check b only
gcd_u32_return:
    or      a0, a0, a1
    sll     a0, a0, t0
    ret
    .size   gcd_u32_asm, .-gcd_u32_asm
