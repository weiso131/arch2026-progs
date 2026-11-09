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
    return (a >> 1) + (b >> 1) + (a & b & 1);
}

int32_t q_mul(int32_t a, int32_t b)
{
    uint32_t ua = a, ub = b;

    uint32_t top = 0, bottom = 0, top_a = 0;
    uint32_t a_sign = ua & 0x80000000, b_sign = ub & 0x80000000;
    if (a_sign)
        ua = ~ua + 1;
    if (b_sign)
        ub = ~ub + 1;

    while (ub) {
        uint32_t a_top = ua & 0x80000000;
        if (ub & 1) {
            top += top_a;
            uint32_t origin_bottom = bottom;
            bottom += ua;
            top += ((a_top & origin_bottom) | (a_top & ~bottom) |
                    (origin_bottom & ~bottom)) >>
                   31;
        }
        top_a <<= 1;
        if (a_top)
            top_a++;
        ua <<= 1;
        ub >>= 1;
    }

    if (a_sign ^ b_sign) {
        top = ~top;
        bottom = ~bottom;
    }
    uint32_t bottom_origin = bottom;
    bottom += (1 << 19) | ((a_sign ^ b_sign) == 0x80000000);
    top += (bottom_origin & ~bottom) >> 31;

    return (top << 12) | (bottom >> 20);
}
