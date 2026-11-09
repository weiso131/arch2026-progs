# op1, op2, op3 and q_mul: hand-written RV32I.
#
# uint32_t op1_asm(uint32_t a, uint32_t b, int *n)   a0, a1, a2 -> a0
# uint32_t op2_asm(uint32_t a, uint32_t b)           a0, a1 -> a0
# uint32_t op3_asm(uint32_t a, uint32_t b)           a0, a1 -> a0
# int32_t  q_mul_asm(int32_t a, int32_t b)           a0, a1 -> a0
#
# RV32I and Zicsr only: no mul, div, rem, no floating point, no compressed
# instructions. q_mul forms a 64-bit product in a register pair. Tests:
# tests/tfixed.c.

    .text

    .globl  op1_asm
    .type   op1_asm, @function
    .align  2
op1_asm:
    addi    t0, x0, 0
op1_asm_loop:
    beq     a1, x0, op1_asm_loop_end
    and     t1, a0, a1
    xor     a0, a0, a1
    slli    a1, t1, 1
    addi    t0, t0, 1
    j       op1_asm_loop
op1_asm_loop_end:
    sw      t0, 0(a2)
    ret
    .size   op1_asm, .-op1_asm

    .globl  op2_asm
    .type   op2_asm, @function
    .align  2
op2_asm:
    sub     a0, a0, a1
    ret
    .size   op2_asm, .-op2_asm

    .globl  op3_asm
    .type   op3_asm, @function
    .align  2
op3_asm:
    andi    t0, a0, 1
    and     t0, t0, a1
    srli    a0, a0, 1
    srli    a1, a1, 1
    add     a0, a0, a1
    add     a0, a0, t0
    ret
    .size   op3_asm, .-op3_asm

    .globl  q_mul_asm
    .type   q_mul_asm, @function
    .align  2
q_mul_asm:
    addi    a2, x0, 0  # top
    addi    a3, x0, 0  # bottom
    addi    a4, x0, 0  # top_a
    li      t0, 0x80000000 
    li      t1, 0xFFFFFFFF
    and     a5, a0, t0 # a_sign
    and     a6, a1, t0 # b_sign

q_mul_check_a_sign:
    beq     a5, x0, q_mul_check_b_sign
    xor     a0, a0, t1
    addi    a0, a0, 1
q_mul_check_b_sign:
    beq     a6, x0, q_mul_loop
    xor     a1, a1, t1
    addi    a1, a1, 1
q_mul_loop:
    and     t2, a0, t0 # a_top
    andi    t3, a1, 1
    beq     t3, x0, q_mul_loop_not_add # if (ub & 1)
    add     a2, a2, a4
    addi    t3, a3, 0  # origin_bottom
    add     a3, a3, a0 # bottom += ua
    xor     t4, a3, t1 # ~bottom
    or      t5, t2, t3
    and     t5, t5, t4
    and     t4, t2, t3
    or      t4, t4, t5
    srli    t4, t4, 31
    add     a2, a2, t4
q_mul_loop_not_add:
    slli    a4, a4, 1
    beq     t2, x0, q_mul_loop_no_carry
    addi    a4, a4, 1
q_mul_loop_no_carry:
    slli    a0, a0, 1
    srli    a1, a1, 1
    bne     a1, x0, q_mul_loop
q_mul_loop_end:
    xor     a5, a5, a6 # a_sign ^ b_sign
    beq     a5, x0, q_mul_no_sign
    xor     a2, a2, t1
    xor     a3, a3, t1
q_mul_no_sign:
    addi    t2, a3, 0
    srli    a5, a5, 31
    srli    t0, t0, 12 # (0x80000000 >> 31) << 19
    or      t0, t0, a5
    add     a3, a3, t0 # bottom += t0 | a5;
    xor     t0, a3, t1
    and     t0, t0, t2
    srli    t0, t0, 31
    add     a2, a2, t0
    slli    a2, a2, 12
    srli    a3, a3, 20
    or      a0, a2, a3
    ret
    .size   q_mul_asm, .-q_mul_asm
