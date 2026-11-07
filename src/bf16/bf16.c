#include "bf16.h"

#define F32_INF 0x7F800000
#define BF16_INF 0x7F80
#define BF16_INF_NEG 0xFF80

/* Dummies: every function returns 0. Replace with the real routines. */
uint16_t bf16_from_f32(uint32_t f32bits)
{
    if ((f32bits & F32_INF) == F32_INF)
        return (uint16_t) (f32bits >> 16);
    uint16_t result = (f32bits + 0x7FFF + ((f32bits >> 16) & 1)) >> 16;
    if ((result & BF16_INF) == BF16_INF)
        return result & BF16_INF_NEG;
    return result;
}

uint16_t bf16_mul(uint16_t a, uint16_t b)
{
    (void) a;
    (void) b;
    return 0;
}

uint16_t bf16_sqrt(uint16_t a)
{
    (void) a;
    return 0;
}
