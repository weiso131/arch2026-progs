#include "gcd.h"

/* Dummy: returns 0 for every input. Replace with the binary GCD. */
uint32_t gcd_u32(uint32_t a, uint32_t b)
{
    int gcd_shift = 0;
    while (!((a | b) & 1) && a && b) {
        a >>= 1;
        b >>= 1;
        gcd_shift++;
    }

    while (a && b) {
        while (!(a & 1) && a)
            a >>= 1;
        while (!(b & 1) && b)
            b >>= 1;
        if (a > b)
            a = a - b;
        else
            b = b - a;
    }

    return (a | b) << gcd_shift;
}
