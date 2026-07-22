#include <stdio.h>
#include <math.h>
#include <stdint.h>

int main() {
    uint32_t val = 1038991686;
    uint32_t divisor = (uint32_t)pow(10, 6);
    printf("divisor: %u\n", divisor);
    printf("pin: %u\n", val % divisor);
    return 0;
}
