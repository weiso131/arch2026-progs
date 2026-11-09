#include "fixed.h"

/* Dummies: every function returns 0. Replace with the real routines. */
uint32_t op1(uint32_t a, uint32_t b, int *n)
{
    int i = 0;
    while (b) {
        uint32_t c = (a & b) << 1;
        a = a ^ b;
        b = c;
        i++;
    }
    *n = i;

    return a;
}

uint32_t op2(uint32_t a, uint32_t b)
{
    return a - b;
}

uint32_t op3(uint32_t a, uint32_t b)
{
    (void) a;
    (void) b;
    return 0;
}

int32_t q_mul(int32_t a, int32_t b)
{
    (void) a;
    (void) b;
    return 0;
}
